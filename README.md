# Lucy Customer Delivery（手册）

本仓库**存放客户 IT 部署手册与参数示例**。镜像大包见 GitHub Releases。

## 当前版本（请用 v3）

- Release：[`lucy-k8s-integration-20260827-v3`](https://github.com/Forrest219/lucy-customer-delivery/releases/tag/lucy-k8s-integration-20260827-v3)
- 镜像：`project-lucy:customer-amd64-0.16.0-v3`（linux/amd64，**ELF x86-64 已校验**）
- KTX：`@kaelio/ktx@0.16.0`

### ⛔ 勿用 v1

[`lucy-k8s-integration-20260827-v1`](https://github.com/Forrest219/lucy-customer-delivery/releases/tag/lucy-k8s-integration-20260827-v1) 已作废（镜像层内为 arm64 ELF，x86 节点会 `exec format error`）。

### 说明：相对 v2

v3 为架构修复后的再清洁构建（清理镜像内历史配置残留），镜像 tag 带 `-v3`。请用本版替换此前所有包。

## 下载

```text
https://github.com/Forrest219/lucy-customer-delivery/releases/download/lucy-k8s-integration-20260827-v3/lucy-k8s-integration-delivery-20260827-v3.tar.gz
https://github.com/Forrest219/lucy-customer-delivery/releases/download/lucy-k8s-integration-20260827-v3/lucy-k8s-integration-delivery-20260827-v3.tar.gz.sha256
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
