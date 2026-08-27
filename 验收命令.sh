#!/usr/bin/env bash
# Lucy K8s 集成验收脚本 — 20260827-v3
# 用法：在已 kubectl 指向目标集群的环境执行。
# 可覆盖环境变量：NAMESPACE DEPLOYMENT SERVICE CONTAINER IMAGE_TAR IMAGE_REF MCP_URL TOKEN CONNECTION_ID

set -euo pipefail

NAMESPACE="${NAMESPACE:-lucy}"
DEPLOYMENT="${DEPLOYMENT:-lucy}"
SERVICE="${SERVICE:-lucy}"
CONTAINER="${CONTAINER:-lucy}"
IMAGE_TAR="${IMAGE_TAR:-image/project-lucy-customer-amd64-0.16.0-v3-image.tar}"
IMAGE_REF="${IMAGE_REF:-project-lucy:customer-amd64-0.16.0-v3}"
MCP_URL="${MCP_URL:-}"
TOKEN="${TOKEN:-}"
CONNECTION_ID="${CONNECTION_ID:-}"

pass=0
fail=0

ok() { echo "[PASS] $*"; pass=$((pass + 1)); }
bad() { echo "[FAIL] $*"; fail=$((fail + 1)); }

echo "=== Lucy K8s 验收 $(date '+%Y-%m-%d %H:%M:%S') ==="
echo "namespace=$NAMESPACE deployment=$DEPLOYMENT service=$SERVICE"

if [[ -f SHA256SUMS ]]; then
  if shasum -a 256 -c SHA256SUMS >/tmp/lucy-sha256.out 2>&1; then
    ok "SHA256SUMS"
  else
    bad "SHA256SUMS"; cat /tmp/lucy-sha256.out | tail -20
  fi
else
  echo "[SKIP] 无 SHA256SUMS（若不在包根目录可忽略）"
fi

if [[ -f "$IMAGE_TAR" ]]; then
  if docker load -i "$IMAGE_TAR" >/tmp/lucy-image-load.out 2>&1; then
    ok "docker load $IMAGE_TAR"
    arch=$(docker image inspect "$IMAGE_REF" --format '{{.Os}}/{{.Architecture}}' 2>/dev/null || true)
    if [[ "$arch" == "linux/amd64" ]]; then
      ok "镜像架构 linux/amd64"
    else
      bad "镜像架构应为 linux/amd64，实际=${arch:-unknown}"
    fi
    image_ver=$(docker run --rm --platform linux/amd64 --entrypoint /bin/sh "$IMAGE_REF" -c 'ktx --version' 2>/tmp/lucy-image-run.err || true)
    if echo "$image_ver" | grep -q '0.16.0'; then
      ok "镜像可执行 ktx --version => $image_ver"
    else
      bad "镜像执行 ktx --version 失败，实际=${image_ver:-empty}"
      tail -20 /tmp/lucy-image-run.err
    fi
  else
    bad "docker load 失败"
    tail -20 /tmp/lucy-image-load.out
  fi
else
  echo "[SKIP] 本地无 $IMAGE_TAR（若镜像已在集群节点可忽略）"
fi

if kubectl -n "$NAMESPACE" get deploy "$DEPLOYMENT" >/dev/null 2>&1; then
  ready=$(kubectl -n "$NAMESPACE" get deploy "$DEPLOYMENT" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)
  if [[ "${ready:-0}" == "1" ]]; then
    ok "Deployment ReadyReplicas=1"
  else
    bad "Deployment ReadyReplicas=${ready:-0}（期望 1）"
  fi
else
  bad "找不到 Deployment $NAMESPACE/$DEPLOYMENT"
fi

if kubectl -n "$NAMESPACE" get svc "$SERVICE" >/dev/null 2>&1; then
  ports=$(kubectl -n "$NAMESPACE" get svc "$SERVICE" -o jsonpath='{range .spec.ports[*]}{.port}{" "}{end}' 2>/dev/null || true)
  echo "Service ports: $ports"
  if echo " $ports " | grep -q ' 7878 '; then
    bad "Service 暴露了 7878（严禁）"
  else
    ok "Service 未暴露 7878"
  fi
  if echo " $ports " | grep -q ' 5174 ' && echo " $ports " | grep -q ' 7879 '; then
    ok "Service 含 5174 与 7879"
  else
    bad "Service 应含 5174 与 7879，实际: $ports"
  fi
else
  bad "找不到 Service $NAMESPACE/$SERVICE"
fi

ver=$(kubectl -n "$NAMESPACE" exec "deploy/$DEPLOYMENT" -c "$CONTAINER" -- ktx --version 2>/dev/null || true)
if echo "$ver" | grep -q '0.16.0'; then
  ok "ktx --version => $ver"
else
  bad "ktx --version 期望含 0.16.0，实际=${ver:-empty}"
fi

# health via port-forward
pf_pid=""
cleanup() { [[ -n "${pf_pid}" ]] && kill "$pf_pid" 2>/dev/null || true; }
trap cleanup EXIT
kubectl -n "$NAMESPACE" port-forward "svc/$SERVICE" 5174:5174 7879:7879 >/tmp/lucy-pf.log 2>&1 &
pf_pid=$!
sleep 2

if curl -fsS --max-time 10 http://127.0.0.1:5174/api/health >/tmp/lucy-health.json 2>/dev/null; then
  if grep -q '"ok":true' /tmp/lucy-health.json \
    && grep -q '0.16.0' /tmp/lucy-health.json; then
    ok "/api/health ok + bundledKtxVersion 0.16.0"
  else
    bad "/api/health 响应异常: $(cat /tmp/lucy-health.json)"
  fi
else
  bad "curl /api/health 失败（见 /tmp/lucy-pf.log）"
fi

if [[ -n "$TOKEN" ]]; then
  url="${MCP_URL:-http://127.0.0.1:7879/mcp}"
  code=$(curl -sS -o /tmp/lucy-mcp-init.json -w '%{http_code}' --max-time 15 \
    -X POST "$url" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"acceptance","version":"0"}}}' || echo 000)
  if [[ "$code" == "200" ]]; then
    ok "MCP initialize HTTP 200 ($url)"
  else
    bad "MCP initialize HTTP $code ($url)"
  fi
  code401=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 10 \
    -X POST "$url" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"acceptance","version":"0"}}}' || echo 000)
  if [[ "$code401" == "401" ]]; then
    ok "无 Token MCP 返回 401"
  else
    bad "无 Token 期望 401，实际 $code401"
  fi
else
  echo "[SKIP] 未设置 TOKEN，跳过 MCP 鉴权验收（export TOKEN=... 后重跑）"
fi

if [[ -n "$CONNECTION_ID" ]]; then
  if kubectl -n "$NAMESPACE" exec "deploy/$DEPLOYMENT" -c "$CONTAINER" -- \
    ktx --project-dir /data/lucy connection test "$CONNECTION_ID"; then
    ok "connection test $CONNECTION_ID"
  else
    bad "connection test $CONNECTION_ID 失败"
  fi
else
  echo "[SKIP] 未设置 CONNECTION_ID，跳过库连通验收"
fi

echo "=== 结果: PASS=$pass FAIL=$fail ==="
[[ "$fail" -eq 0 ]]
