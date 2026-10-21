# Lucy 2.0.0 r6 升级验证候选（待验）

2026-10-21：新增 [r6 文档](versions/20261021-r6/README.md)，采用“检查单 → 部署 → 创建管理员 → 验收”。原生升级和恢复验收尚未完成，未替换当前正式版。
详细变化与已验/待验范围见 [r6 版本说明](versions/20261021-r6/RELEASE_NOTES.md)。

---

# Release Notes — lucy-k8s-integration-20261009-v1（客户正式版）

## 摘要

对齐包 `lucy-k8s-integration-delivery-20261009-v1`：Lucy 0.17.0 / KTX 0.16.0 / Chart **0.2.4**。本版在 test3 真实 K3s 平滑升级验收（Helm revision 13、既有 `lucy` RWO PVC、外部端口 8276/8277）反馈的基础上修复了全部 5 个现场问题，是当前唯一推荐的客户发放版。

## 镜像与包

| 项 | 值 |
|---|---|
| Tag | `project-lucy:customer-amd64-0.17.0-20261008-e08de17` |
| Config ID | `sha256:6f8e471022f4cb2ea4ce1587e63a0043302662be5f1509f01173fea2d69aeb07` |
| Platform | `linux/amd64`（ELF node+tini 经 G2 校验） |
| 包 SHA256 | `01b2713a112ea3e10c0477b027472473cbfc124be50e7e878e0020376400144b` |
| Lucy / KTX | `0.17.0` / `@kaelio/ktx@0.16.0` |
| 源码 | `project-lucy@e08de17`（tag `customer-delivery-20261009-v1`） |
| 出包门禁 | G1–G4 + G8 本机通过；包验证脚本（helm lint / H1 / K6）全量通过；负向契约测试 29/29 |

## test3 升级验收反馈的修复核销（本版核心）

| # | 现场问题 | 本版修复 |
|---|---|---|
| 3.1 | 验收脚本把 fsGroup setgid 的 `2700` 误报为权限错误 | `acceptance.sh` 改权限位语义检查：低 9 位须 `0700`、属主 `10001:10001`、仅允许 setgid；密码文件同理按 `0600` 位语义校验 |
| 3.2 | 验收脚本固定匹配 `lucy-mcp-proxy`，误报 MCP 初始化失败 | 改按 JSON-RPC 结构校验（`result` / `protocolVersion` / `serverInfo`），兼容上游透传名 `ktx`；失败时不回显响应体 |
| 3.3 | 存量 Deployment 人工补丁（旧 command/args、hotfix 挂载）导致新 Pod CrashLoop | 新增 `scripts/preflight-upgrade.sh`：渲染 Chart 对比 live Deployment，报告漂移并打印 JSON Patch（只打印不执行，人工确认后应用） |
| 3.4 | SQL Server 语义层原生类型（`varchar`/`datetime2` 等）无法通过新版校验 | 预检 `scan-types` 报告具体文件/字段/类型；`--apply-types` 按固定映射表改写（string/number/time/boolean），先自动备份；`geometry` 等无映射类型只报告不改 |
| 3.5 | 旧 `access.yaml` 角色工具（`sl_query`/`sl_read_source`）触发 AbsoluteDeny，Agent degraded | 预检 `scan-access` 只查 `roles.*.allow.tools`；`--apply-access` 仅从角色列表移除并先备份；`defaults.known_tools` 等全局定义不动 |

## Chart 变更轨迹（0.2.2 → 0.2.4）

- **0.2.3**：DB 密码 Secret 改由 `secrets-sync` init 复制进 PVC（修复 WebUI 写数据源 `EROFS`）；`env.LUCY_CONTENT_ROOT` 兼容 pre-M31 平铺布局；`fullnameOverride` 固定既有资源名；包内脚本可从包根直接运行。
- **0.2.4**：新增 `preflight-upgrade.sh` 升级前在线预检（上述 3.3/3.4/3.5）；`UPGRADE.md` 明确「先预检、确认 PATCH、再 `helm upgrade`」的流程，`helm upgrade --force` 仅作退路。

## 手册主要变更（相对 20261008-test 草稿）

- 全部身份信息更新为客户正式版（包名 / 镜像 tag / config ID / 包 SHA256 / Chart 0.2.4）
- `集成说明.md` 新增 §6.1 升级前在线预检、密码 Secret 同步行为表、旧 PVC 平铺布局说明
- 验收口径改走 `LUCY_MCP_TOKEN` 环境变量（包内脚本拒绝 `--token` 参数）
- `K8s部署契约.md` Secret 一节改写为 secrets-sync 契约（禁止 Secret 直接挂载 `.ktx/secrets`）
- 排障表补入 test3 现场症状（漂移 CrashLoop、AbsoluteDeny degraded、SQL 类型校验、2700 误报、MCP 名称误报、content root、selector 不可变）
- 大包改为 GitHub Release 资产 + 另渠道双通道发放

## Deprecated（勿用于原地升级）

- `lucy-k8s-integration-20260827-v1`（arm64 ELF 坏包）
- `lucy-k8s-integration-delivery-20260902-v1` / `v2`（升级契约不完整）
- `lucy-k8s-integration-20260828-v1` 及 Chart ≤ 0.2.2 的包（Secret 只读挂载 `EROFS`、无升级预检）
- `project-lucy:customer-amd64-0.16.0` 及同 era 未过 G4b 的 tar
- 内部测试包 `20261008-test` / `20261008-test3` / `20261009-test` / `20261009-test2` 不对外发放；`20261009-v1` 与 `20261009-test2` 内容一致（同一 sha256，仅文件名不同）

---

<details>
<summary>历史：20261008-test（内部测试包，仅存档）</summary>

Chart 0.2.2 / 镜像 `customer-amd64-0.17.0-20261008-14d7c26` / config ID `sha256:ee595599202fe52a7e382f7d1bc589a840ebe15715560c1857754aa628527934`。手册按 v3 包结构重写的第一版草稿，未对外发放。
</details>

<details>
<summary>历史：20260902-v1（已作废，仅存档）</summary>

v2 交付包布局：受支持 Helm Chart 0.2.0 与镜像同包交付；探针改 HTTP；新增 K8S_CONTRACT / UPGRADE / ROLLBACK / acceptance.sh。

| 项 | 值 |
|---|---|
| Tag | `project-lucy:customer-amd64-0.16.0-20260902-b262798` |
| Digest | `sha256:5038c872ba54e916474d076be2eb683fbc583b9a5c858fee5da2c964d92157b4` |
| Platform | `linux/amd64` |
| KTX | `@kaelio/ktx@0.16.0` |
| 源码 | `project-lucy@b262798` |

作废原因：root 运行 + 升级契约不完整（无 `.git` 初始化职责划分），K3s 原地升级失败；由 20261009-v1 取代。
</details>
