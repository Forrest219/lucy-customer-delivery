# Release Notes — lucy-k8s-integration-20261117-r1（Lucy 0.30.0 平滑升级包）

## 摘要

对齐包 `lucy-k8s-integration-delivery-20261117-r1`：Lucy **0.30.0** / KTX **0.16.0** / Chart **0.2.9**。本包基于 `project-lucy@abb38913`（clean），面向已有 K8s/Helm 环境的**原地平滑升级**（保留 PVC / Secret / 既有资源名）。相对上一现场包 `20261113-r1`（Lucy 0.30.0 / Chart 0.2.8）。

本机已完成镜像 G1–G4/G4b/G8、Helm 静态门禁与离线封包校验。原生 amd64 集群上的本次升级与恢复重验未执行。`productionReady` 仍为 false。现场升级后请按包内 `ACCEPTANCE.md` / 本仓库 `验收命令.sh` 回传结果。

## 镜像与包

| 项 | 值 |
|---|---|
| Tag | `project-lucy:customer-amd64-0.30.0-20261117-abb38913` |
| Config ID | `sha256:3f02583efe855ea87dafaa77e4ef23fc91f4d7681ff7c97c76ea4aa3031e46f4` |
| Platform manifest | `sha256:6746253d6ab0f6cc95fe4c41b31a0ca17a31ea21bbb79a0d0f93ede87ea012e6` |
| Index / image ID | `sha256:44decaec9dd5694b716e084f0087292cf60557a3ff959346840cf459a63a7ee0` |
| Platform | `linux/amd64`（ELF node+tini+runtime-python 经 G2 校验） |
| 包 SHA256 | `f0c3e122db08e74fed8473748dd82889fbf8c81bf6b08c32391662e438057985` |
| Lucy / KTX | `0.30.0` / `@kaelio/ktx@0.16.0` |
| Chart | `0.2.9`（`appVersion` `0.30.0`） |
| 现场 Helm | `lucy-helm-v261117.tgz` |
| 现场 Helm SHA256 | `63c85848e801350a016ac3ced51a640cde0e7177f85ef39a70b892e7f9197089` |
| 源码 | `project-lucy@abb3891333561f1cc66d61b0cc160225e6366021`（clean） |

## 本版内容（相对现场 20261113-r1）

1. **Chart 0.2.9**：启动和就绪探针改为 `/api/readyz`，存活探针改为 `/api/livez`。`/api/health` 仍可用于人工查看。
2. **多表命中**：语义层已声明 join 并连通的表直接放行；没有 join 的放行，并在成功答复的可核对信息里披露实际来源。解析不到的来源、Catalog 不健康、跨连接、一次超过 4 个来源仍然硬拦。
3. **审计**：同一次 MCP 调用按阶段记 Trace。封存导出新增 `spans.csv`，`calls-v2.csv` 末尾追加三列，原有列顺序不变。
4. **MCP**：权限未变时握手说明走缓存；拒绝更快；不存在的工具名会返回当前可用工具；会话丢失返回 `session_lost`。

`20261113-r1` 已带上的问数约束、可核对答复、连接重载和 Catalog 读取仍在本镜像中。行级隔离尚未验收，不得写成已经可用。详见包内 `RELEASE_NOTES.md`。

## 升级路径（标准）

通用环境可以用镜像大包里的 `helm/lucy`。本次 `lucy-system` 现场升级用下一节的单独 Helm 包，不用包内 `helm/lucy`。

```bash
shasum -a 256 -c lucy-k8s-integration-delivery-20261117-r1.tar.gz.sha256
tar -xzf lucy-k8s-integration-delivery-20261117-r1.tar.gz
cd lucy-k8s-integration-delivery-20261117-r1

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

两份材料分开校验。现场 Helm 用 `lucy-helm-v261117.tgz`。镜像大包里的 `helm/lucy` 不用于本次现场升级。PVC、`lucy-doris`、`lucy-bootstrap` 和 Ingress 继续沿用，不新发管理员密钥。升级前备份 `/data/lucy`。单副本重建，升级期间服务会中断。

现场 values 继续用已有的 `helm/values.m69.yaml`，把镜像指到 `mjhub.matrixback.com/lucy/lucy-runtime:20261117-r1`。若这份 values 写死了探针路径，同一次升级把 startup／readiness 改为 `/api/readyz`，liveness 改为 `/api/livez`。

```bash
shasum -a 256 -c lucy-k8s-integration-delivery-20261117-r1.tar.gz.sha256
shasum -a 256 -c lucy-helm-v261117.tgz.sha256

tar -xzf lucy-k8s-integration-delivery-20261117-r1.tar.gz
docker load -i lucy-k8s-integration-delivery-20261117-r1/image/project-lucy-customer-amd64-0.30.0-20261117-abb38913.tar

docker tag project-lucy:customer-amd64-0.30.0-20261117-abb38913 \
  mjhub.matrixback.com/lucy/lucy-runtime:20261117-r1
docker push mjhub.matrixback.com/lucy/lucy-runtime:20261117-r1

tar -xzf lucy-helm-v261117.tgz
helm upgrade <现有 release 名> helm -n lucy-system -f helm/values.m69.yaml
```

升级后检查：管理台可以登录，Hive 能列出表，`jipaas_poc` 能读取表结构，新建连接后 Agent 能读到数据。

## 作废 / 取代

- `lucy-k8s-integration-delivery-20261113-r1`（Lucy 0.30.0 / Chart 0.2.8）——由本包取代为当前推荐平滑升级发放版；仅作历史回滚参考
- `lucy-k8s-integration-delivery-20261111-r1`（Lucy 0.25.0）——更早现场包
- `lucy-k8s-integration-delivery-20261009-v1`（Lucy 0.17.0）——更早现场包
- 更早的 arm64 坏包、20260902-v1/v2、Chart ≤ 0.2.2、未 bake-in runtime 的 0.16.0 era 包——继续勿用

## 不包含

- 数据库密码、MCP Token、私有 bootstrap 密钥明文（本包为 `--public-release`）
- 原生 amd64 集群上的本次升级/恢复重验证据（本轮未执行）
