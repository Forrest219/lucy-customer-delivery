# Release Notes — lucy-k8s-integration-20260828-v1

## 摘要

客户 amd64 镜像重建 + 内网可用硬门禁，修复现场「装完不能用」两类问题：

1. 查询触发 `ktx could not download uv`（KTX Python runtime 未预装）
2. WebUI「Lucy MCP 未就绪」（`LUCY_PUBLIC_MCP_URL` 未配置 → `mcpEndpoint.status=fallback`）

## 镜像

| 项 | 值 |
|---|---|
| Tag | `project-lucy:customer-amd64-0.16.0` |
| Platform | `linux/amd64` |
| KTX | `@kaelio/ktx@0.16.0` |
| Runtime | Dockerfile `ktx admin runtime install --yes --feature core` bake-in |
| 门禁 | G1–G4 + **G4b**（runtime 文件 + `--network=none`）当场通过 |

## Chart / 验收

- 参考 Helm chart：当 `image.repository != project-lucy` 时，空 / `REPLACE-ME` / `127.0.0.1` 的 `LUCY_PUBLIC_MCP_URL` **渲染失败**。
- `验收命令.sh` 新增：Pod/镜像 runtime 检查、`/api/project` → `mcpEndpoint.status=configured`。

## 作废

- `lucy-k8s-integration-20260827-v1`（arm64 ELF）及任何未过 G4b 的历史 tar：**禁止继续交付或现场复用**。

## 升级注意

- 单副本 `Recreate`，短中断；PVC 保留。
- 必须显式设置外部可达 `LUCY_PUBLIC_MCP_URL` 后再 `helm upgrade`。
