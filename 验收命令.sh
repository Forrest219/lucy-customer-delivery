#!/usr/bin/env bash
# Lucy K8s 集成验收脚本 — 20261113-r1（0.30.0 平滑升级包）
# 用法：在已 kubectl 指向目标集群的环境执行。
#
# 说明：包内 scripts/acceptance.sh 是权威验收（含 secrets 权限位、MCP 结构校验、
#       连接测试与索引重建）；本脚本为中文版补充核查，两者结论应一致。
#       升级前请先运行包内 scripts/preflight-upgrade.sh（漂移/类型/角色预检）。
#
# 可覆盖环境变量：
#   NAMESPACE RELEASE SERVICE CONTAINER IMAGE_NAME IMAGE_TAR
#   MCP_URL TOKEN CONNECTION_ID
#   PUBLIC_MCP_URL   # 期望的 Advertise URL（与 values 中 LUCY_PUBLIC_MCP_URL 一致）
#
# 相对 20261008-test 的变化：
#   - 镜像 tag 更新为 customer-amd64-0.30.0-20261113-3a9f0711（Chart 0.2.8）
#   - 提示以包内 acceptance.sh 为权威（2700 setgid / MCP serverInfo 误报已修正）

set -euo pipefail

NAMESPACE="${NAMESPACE:-lucy}"
RELEASE="${RELEASE:-lucy}"
DEPLOYMENT="${DEPLOYMENT:-$RELEASE}"   # 兼容旧变量名
SERVICE="${SERVICE:-$RELEASE}"
CONTAINER="${CONTAINER:-lucy}"
IMAGE_NAME="${IMAGE_NAME:-project-lucy:customer-amd64-0.30.0-20261113-3a9f0711}"
IMAGE_TAR="${IMAGE_TAR:-}"
MCP_URL="${MCP_URL:-}"
TOKEN="${TOKEN:-}"
CONNECTION_ID="${CONNECTION_ID:-}"
PUBLIC_MCP_URL="${PUBLIC_MCP_URL:-${MCP_URL:-}}"
EXPECT_KTX="${EXPECT_KTX:-0.16.0}"

pass=0
fail=0

ok() { echo "[PASS] $*"; pass=$((pass + 1)); }
bad() { echo "[FAIL] $*"; fail=$((fail + 1)); }

echo "=== Lucy K8s 验收 20261113-r1 $(date '+%Y-%m-%d %H:%M:%S') ==="
echo "namespace=$NAMESPACE release=$RELEASE deployment=$DEPLOYMENT service=$SERVICE"

# ---------- 0. 包完整性 ----------
if [[ -f SHA256SUMS ]]; then
  if shasum -a 256 -c SHA256SUMS >/tmp/lucy-sha256.out 2>&1; then
    ok "SHA256SUMS"
  else
    bad "SHA256SUMS"; tail -20 /tmp/lucy-sha256.out || true
  fi
else
  echo "[SKIP] 无 SHA256SUMS（若不在包根目录可忽略）"
fi

# ---------- 1. 本地镜像（有 tar 或已 load 时） ----------
if [[ -z "$IMAGE_TAR" ]]; then
  # 自动探测包内 image 目录
  IMAGE_TAR="$(ls image/*.tar 2>/dev/null | head -1 || true)"
fi

if [[ -n "$IMAGE_TAR" && -f "$IMAGE_TAR" ]]; then
  if docker image inspect "$IMAGE_NAME" >/dev/null 2>&1 \
    || docker load -i "$IMAGE_TAR" >/dev/null; then
    arch=$(docker image inspect "$IMAGE_NAME" --format '{{.Os}}/{{.Architecture}}' 2>/dev/null || true)
    if [[ "$arch" == "linux/amd64" ]]; then
      ok "镜像架构 linux/amd64"
    else
      bad "镜像架构应为 linux/amd64，实际=${arch:-unknown}"
    fi
    # G4b-1：runtime 在 lucy 用户目录（v3 起 /home/lucy，不是 /root）
    if docker run --rm --platform linux/amd64 --entrypoint /bin/sh \
      "$IMAGE_NAME" -c \
      "test -x /home/lucy/.ktx/runtime/${EXPECT_KTX}/.venv/bin/python" >/dev/null 2>&1; then
      ok "镜像 bake-in Python runtime（G4b-1，/home/lucy 路径）"
    else
      bad "镜像缺少 /home/lucy/.ktx/runtime/${EXPECT_KTX}/.venv/bin/python — 内网查询会尝试下载 uv，请换用 20261113-r1 交付包"
    fi
    # G4b-2：无网启动 ktx
    if docker run --rm --network=none --platform linux/amd64 --entrypoint ktx \
      "$IMAGE_NAME" --version 2>/dev/null | grep -q "$EXPECT_KTX"; then
      ok "镜像无网可启动 ktx（G4b-2）"
    else
      bad "镜像在 --network=none 下无法启动 ktx — runtime 未完整 bake-in"
    fi
  else
    bad "docker load / inspect 失败"
  fi
else
  echo "[SKIP] 本地无镜像 tar（若镜像已在集群节点可忽略）"
fi

