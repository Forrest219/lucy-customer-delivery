# Lucy K8s 部署契约（20260827-v1）

客户平台工程接入 Lucy 时必须遵守以下硬约束。与参考 chart `reference/helm-chart/` 一致。

## 1. 工作负载

| 项 | 契约 |
|---|---|
| `replicas` | **必须为 1**（本期不支持多副本 HA） |
| `strategy.type` | **Recreate**（RWO PVC 不可双挂） |
| 容器镜像平台 | `linux/amd64` |
| Bundled KTX | `@kaelio/ktx@0.16.0` |

## 2. 端口

| 端口 | 用途 | 是否进 Service / Ingress |
|---|---|---|
| `5174/tcp` | WebUI / API / `/api/health` | 是 |
| `7879/tcp` | Lucy MCP Proxy（Agent 入口） | 是 |
| `7878/tcp` | KTX MCP upstream（Pod 内 `127.0.0.1`） | **否。严禁暴露** |

## 3. 持久化

| 项 | 契约 |
|---|---|
| 挂载点 | `/data/lucy` |
| accessModes | `ReadWriteOnce` |
| 内容 | `ktx.yaml`、semantic-layer、wiki、evals、skills、access.yaml、`.ktx/`、`.ktx-ui/` |
| 卸载 | 删除 Deployment/Service **不**自动等于删数据；删 PVC 前必须备份 |

## 4. 环境变量

| 变量 | 要求 |
|---|---|
| `KTX_PROJECT_ROOT` | `/data/lucy` |
| `POSTHOG_DISABLED` | `1` |
| `LUCY_PUBLIC_MCP_URL` | **必填**；外部可达 Agent URL，如 `https://lucy.example.com/mcp` |
| `LUCY_ALLOW_PLACEHOLDER_KTX` | 生产必须为空；仅首次 seed 可临时 `1` |

## 5. Secret

- 推荐：K8s Secret（或贵司 SealedSecret / ExternalSecret）挂载到 `/data/lucy/.ktx/secrets/<key>`
- `ktx.yaml` 引用：`password: file:/data/lucy/.ktx/secrets/<key>`
- **禁止**把明文密码写进镜像层、Git、或可提交的 values

## 6. Probe

| Probe | 建议 |
|---|---|
| Startup | `exec /app/scripts/docker-healthcheck.sh`，`failureThreshold ≥ 60` |
| Readiness | 同上 healthcheck |
| Liveness | `httpGet /api/health`，port `5174`（或 named port `webui`） |

## 7. SecurityContext（当前镜像）

| 项 | 当前值 | 说明 |
|---|---|---|
| `runAsUser` | `0` | 当前 entrypoint 需要；若集群 PSA=`restricted` 需与交付方协商 |
| `allowPrivilegeEscalation` | `false` | 必须 |
| `capabilities.drop` | `[ALL]` | 必须 |

## 8. 资源（示例，可按现场调）

```yaml
resources:
  requests: { cpu: 250m, memory: 512Mi }
  limits:   { cpu: "2",  memory: 2Gi }
```

## 9. 明确不在本期

多副本 HA、HPA、Operator/CRD、自动 TLS 签发、NetworkPolicy 模板、ServiceMonitor。
