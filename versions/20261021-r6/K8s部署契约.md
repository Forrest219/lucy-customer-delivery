# r6 Kubernetes 部署契约

当前为升级验证候选；实际元数据为 Lucy 2.0.0 / KTX 0.16.0 / Chart 0.2.6。包内历史兼容矩阵如仍把 0.2.5 标成 Current，不据此改动包身份；以 `BUILD-INFO.json` 和 `helm/lucy/Chart.yaml` 为准。

| 项目 | 要求 |
|---|---|
| 平台 | linux/amd64，已验证 node/tini ELF；运行时依赖离线预装 |
| 拓扑 | 单实例、单副本、Recreate，不支持多副本共享可写配置 |
| PVC | RWO，挂载 /data/lucy，升级保留 UID、名称和管理方式 |
| 内容布局 | 保留原 content root；旧平铺布局不得被新装默认值覆盖 |
| 运行身份 | UID/GID 10001，旧盘属主迁移由既有受支持 init 负责 |
| Git | 镜像入口幂等初始化；不要求部署人员手工 git init/chown |
| 探针 | HTTP /api/health，使用容器 WebUI 端口 |
| WebUI / MCP | 容器端口 5174 / 7879；外部端口按原 Service 保留 |
| KTX 上游 | 7878 只在 Pod 内使用，不进入 Service/Ingress |
| 数据库 Secret | 保留原 Secret 引用与 secrets-sync 方式；不把密码写进 Git/values |
| 首次所有者 Secret | bootstrap.existingSecret；token 挂载到 /run/secrets/lucy-bootstrap/token |
| 首次所有者环境变量 | LUCY_WEBUI_BOOTSTRAP_TOKEN_FILE 指向上面的受限文件 |
| 访问方式 | security.access 为 http 或 https，与现场两个访问 URL 一致 |
| 镜像身份 | offline 的 image.digest 留空；config ID、平台 manifest、包 SHA256 分开核对 |

同实例重出包/升级/重试复用原密钥，另一实例由供应方另行签发；已有管理员不重新认领。引导 Secret 与数据库 Secret 是不同配置项。

不得通过删 PVC、重装第二套 release、现场 patch 或更改实例 ID 来绕过检查。尤其不能为了升级强设 `persistence.existingClaim`，导致原由 Helm 管理的 PVC 从渲染资源中消失。
