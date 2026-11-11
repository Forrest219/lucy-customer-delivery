# Release Notes — lucy-k8s-integration-20261111-r1（Lucy 0.25.0 平滑升级包）

## 摘要

对齐包 `lucy-k8s-integration-delivery-20261111-r1`：Lucy **0.25.0** / KTX **0.16.0** / Chart **0.2.8**。本包基于 `project-lucy@9c78b0e3`，面向已有 K8s/Helm 环境的**原地平滑升级**（保留 PVC / Secret / 既有资源名），并收口连接加载、Catalog 读取与 SelectDB 结构读取相关修复。

本轮按交付方要求跳过原生 amd64 升级重验；本机已完成镜像 G1–G4/G4b/G8、Helm 静态门禁与离线封包校验。`productionReady` 仍记为 false，现场升级后请按包内 `ACCEPTANCE.md` / 本仓库 `验收命令.sh` 回传结果。

## 镜像与包

| 项 | 值 |
|---|---|
| Tag | `project-lucy:customer-amd64-0.25.0-20261111-9c78b0e3` |
| Config ID | `sha256:e3c78920192a82b5452a6ca786c253fd16044331905f2da8ce603e39ce309e2f` |
| Platform manifest | `sha256:c04234ec52a32d0c2cf691da58bce434a7e93e8511993a455ab6be1106321f0e` |
| Index / image ID | `sha256:f9630570416dc760698a76dc4c9eade48e86a496b9fc43cb4a2f983cea7b7794` |
| Platform | `linux/amd64`（ELF node+tini+runtime-python 经 G2 校验） |
| 包 SHA256 | `8a66bbdf02ae79c33c3a89dbc5e869e3b9bb31b2e100a21e43bbc47264c04fac` |
| Lucy / KTX | `0.25.0` / `@kaelio/ktx@0.16.0` |
| Chart | `0.2.8`（`appVersion` `0.25.0`） |
| 源码 | `project-lucy@9c78b0e367c7466c697e3b1627ba800afa8956f1`（clean） |

## 本版修复（相对现场 0.25 基线）

1. **连接写路径 / 执行层重载**：写 `ktx.yaml` 后自动尝试重载；成功不再误标 pending，失败仍可由所有者确认重试。
2. **SelectDB / 外部 Catalog 结构读取**：连接错误与超时直接报错；仅在语句被拒时回退 `SHOW COLUMNS` / `DESCRIBE`；前端文案脱敏。
3. **Catalog / Schema 结构读取路径加固**：宽表与结构 diff 相关读取对齐，降低误用 SHOW 路径与错误掩盖。

产品线相对 `20261009-v1`（0.17.0）另含 0.25.0 已合并能力（执行层重载、lucy-ops、用量口径、访问关系图等）；详见包内 `RELEASE_NOTES.md` 与供应方 `CHANGELOG`。

## 升级路径（标准）

```bash
shasum -a 256 -c lucy-k8s-integration-delivery-20261111-r1.tar.gz.sha256
tar -xzf lucy-k8s-integration-delivery-20261111-r1.tar.gz
cd lucy-k8s-integration-delivery-20261111-r1

# 导入镜像（K3s 用 k3s ctr images import；Docker 节点可用 docker load）
# 修改 values：image.repository/tag、env.LUCY_PUBLIC_MCP_URL、persistence、existingSecret

bash scripts/preflight-upgrade.sh \
  --namespace <ns> --release <release> \
  --deployment <deploy名> -f <your-values>

helm upgrade <release> helm/lucy -n <ns> -f <your-values> --atomic --wait --timeout 15m

export LUCY_MCP_TOKEN="<bearer>"
bash scripts/acceptance.sh --namespace <ns> --release <release> \
  --deployment <deploy名> --service <svc名> \
  --public-mcp-url https://lucy.<贵司域名>/mcp
```

已用现场兼容 Chart（仅管理既有 Deployment/Service、PVC/Secret/Ingress 外置）的环境：可继续沿用该 Chart，只替换镜像 tag / digest 后 `helm upgrade`；契约仍须满足 UID 10001、单副本 Recreate、不暴露 7878。

## 作废 / 取代

- `lucy-k8s-integration-delivery-20261009-v1`（Lucy 0.17.0）——由本包取代为当前推荐平滑升级发放版
- 更早的 arm64 坏包、20260902-v1/v2、Chart ≤ 0.2.2、未 bake-in runtime 的 0.16.0 era 包——继续勿用

## 不包含

- 数据库密码、MCP Token、私有 bootstrap 密钥明文（本包为 `--public-release`）
- 原生 amd64 集群上的本次升级/恢复重验证据（本轮未执行）
