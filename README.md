# Lucy Customer Delivery

本仓库用于向客户交付 Lucy 部署材料。

## 当前交付版本

- Release：`lucy-k8s-integration-20260727-v2`
- 适用场景：客户已有 Kubernetes / Helm 部署体系
- CPU 架构：`linux/amd64`

## 下载方式

请进入本仓库 Releases 页面，下载同一版本下的两个附件：

1. `lucy-k8s-integration-delivery-20260727-v2.tar.gz`
2. `lucy-k8s-integration-delivery-20260727-v2.tar.gz.sha256`

两个文件必须放在同一目录。

## 校验和解压

```bash
shasum -a 256 -c lucy-k8s-integration-delivery-20260727-v2.tar.gz.sha256
tar -xzf lucy-k8s-integration-delivery-20260727-v2.tar.gz
```

校验通过后进入解压目录，先阅读 `请先阅读.md`。

## 重要说明

- 本包用于客户已有 K8s/Helm 体系集成，不是 K3s 离线安装包。
- 本包不包含可直接安装的 Helm Chart，客户继续使用自己的 Chart 或 GitOps 流水线。
- `values-example.yaml` 是参数示例，不是可直接 `helm install` 的 values。
- 数据源类型、`connectionId`、表范围和 `customer-config`，以交付方针对本客户提供的版本为准。
- 数据库密码和 MCP Token 不在包内，请按客户 Secret / 密码库规范配置。
- 部署完成后，请根据现场 `namespace`、`deployment`、`connectionId`、`source`、URL 等参数运行 `验收命令.sh`，并将输出结果回传给交付方确认。
