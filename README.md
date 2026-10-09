# Lucy Customer Delivery（手册）

本仓库**存放客户 IT 部署手册与参数示例**。镜像大包通过本仓库 Release 资产发放，也可经另渠道（飞书/网盘/邮件）获取——两个渠道内容相同，一律以 SHA256 校验值为准。

## 当前版本（20261009-v1，客户正式版）

| 项 | 值 |
|---|---|
| 包标识 | `lucy-k8s-integration-delivery-20261009-v1` |
| 镜像 | `project-lucy:customer-amd64-0.17.0-20261008-e08de17`（linux/amd64，G1–G4 + G8 已通过） |
| 镜像 config ID | `sha256:6f8e471022f4cb2ea4ce1587e63a0043302662be5f1509f01173fea2d69aeb07` |
| 包 SHA256 | `01b2713a112ea3e10c0477b027472473cbfc124be50e7e878e0020376400144b` |
| Chart | `helm/lucy/` **0.2.4**（受支持安装包，随 tar.gz 交付，可直接 `helm install` / `helm upgrade`） |
| Lucy / KTX | Lucy `0.17.0` / `@kaelio/ktx@0.16.0`（两者是独立版本） |
| 源码 | `project-lucy@e08de17`（tag `customer-delivery-20261009-v1`） |
| 交付模式 | offline（`pullPolicy: Never`；`image.digest` 留空，digest 语义见 `集成说明.md` §2） |

### 本版要点

- **平滑升级预检**（Chart 0.2.4 新增）：包内 `scripts/preflight-upgrade.sh` 在 `helm upgrade` 前检查三类存量问题——live Deployment 人工补丁漂移（command/args、hotfix 挂载、多余 init container）、SQL Server 语义层原生类型、旧 `access.yaml` 角色工具与 AbsoluteDeny 冲突。默认只报告不修改；`--apply-types` / `--apply-access` 才会改文件且先自动备份。
- **密码 Secret 可写兼容**（0.2.3 起）：DB 密码 Secret 不再直接挂载到 `/data/lucy/.ktx/secrets`（只读挂载会导致 WebUI 新建数据源报 `EROFS`），改由 `secrets-sync` init 复制进 PVC（目录 0700、文件 0600、属主 10001）。
- **旧 PVC 布局兼容**：`env.LUCY_CONTENT_ROOT` 支持 pre-M31 的平铺布局；`fullnameOverride` 固定既有 Deployment/Service 资源名。
- **验收脚本修正**：Secret 目录带 fsGroup setgid 位（`2700`）不再误报；MCP `initialize` 按 JSON-RPC 结构校验，不再固定匹配旧服务名。
- 镜像运行身份 **UID/GID 10001**；探针全部 HTTP `GET /api/health`；`project-migrate` init 仅 chown；`git init` 由镜像入口幂等完成。

### 镜像大包获取

- GitHub Release 资产：https://github.com/Forrest219/lucy-customer-delivery/releases
- 或另渠道（飞书/网盘/邮件）同名文件

```text
lucy-k8s-integration-delivery-20261009-v1.tar.gz
lucy-k8s-integration-delivery-20261009-v1.tar.gz.sha256
```

收到后第一步永远是 `shasum -a 256 -c *.tar.gz.sha256`。

### ⛔ 勿用旧包

| 包 / 镜像 | 作废原因 |
|---|---|
| `lucy-k8s-integration-20260827-v1` | 镜像 ELF 实为 arm64，x86 服务器 `exec format error` |
| `lucy-k8s-integration-delivery-20260902-v1` / `v2` | 升级契约不完整（root 运行、无 `.git` 初始化职责划分），**禁止用于原地升级** |
| `lucy-k8s-integration-20260828-v1` 及 Chart 0.2.2 及以前的包 | Secret 只读挂载导致 WebUI 写数据源 `EROFS`；无升级预检 |
| `project-lucy:customer-amd64-0.16.0` 及同 era tar | 过 G4b 之前产物，runtime 未 bake-in，内网查询会报 `could not download uv` |

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
