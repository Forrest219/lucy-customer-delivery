# Lucy Customer Delivery（手册）

本仓库**存放客户 IT 部署手册与参数示例**。镜像大包见 GitHub Releases。

## 当前版本（请用 20260828-v1）

- Release：[`lucy-k8s-integration-20260828-v1`](https://github.com/Forrest219/lucy-customer-delivery/releases/tag/lucy-k8s-integration-20260828-v1)
- 镜像：`project-lucy:customer-amd64-0.16.0`（linux/amd64，**ELF x86-64 + KTX Python runtime G4b 已校验**）
- KTX：`@kaelio/ktx@0.16.0`

### 本版相对 v3 的关键修复

1. 镜像预装 KTX Python/uv runtime（内网不再尝试下载 `uv`）
2. 强制配置外部可达 `LUCY_PUBLIC_MCP_URL`（避免 WebUI「MCP 未就绪」）
3. `验收命令.sh` 增加 runtime 离线检查与 `mcpEndpoint.status=configured` 断言

### ⛔ 勿用旧包

| Release | 状态 |
|---|---|
| [`lucy-k8s-integration-20260827-v1`](https://github.com/Forrest219/lucy-customer-delivery/releases/tag/lucy-k8s-integration-20260827-v1) | **作废**（arm64 ELF → `exec format error`） |
| [`lucy-k8s-integration-20260827-v2`](https://github.com/Forrest219/lucy-customer-delivery/releases/tag/lucy-k8s-integration-20260827-v2) / [`v3`](https://github.com/Forrest219/lucy-customer-delivery/releases/tag/lucy-k8s-integration-20260827-v3) | 被本版替代（缺 G4b runtime 预装时，内网查询可能失败） |

## 下载

```text
https://github.com/Forrest219/lucy-customer-delivery/releases/download/lucy-k8s-integration-20260828-v1/lucy-k8s-integration-delivery-20260828-v1.tar.gz
https://github.com/Forrest219/lucy-customer-delivery/releases/download/lucy-k8s-integration-20260828-v1/lucy-k8s-integration-delivery-20260828-v1.tar.gz.sha256
```

## 阅读顺序

1. [请先阅读.md](./请先阅读.md)
2. [集成说明.md](./集成说明.md)
3. [K8s部署契约.md](./K8s部署契约.md)
4. [values-example.yaml](./values-example.yaml)
5. 部署后执行 [验收命令.sh](./验收命令.sh)

## 重要说明

- 面向客户已有 Kubernetes / Helm / GitOps 的集成场景。
- **不包含**可直接安装的 Lucy Helm Chart。
- 不含数据库密码、MCP Token 明文。
