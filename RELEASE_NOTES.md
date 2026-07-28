# Lucy K8s Integration Delivery 20260727 v2

本 Release 提供 Lucy K8s 集成交付材料，面向客户已有 K8s/Helm 体系。

## Assets

- `lucy-k8s-integration-delivery-20260727-v2.tar.gz`
- `lucy-k8s-integration-delivery-20260727-v2.tar.gz.sha256`

## Usage

```bash
shasum -a 256 -c lucy-k8s-integration-delivery-20260727-v2.tar.gz.sha256
tar -xzf lucy-k8s-integration-delivery-20260727-v2.tar.gz
```

解压后先阅读 `请先阅读.md`。

## Scope

- 包含 Lucy 镜像归档、中文集成说明、K8s 部署契约、示例参数、验收脚本、digest 和 SHA256 校验清单。
- 不包含 K3s 离线安装包。
- 不包含可直接安装的 Lucy Helm Chart。
- 不包含数据库密码或 MCP Token 明文。
