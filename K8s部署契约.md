# Lucy K8s 部署契约（20261009-v1）

客户平台工程接入 Lucy 时必须遵守以下硬约束。与包内受支持 Chart `helm/lucy/`（0.2.4）一致；自研 Chart 场景请逐条对照。

## 1. 工作负载

| 项 | 契约 |
|---|---|
| `replicas` | **必须为 1**（本期不支持多副本 HA） |
| `strategy.type` | **Recreate**（RWO PVC 不可双挂；升级有短暂中断） |
| 容器镜像平台 | `linux/amd64` |
| Lucy / KTX 版本 | Lucy `0.17.0` / `@kaelio/ktx@0.16.0`（相互独立，别混用版本号） |
| KTX Python runtime | 镜像必须 bake-in（出包 G4b 校验）；路径 `/home/lucy/.ktx/runtime/0.16.0/.venv/bin/python`；内网禁止依赖现场下载 `uv` |
| `workingDir` | `/data/lucy` |

## 2. 端口

| 端口 | 用途 | 是否进 Service / Ingress |
|---|---|---|
| `5174/tcp` | WebUI / API / `/api/health` | 是（Service 层可重映射，如 8276） |
| `7879/tcp` | Lucy MCP Proxy（Agent 入口） | 是（Service 层可重映射，如 8277） |
| `7878/tcp` | KTX MCP upstream（Pod 内 `127.0.0.1`） | **否。严禁暴露** |

容器端口与 Service 端口分离：容器内固定 5174/7879，对外端口只在 Service 层映射。

## 3. 持久化

| 项 | 契约 |
|---|---|
| 挂载点 | `/data/lucy` |
| accessModes | `ReadWriteOnce` |
| 内容 | `ktx.yaml`、semantic-layer、wiki、**evals**、skills、access.yaml、admins.yaml、`.ktx/`（含 secrets）、`.ktx-ui/`（含 audit）、`.git`（新装实例业务内容在 `/data/lucy/config/` 下；pre-M31 旧盘为平铺布局，需 `env.LUCY_CONTENT_ROOT: "."`） |
| 升级 | 保留 PVC；`evals/` 等全部目录必须在升级后仍在 |
| 卸载 | 删 Deployment/Service **不**自动删数据；删 PVC 前必须备份并获批准 |
| 属主 | 运行 UID **10001**；旧盘若是 root 属主，由 `project-migrate` init chown 迁移 |

## 4. 环境变量

| 变量 | 要求 |
|---|---|
| `KTX_PROJECT_ROOT` | `/data/lucy` |
| `POSTHOG_DISABLED` | `1` |
| `LUCY_PUBLIC_MCP_URL` | **必填**；外部可达 Agent URL，如 `https://lucy.example.com/mcp`。空值 / `REPLACE-ME` / `127.0.0.1` 会导致 WebUI `mcpEndpoint.status=fallback`（「MCP 未就绪」）；包内 Chart 在客户 registry 路径下会 **fail 渲染** |
| `LUCY_CONTENT_ROOT` | 新装留空（默认 `/data/lucy/config`）；pre-M31 平铺布局旧盘必须设 `"."` |
| `LUCY_ALLOW_PLACEHOLDER_KTX` | 生产必须为空；仅首次 seed 可临时 `1`，注入真实配置后必须改回 |

## 5. Secret

- K8s Secret 卷永远只读，**禁止**把 Secret 直接挂载到 `/data/lucy/.ktx/secrets`（WebUI 写数据源会 `EROFS`）
- 契约做法（包内 Chart 已实现）：Secret 只读挂在 `secrets-sync` init 容器的 `/mnt/lucy-secrets`，由 `secrets-sync` 复制到 PVC `/data/lucy/.ktx/secrets/<key>`，目录 `0700`、文件 `0600`、属主 `10001:10001`（fsGroup 可能给目录加 setgid 位呈 `2700`，属正常）
- Secret 删 key 不自动清 PVC 文件；WebUI 创建的密码文件只在 PVC 上
- `ktx.yaml` 引用：`password: file:/data/lucy/.ktx/secrets/<key>`
- **禁止**把明文密码写进镜像层、Git、或可提交的 values

## 6. Probe

| Probe | 契约 |
|---|---|
| Startup / Readiness / Liveness | 一律 `httpGet /api/health`，端口 `webui`（5174） |
| 禁止 | exec 探针（`docker-healthcheck.sh`）、preflight init、把 StarRocks 连通 / reindex / MCP handshake 塞进探针 |

## 7. SecurityContext（当前镜像）

| 项 | 当前值 | 说明 |
|---|---|---|
| `runAsUser` / `runAsGroup` | **10001** | 与旧 PVC `.git` 属主兼容 |
| `fsGroup` | **10001** | |
| `runAsNonRoot` | `true` | |
| `allowPrivilegeEscalation` | `false` | 必须 |
| `capabilities.drop` | `[ALL]` | 必须 |

## 8. init 与 Git 职责（升级契约核心）

| 组件 | 职责 |
|---|---|
| 镜像入口 `docker-entrypoint.sh` | **唯一权威**：幂等 `git -C /data/lucy init` |
| `project-migrate` init | **仅 `chown`**：把 `/data/lucy` 下非 `10001:10001` 的条目交给运行用户；禁止 `git init`、禁止删文件 |
| `secrets-sync` init | 把 `/mnt/lucy-secrets` 的 Secret key 复制进 PVC `.ktx/secrets/`（只增改、不清理） |
| 已废弃 | `runtime-preflight` / `k8s-preflight` 不得复活 |

升级时禁止现场 `git init`、`chown`、`kubectl set env`、手工 Deployment patch。
升级前必须运行包内 `scripts/preflight-upgrade.sh`：live Deployment 漂移、语义层非法类型、角色 AbsoluteDeny 工具三类问题先报告、确认后再升级（该脚本打印的 JSON Patch 是唯一允许手工执行的 patch）。

## 9. 资源（示例，可按现场调）

```yaml
resources:
  requests: { cpu: 250m, memory: 512Mi }
  limits:   { cpu: "2",  memory: 2Gi }
```

## 10. 明确不在本期

多副本 HA、HPA、Operator/CRD、自动 TLS 签发、NetworkPolicy 模板、ServiceMonitor。