# ---------- 2. 工作负载 ----------
if kubectl -n "$NAMESPACE" get deploy "$DEPLOYMENT" >/dev/null 2>&1; then
  ready=$(kubectl -n "$NAMESPACE" get deploy "$DEPLOYMENT" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)
  if [[ "${ready:-0}" == "1" ]]; then
    ok "Deployment ReadyReplicas=1"
  else
    bad "Deployment ReadyReplicas=${ready:-0}（期望 1）"
  fi
  # 容器端口契约 + 运行身份
  cports=$(kubectl -n "$NAMESPACE" get deploy "$DEPLOYMENT" -o jsonpath='{range .spec.template.spec.containers[0].ports[*]}{.containerPort}{" "}{end}' 2>/dev/null || true)
  if echo " $cports " | grep -q ' 5174 ' && echo " $cports " | grep -q ' 7879 '; then
    ok "容器端口含 5174 与 7879"
  else
    bad "容器端口应含 5174 与 7879，实际: ${cports:-empty}"
  fi
  runas=$(kubectl -n "$NAMESPACE" get deploy "$DEPLOYMENT" -o jsonpath='{.spec.template.spec.containers[0].securityContext.runAsUser}' 2>/dev/null || true)
  if [[ "$runas" == "10001" ]]; then
    ok "runAsUser=10001"
  else
    bad "runAsUser 应为 10001，实际=${runas:-empty}"
  fi
  # 探针必须为 HTTP（禁止 exec 探针）
  probe=$(kubectl -n "$NAMESPACE" get deploy "$DEPLOYMENT" -o jsonpath='{.spec.template.spec.containers[0].startupProbe}' 2>/dev/null || true)
  if echo "$probe" | grep -q 'httpGet'; then
    ok "startupProbe 为 HTTP /api/health"
  else
    bad "startupProbe 应为 httpGet /api/health（exec 探针已废弃）"
  fi
else
  bad "找不到 Deployment $NAMESPACE/$DEPLOYMENT"
fi

# ---------- 3. Service ----------
if kubectl -n "$NAMESPACE" get svc "$SERVICE" >/dev/null 2>&1; then
  tports=$(kubectl -n "$NAMESPACE" get svc "$SERVICE" -o jsonpath='{range .spec.ports[*]}{.targetPort}{" "}{end}' 2>/dev/null || true)
  echo "Service targetPorts: $tports"
  if echo " $tports " | grep -q ' 7878 '; then
    bad "Service 暴露了 7878（严禁）"
  else
    ok "Service 未暴露 7878"
  fi
  if echo " $tports " | grep -q ' 5174 ' && echo " $tports " | grep -q ' 7879 '; then
    ok "Service targetPort 指向 5174 与 7879"
  else
    bad "Service targetPort 应指向 5174 与 7879，实际: ${tports:-empty}"
  fi
else
  bad "找不到 Service $NAMESPACE/$SERVICE"
fi

# ---------- 4. Pod 内运行时与版本 ----------
ver=$(kubectl -n "$NAMESPACE" exec "deploy/$DEPLOYMENT" -c "$CONTAINER" -- ktx --version 2>/dev/null || true)
if echo "$ver" | grep -q "$EXPECT_KTX"; then
  ok "ktx --version => $ver"
else
  bad "ktx --version 期望含 $EXPECT_KTX，实际=${ver:-empty}"
fi

if kubectl -n "$NAMESPACE" exec "deploy/$DEPLOYMENT" -c "$CONTAINER" -- \
  /bin/sh -c "test -x /home/lucy/.ktx/runtime/${EXPECT_KTX}/.venv/bin/python" >/dev/null 2>&1; then
  ok "Pod 内 Python runtime 已预装（/home/lucy 路径，防 uv 公网下载）"
else
  bad "Pod 内缺少 KTX Python runtime — 查询会报 could not download uv；请升级到本包镜像"
fi

# ---------- 5. 升级保留检查（自动化门禁不覆盖 evals/，现场单独看） ----------
if kubectl -n "$NAMESPACE" exec "deploy/$DEPLOYMENT" -c "$CONTAINER" -- \
  /bin/sh -c 'test -d /data/lucy/evals' >/dev/null 2>&1; then
  ok "PVC 上 /data/lucy/evals 目录保留"
else
  bad "PVC 上缺少 /data/lucy/evals — 升级可能丢了评估用例目录"
fi

# ---------- 6. health + mcpEndpoint（port-forward） ----------
pf_pid=""
cleanup() { [[ -n "${pf_pid}" ]] && kill "$pf_pid" 2>/dev/null || true; }
trap cleanup EXIT
kubectl -n "$NAMESPACE" port-forward "svc/$SERVICE" 5174:5174 7879:7879 >/tmp/lucy-pf.log 2>&1 &
pf_pid=$!
sleep 2

if curl -fsS --max-time 10 http://127.0.0.1:5174/api/health >/tmp/lucy-health.json 2>/dev/null; then
  if grep -q "$EXPECT_KTX" /tmp/lucy-health.json; then
    ok "/api/health ok + bundledKtxVersion $EXPECT_KTX"
  else
    bad "/api/health 响应异常: $(head -c 400 /tmp/lucy-health.json)"
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
    bad "mcpEndpoint.status=fallback — 未配置 LUCY_PUBLIC_MCP_URL。请在 values 设置外部可达 https://…/mcp 后 helm upgrade"
  elif [[ "$status" == "invalid" ]]; then
    bad "mcpEndpoint.status=invalid url=${url} — 检查 LUCY_PUBLIC_MCP_URL 格式"
  else
    bad "无法解析 mcpEndpoint.status（实际=${status:-empty}）；原始: $(head -c 300 /tmp/lucy-project.json)"
  fi
else
  bad "curl /api/project 失败"
fi

# ---------- 7. MCP 鉴权（有 TOKEN 时） ----------
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

# ---------- 8. 库连通（有 CONNECTION_ID 时） ----------
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
  echo "  - MCP 未就绪 / fallback → 设置 env.LUCY_PUBLIC_MCP_URL 后 helm upgrade（勿 kubectl set env）"
  echo "  - dubious ownership → 确认 projectMigrate.enabled=true 且镜像为 v3+（UID 10001）"
fi
[[ "$fail" -eq 0 ]]
