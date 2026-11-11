# Lucy Customer Delivery（手册）

本仓库**存放客户 IT 部署手册与参数示例**。镜像大包通过本仓库 Release 资产发放，也可经另渠道（飞书/网盘/邮件）获取——两个渠道内容相同，一律以 SHA256 校验值为准。

## 当前版本（20261111-r1，Lucy 0.25.0 平滑升级包）

| 项 | 值 |
|---|---|
| 包标识 | `lucy-k8s-integration-delivery-20261111-r1` |
| 镜像 | `project-lucy:customer-amd64-0.25.0-20261111-9c78b0e3`（linux/amd64） |
| 镜像 config ID | `sha256:e3c78920192a82b5452a6ca786c253fd16044331905f2da8ce603e39ce309e2f` |
| 包 SHA256 | `8a66bbdf02ae79c33c3a89dbc5e869e3b9bb31b2e100a21e43bbc47264c04fac` |
| Chart | `helm/lucy/` **0.2.8**（受支持安装包，随 tar.gz 交付，可直接 `helm install` / `helm upgrade`） |
| Lucy / KTX | Lucy `0.25.0` / `@kaelio/ktx@0.16.0`（两者是独立版本） |
| 源码 | `project-lucy@9c78b0e3`（`9c78b0e367c7466c697e3b1627ba800afa8956f1`） |
| 交付模式 | offline（`pullPolicy: Never`；`image.digest` 留空，digest 语义见 `集成说明.md` §2） |

### 本版要点

- **相对上一客户正式版 `20261009-v1`（0.17.0）的产品线升级**：对齐 Lucy `0.25.0` / Chart `0.2.8`，保留 RWO PVC 原地升级契约（单副本 `Recreate`、UID 10001、`secrets-sync`、升级前预检）。
- **本轮修复重点（连接 / Catalog / SelectDB）**：写 `ktx.yaml` 后执行层重载状态不再误标 pending；SelectDB 外部 Catalog 结构读取在连接错误时直接报错，仅在语句被拒时回退 `SHOW COLUMNS` / `DESCRIBE`；前端脱敏，原始驱动错误留服务端。
- **平滑升级预检仍在**：包内 `scripts/preflight-upgrade.sh` 在 `helm upgrade` 前检查 live Deployment 漂移、语义层非法类型、旧 `access.yaml` AbsoluteDeny 工具冲突。
- 镜像运行身份 **UID/GID 10001**；探针全部 HTTP `GET /api/health`；`project-migrate` init 仅 chown；`git init` 由镜像入口幂等完成。

### 镜像大包获取

- GitHub Release 资产：https://github.com/Forrest219/lucy-customer-delivery/releases
- 或另渠道（飞书/网盘/邮件）同名文件

```text
lucy-k8s-integration-delivery-20261111-r1.tar.gz
lucy-k8s-integration-delivery-20261111-r1.tar.gz.sha256
```

收到后第一步永远是 `shasum -a 256 -c *.tar.gz.sha256`。

### ⛔ 勿用旧包

| 包 / 镜像 | 作废原因 |
|---|---|
| `lucy-k8s-integration-20260827-v1` | 镜像 ELF 实为 arm64，x86 服务器 `exec format error` |
| `lucy-k8s-integration-delivery-20260902-v1` / `v2` | 升级契约不完整，**禁止用于原地升级** |
| `lucy-k8s-integration-20260828-v1` 及 Chart 0.2.2 及以前的包 | Secret 只读挂载导致 WebUI 写数据源 `EROFS`；无升级预检 |
| `project-lucy:customer-amd64-0.16.0` 及同 era tar | runtime 未 bake-in，内网查询会报 `could not download uv` |
| `lucy-k8s-integration-delivery-20261009-v1`（0.17.0） | 已被本包（0.25.0）取代；仅作历史回滚参考 |

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
