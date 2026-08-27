# Lucy K8s Integration Delivery — RELEASE_NOTES

| 字段 | 值 |
|---|---|
| 版本 | `lucy-k8s-integration-20260827-v1` |
| 日期 | 2026-08-27 |
| 镜像 | `project-lucy:customer-amd64-0.16.0`（linux/amd64） |
| KTX | `@kaelio/ktx@0.16.0` |
| 手册仓库 | https://github.com/Forrest219/lucy-customer-delivery |

## 相对 20260727-v2 的变更

- 文档与部署契约对齐正式 chart 约束：`replicas=1`、`Recreate`、Service 仅 5174/7879、严禁暴露 7878、RWO PVC `/data/lucy`。
- 明确双渠道：GitHub 仅手册；镜像大包（本 tar.gz）另渠道交付。
- 提供 `values-example.yaml`（参数示例，非可直接 helm install）。
- 提供可现场执行的 `验收命令.sh`。
- 附 `customer-config-template/` 与 `reference/helm-chart/` 只读参考快照。

## 范围

- 面向客户已有 K8s/Helm/GitOps 的集成。
- 不含可直接安装的 Lucy Helm Chart 主交付物。
- 不含 K3s 离线安装包、数据库本体、明文密钥。

## 客户动作

1. `shasum -a 256 -c SHA256SUMS`
2. 阅读 `请先阅读.md` → `集成说明.md`
3. `docker load` 镜像并按贵司方式部署
4. `bash 验收命令.sh`，把输出回传交付方
