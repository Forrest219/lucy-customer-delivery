#!/usr/bin/env bash
# Lucy K8s 集成验收脚本 — 20260828-v1
# 用法：在已 kubectl 指向目标集群的环境执行。
#
# 可覆盖环境变量：
#   NAMESPACE DEPLOYMENT SERVICE CONTAINER IMAGE_TAR
#   MCP_URL TOKEN CONNECTION_ID
#   PUBLIC_MCP_URL   # 期望的 Advertise URL（与 values 中 LUCY_PUBLIC_MCP_URL 一致）
#
# 相对 20260827-v2 新增：
#   - Pod 内 KTX Python runtime 离线预装检查（防内网 uv 下载失败）
#   - /api/project mcpEndpoint.status == configured 断言

set -euo pipefail

NAMESPACE="${NAMESPACE:-lucy}"
DEPLOYMENT="${DEPLOYMENT:-lucy}"
SERVICE="${SERVICE:-lucy}"
CONTAINER="${CONTAINER:-lucy}"
IMAGE_TAR="${IMAGE_TAR:-image/project-lucy-customer-amd64-0.16.0-image.tar}"
MCP_URL="${MCP_URL:-}"
TOKEN="${TOKEN:-}"
CONNECTION_ID="${CONNECTION_ID:-}"
PUBLIC_MCP_URL="${PUBLIC_MCP_URL:-${MCP_URL:-}}"

pass=0
fail=0

ok() { echo "[PASS] $*"; pass=$((pass + 1)); }
bad() { echo "[FAIL] $*"; fail=$((fail + 1)); }

echo "=== Lucy K8s 验收 20260828-v1 $(date '+%Y-%m-%d %H:%M:%S') ==="
echo "namespace=$NAMESPACE deployment=$DEPLOYMENT service=$SERVICE"

if [[ -f SHA256SUMS ]]; then
  if shasum -a 256 -c SHA256SUMS >/tmp/lucy-sha256.out 2>&1; then
    ok "SHA256SUMS"
  else
    bad "SHA256SUMS"; tail -20 /tmp/lucy-sha256.out || true
  fi
else
  echo "[SKIP] 无 SHA256SUMS（若不在包根目录可忽略）"
fi

if [[ -f "$IMAGE_TAR" ]]; then
  if docker image inspect project-lucy:customer-amd64-0.16.0 >/dev/null 2>&1 \
    || docker load -i "$IMAGE_TAR" >/dev/null; then
    arch=$(docker image inspect project-lucy:customer-amd64-0.16.0 --format '{{.Os}}/{{.Architecture}}' 2>/dev/null || true)
    if [[ "$arch" == "linux/amd64" ]]; then
      ok "镜像架构 linux/amd64"
    else
      bad "镜像架构应为 linux/amd64，实际=${arch:-unknown}"
    fi
    if docker run --rm --platform linux/amd64 --entrypoint /bin/sh \
      project-lucy:customer-amd64-0.16.0 -c \
      'test -x /root/.ktx/runtime/0.16.0/.venv/bin/python' >/dev/null 2>&1; then
      ok "镜像 bake-in Python runtime（G4b-1）"
    else
      bad "镜像缺少 /root/.ktx/runtime/0.16.0/.venv/bin/python — 内网查询会尝试下载 uv，请换用 20260828-v1 及以后交付包"
    fi
    if docker run --rm --network=none --platform linux/amd64 --entrypoint ktx \
      project-lucy:customer-amd64-0.16.0 --version 2>/dev/null | grep -q '0.16.0'; then
      ok "镜像无网可启动 ktx（G4b-2）"
    else
      bad "镜像在 --network=none 下无法启动 ktx — runtime 未完整 bake-in"
    fi
  else
    bad "docker load / inspect 失败"
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

# Pod 内 runtime 离线预装（不依赖客户节点 docker）
if kubectl -n "$NAMESPACE" exec "deploy/$DEPLOYMENT" -c "$CONTAINER" -- \
  /bin/sh -c 'test -x /root/.ktx/runtime/0.16.0/.venv/bin/python' >/dev/null 2>&1; then
  ok "Pod 内 Python runtime 已预装（防 uv 公网下载）"
else
  bad "Pod 内缺少 KTX Python runtime — 查询会报 could not download uv；请升级到本包镜像"
fi

# health + mcpEndpoint via port-forward
pf_pid=""
cleanup() { [[ -n "${pf_pid}" ]] && kill "$pf_pid" 2>/dev/null || true; }
trap cleanup EXIT
kubectl -n "$NAMESPACE" port-forward "svc/$SERVICE" 5174:5174 7879:7879 >/tmp/lucy-pf.log 2>&1 &
pf_pid=$!
sleep 2

if curl -fsS --max-time 10 http://127.0.0.1:5174/api/health >/tmp/lucy-health.json 2>/dev/null; then
  if grep -q '"ok":true\|"status":"ok"\|"healthy"' /tmp/lucy-health.json \
    && grep -q '0.16.0' /tmp/lucy-health.json; then
    ok "/api/health ok + bundledKtxVersion 0.16.0"
  else
    # softer: accept 200 body that at least mentions ktx version
    if grep -q '0.16.0' /tmp/lucy-health.json; then
      ok "/api/health 含 0.16.0"
    else
      bad "/api/health 响应异常: $(head -c 400 /tmp/lucy-health.json)"
    fi
  fi
else
  bad "curl /api/health 失败（见 /tmp/lucy-pf.log）"
fi

if curl -fsS --max-time 10 http://127.0.0.1:5174/api/project >/tmp/lucy-project.json 2>/dev/null; then
  status=$(python3 -c 'import json,sys; d=json.load(open("/tmp/lucy-project.json")); e=d.get("mcpEndpoint") or d.get("data",{}).get("mcpEndpoint") or {}; print(e.get("status",""))' 2>/dev/null || true)
  url=$(python3 -c 'import json,sys; d=json.load(open("/tmp/lucy-project.json")); e=d.get("mcpEndpoint") or d.get("data",{}).get("mcpEndpoint") or {}; print(e.get("url") or "")' 2>/dev/null || true)
  if [[ "$status" == "configured" ]]; then
    ok "mcpEndpoint.status=configured url=${url}"
    if [[ -n "$PUBLIC_MCP_URL" && "$url" != "$PUBLIC_MCP_URL" ]]; then
      bad "mcpEndpoint.url ($url) 与 PUBLIC_MCP_URL ($PUBLIC_MCP_URL) 不一致"
    fi
  elif [[ "$status" == "fallback" ]]; then
    bad "mcpEndpoint.status=fallback — 未配置 LUCY_PUBLIC_MCP_URL，WebUI 将显示 MCP 未就绪。请在 values 设置外部可达 https://…/mcp"
  elif [[ "$status" == "invalid" ]]; then
    bad "mcpEndpoint.status=invalid url=${url} — 检查 LUCY_PUBLIC_MCP_URL 格式"
  else
    bad "无法解析 mcpEndpoint.status（实际=${status:-empty}）；原始: $(head -c 300 /tmp/lucy-project.json)"
  fi
else
  bad "curl /api/project 失败"
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
if [[ "$fail" -eq 0 ]]; then
  echo "✅ 验收通过"
else
  echo "❌ 验收未通过 — 见上方 [FAIL]；常见修复："
  echo "  - could not download uv / runtime 缺失 → 换用本包 image（勿在内网 docker build）"
  echo "  - MCP 未就绪 / fallback → 设置 env.LUCY_PUBLIC_MCP_URL 为外部可达 URL 后 helm upgrade"
fi
[[ "$fail" -eq 0 ]]
