# Lucy Customer Delivery（手册）

本仓库**存放客户 IT 部署手册与参数示例**。镜像大包通过本仓库 Release 资产发放，也可经另渠道（飞书/网盘/邮件）获取——两个渠道内容相同，一律以 SHA256 校验值为准。

## 当前版本（20261117-r1，Lucy 0.30.0 平滑升级包）

| 项 | 值 |
|---|---|
| 包标识 | `lucy-k8s-integration-delivery-20261117-r1` |
| 镜像 | `project-lucy:customer-amd64-0.30.0-20261117-abb38913`（linux/amd64） |
| 镜像 config ID | `sha256:3f02583efe855ea87dafaa77e4ef23fc91f4d7681ff7c97c76ea4aa3031e46f4` |
| 包 SHA256 | `f0c3e122db08e74fed8473748dd82889fbf8c81bf6b08c32391662e438057985` |
| Chart | **0.2.9**（`appVersion` `0.30.0`）。本次现场升级用单独包 `lucy-helm-v261117.tgz`（SHA256 `63c85848e801350a016ac3ced51a640cde0e7177f85ef39a70b892e7f9197089`），解压目录为 `helm/`。镜像大包里的 `helm/lucy` 不用于本次现场升级 |
| Lucy / KTX | Lucy `0.30.0` / `@kaelio/ktx@0.16.0`（两者是独立版本） |
| 源码 | `project-lucy@abb38913`（`abb3891333561f1cc66d61b0cc160225e6366021`） |
| 交付模式 | offline（`pullPolicy: Never`；`image.digest` 留空，digest 语义见 `集成说明.md` §2） |

### 本版要点

- **相对上一现场包 `20261113-r1`（Lucy 0.30.0 / Chart 0.2.8）**：产品版本仍是 `0.30.0`，KTX 仍是 `0.16.0`，Chart 升到 `0.2.9`。启动和就绪探针改为 `/api/readyz`，存活探针改为 `/api/livez`。
- **多表命中**：已声明 join 并连通的表直接放行；没有 join 的放行并在可核对信息里披露来源；解析不到、跨连接或一次超过 4 个来源仍然硬拦。
- **审计与 MCP**：同一次调用按阶段留下 Trace；封存导出增加 `spans.csv`。握手说明在权限未变时走缓存，拒绝更快，失败信息带可操作的下一步。
- 镜像运行身份 **UID/GID 10001**；`project-migrate` init 仅 chown；`git init` 由镜像入口幂等完成。

### 镜像大包获取

- GitHub Release 资产：https://github.com/Forrest219/lucy-customer-delivery/releases
- 或另渠道（飞书/网盘/邮件）同名文件

```text
lucy-k8s-integration-delivery-20261117-r1.tar.gz
lucy-k8s-integration-delivery-20261117-r1.tar.gz.sha256
lucy-helm-v261117.tgz
lucy-helm-v261117.tgz.sha256
```

收到后先分别校验两个包：`shasum -a 256 -c lucy-k8s-integration-delivery-20261117-r1.tar.gz.sha256` 与 `shasum -a 256 -c lucy-helm-v261117.tgz.sha256`。

### ⛔ 勿用旧包

| 包 / 镜像 | 作废原因 |
|---|---|
| `lucy-k8s-integration-20260827-v1` | 镜像 ELF 实为 arm64，x86 服务器 `exec format error` |
| `lucy-k8s-integration-delivery-20260902-v1` / `v2` | 升级契约不完整，**禁止用于原地升级** |
| `lucy-k8s-integration-20260828-v1` 及 Chart 0.2.2 及以前的包 | Secret 只读挂载导致 WebUI 写数据源 `EROFS`；无升级预检 |
| `project-lucy:customer-amd64-0.16.0` 及同 era tar | runtime 未 bake-in，内网查询会报 `could not download uv` |
| `lucy-k8s-integration-delivery-20261113-r1`（0.30.0 / Chart 0.2.8） | 已被本包取代；仅作历史回滚参考 |
| `lucy-k8s-integration-delivery-20261111-r1`（0.25.0） | 更早现场包；仅作历史回滚参考 |
| `lucy-k8s-integration-delivery-20261009-v1`（0.17.0） | 更早的现场包；仅作历史回滚参考 |

### 阅读顺序

1. [`请先阅读.md`](请先阅读.md) — 首读导航 + 名词解释
2. [`集成说明.md`](集成说明.md) — 主文档：导入 → 配置 → 预检 → 安装/升级 → 验收 → 排障
3. [`K8s部署契约.md`](K8s部署契约.md) — 硬约束（自研 Chart 场景必看）
4. [`values-example.yaml`](values-example.yaml) — 参数示例（抄字段含义，勿照抄测试值）
5. 升级前运行包内 `scripts/preflight-upgrade.sh`；部署完成后运行包内 `scripts/acceptance.sh`（或本仓库 [`验收命令.sh`](验收命令.sh)）

历史版本记录见 [`RELEASE_NOTES.md`](RELEASE_NOTES.md)。

## 反馈渠道

- 本仓库 issue：https://github.com/Forrest219/lucy-customer-delivery/issues
- 或联系交付方对接人（飞书/邮件）
