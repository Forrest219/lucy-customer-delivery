# Lucy Customer Delivery（手册）

本仓库**只存放客户 IT 部署手册与参数示例**。镜像大包（`*.tar.gz`）由交付方**另渠道**发送。

## 当前版本

- 手册版本：`lucy-k8s-integration-20260827-v1`
- 镜像 tag：`project-lucy:customer-amd64-0.16.0`（linux/amd64）
- KTX：`@kaelio/ktx@0.16.0`

## 阅读顺序

1. [请先阅读.md](./请先阅读.md)
2. [集成说明.md](./集成说明.md)
3. [K8s部署契约.md](./K8s部署契约.md)
4. [values-example.yaml](./values-example.yaml)（参数示例，不能直接 helm install）
5. 部署后执行 [验收命令.sh](./验收命令.sh)

## 重要说明

- 面向客户已有 Kubernetes / Helm / GitOps 的集成场景。
- **不包含**可直接安装的 Lucy Helm Chart；请继续使用贵司自己的 Chart。
- **不包含** K3s 一键安装包、数据库密码、MCP Token 明文。
- 拿到另送的 tar.gz 后：先 `shasum -a 256 -c` 包内 `SHA256SUMS`，再 `docker load` 镜像，按手册部署。

## 变更

见 [RELEASE_NOTES.md](./RELEASE_NOTES.md)。
