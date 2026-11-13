# Release Notes — lucy-k8s-integration-20261113-r1（Lucy 0.30.0 平滑升级包）

## 摘要

对齐包 `lucy-k8s-integration-delivery-20261113-r1`：Lucy **0.30.0** / KTX **0.16.0** / Chart **0.2.8**。本包基于 `project-lucy@3a9f0711`（clean），面向已有 K8s/Helm 环境的**原地平滑升级**（保留 PVC / Secret / 既有资源名）。相对上一现场包 `20261111-r1`（Lucy 0.25.0）。

本机已完成镜像 G1–G4/G4b/G8、Helm 静态门禁与离线封包校验。原生 amd64 集群上的本次升级与恢复重验未执行。`productionReady` 仍为 false。现场升级后请按包内 `ACCEPTANCE.md` / 本仓库 `验收命令.sh` 回传结果。

## 镜像与包

| 项 | 值 |
|---|---|
| Tag | `project-lucy:customer-amd64-0.30.0-20261113-3a9f0711` |
| Config ID | `sha256:17d5ded730ac7c8e83fd0106dcfd60ba69856234bf6d93feb13e95ad37d67159` |
| Platform manifest | `sha256:ae3d4f48a4615f874fc208fa779dd8ff71159fba8d0483cb4d088484c29d3bb7` |
| Index / image ID | `sha256:f6c15267f863769ebdd1d47dace6162e329219e9ad05fb14cdc0062aa8a0a9c9` |
| Platform | `linux/amd64`（ELF node+tini+runtime-python 经 G2 校验） |
| 包 SHA256 | `9adf590da7fa98b9a7604851a5cc63110e8db2ffe71feb2daeb99c5c63f316c0` |
| Lucy / KTX | `0.30.0` / `@kaelio/ktx@0.16.0` |
| Chart | `0.2.8`（`appVersion` `0.30.0`） |
| 现场 Helm | `lucy-helm-v261113.tgz` |
| 现场 Helm SHA256 | `2792727105a6c669b99441b7d6d144b17311ff6d3075f91efae1e3e4ccbef50f` |
| 源码 | `project-lucy@3a9f0711a81c9281e6abaa7977c2c9f7b9c42287`（clean） |

## 本版内容（相对现场 0.25.0 / 20261111-r1）

1. **问数约束**：问题类型可绑定唯一数据源和固定口径；多个可见来源都能回答同一业务词时先澄清；Catalog 带回业务描述；可按 Source 裁剪暴露字段。
2. **答复**：成功查询带上来源、口径与截止期等可核对信息；严格 0 行时带结构化下一步。截止期未核到时标成未核对。
3. **问询预算**：默认 60 次调用／300 秒。审计可带预算快照。
4. **连接写路径**：具备 supervisor 时，创建或编辑连接后走执行层重载，并回报配置是否已经进入执行层。

`20261111-r1` 已带上的连接重载、SelectDB / Catalog 结构读取修复仍在本镜像中。详见包内 `RELEASE_NOTES.md` 与供应方 `docs/releases/v0.30.0-user-facing.md`。

## 升级路径（标准）

通用环境可以用镜像大包里的 `helm/lucy`。本次 `lucy-system` 现场升级用下一节的单独 Helm 包，不用包内 `helm/lucy`。

```bash
shasum -a 256 -c lucy-k8s-integration-delivery-20261113-r1.tar.gz.sha256
tar -xzf lucy-k8s-integration-delivery-20261113-r1.tar.gz
cd lucy-k8s-integration-delivery-20261113-r1

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

## 本次现场升级（lucy-system）

两份材料分开校验。现场 Helm 用 `lucy-helm-v261113.tgz`。镜像大包里的 `helm/lucy` 不用于本次现场升级。PVC、`lucy-doris`、`lucy-bootstrap` 和 Ingress 继续沿用，不新发管理员密钥。升级前备份 `/data/lucy`。单副本重建，升级期间服务会中断。

现场 values 继续用已有的 `helm/values.m69.yaml`，把镜像指到 `mjhub.matrixback.com/lucy/lucy-runtime:20261113-r1`。

```bash
shasum -a 256 -c lucy-k8s-integration-delivery-20261113-r1.tar.gz.sha256
shasum -a 256 -c lucy-helm-v261113.tgz.sha256

tar -xzf lucy-k8s-integration-delivery-20261113-r1.tar.gz
docker load -i lucy-k8s-integration-delivery-20261113-r1/image/project-lucy-customer-amd64-0.30.0-20261113-3a9f0711.tar

docker tag project-lucy:customer-amd64-0.30.0-20261113-3a9f0711 \
  mjhub.matrixback.com/lucy/lucy-runtime:20261113-r1
docker push mjhub.matrixback.com/lucy/lucy-runtime:20261113-r1

tar -xzf lucy-helm-v261113.tgz
helm upgrade <现有 release 名> helm -n lucy-system -f helm/values.m69.yaml
```

升级后检查：管理台可以登录，Hive 能列出表，`jipaas_poc` 能读取表结构，新建连接后 Agent 能读到数据。

## 作废 / 取代

- `lucy-k8s-integration-delivery-20261111-r1`（Lucy 0.25.0）——由本包取代为当前推荐平滑升级发放版；仅作历史回滚参考
- `lucy-k8s-integration-delivery-20261009-v1`（Lucy 0.17.0）——更早现场包
- 更早的 arm64 坏包、20260902-v1/v2、Chart ≤ 0.2.2、未 bake-in runtime 的 0.16.0 era 包——继续勿用

## 不包含

- 数据库密码、MCP Token、私有 bootstrap 密钥明文（本包为 `--public-release`）
- 原生 amd64 集群上的本次升级/恢复重验证据（本轮未执行）
