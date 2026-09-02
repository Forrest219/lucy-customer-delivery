# Lucy Customer Delivery（手册）

本仓库**存放客户 IT 部署手册与参数示例**。镜像大包**另渠道发送**（飞书/网盘/邮件）。

## 当前版本（请用 20260902-v1）

- 版本标识：`lucy-k8s-integration-20260902-v1`
- 镜像：`project-lucy:customer-amd64-0.16.0-20260902-b262798`（linux/amd64，G4b 已校验）
- Digest：`sha256:5038c872ba54e916474d076be2eb683fbc583b9a5c858fee5da2c964d92157b4`
- Chart：`helm/lucy/` **0.2.0**（受支持安装包，随 tar.gz 交付）
- KTX：`@kaelio/ktx@0.16.0`
- 源码：`project-lucy@b262798`

### 本版相对 20260901-v1 的主要变更

- 包内含**可直接 `helm install` 的受支持 Chart**（`helm/lucy/` 0.2.0），不再是 reference 快照
- 探针改为 HTTP `GET /api/health`（废弃 exec `docker-healthcheck.sh`）
- 新增 `K8S_CONTRACT.md`、`UPGRADE.md`、`ROLLBACK.md`、`scripts/acceptance.sh`
- 镜像 tag 改为不可变格式

### 镜像大包（另渠道获取）

```text
lucy-k8s-integration-delivery-20260902-v1.tar.gz
lucy-k8s-integration-delivery-20260902-v1.tar.gz.sha256
```

出包路径（交付方内部）：`project-lucy/inbox/customer-k8s-integration-build/`

### ⛔ 勿用旧包

| 版本 | 状态 |
|---|---|
| `20260827-v1` | **作废**（arm64 ELF） |
| `20260828-v1` / `20260901-v1` | 被本版替代（Chart 0.1.x / 旧包结构） |

## 包内阅读顺序（v2 布局）

1. `README.md`
2. `K8S_CONTRACT.md`
3. `helm/lucy/UPGRADE.md`
4. `helm/lucy/ROLLBACK.md`
5. `examples/values.k3s-test.yaml`
6. 部署后 `scripts/acceptance.sh`

## 本仓库保留的中文参考

以下文件为上一版中文集成说明，字段含义仍可参考，但 **Chart 安装路径与探针模型以大包内 v2 内容为准**：

- [请先阅读.md](./请先阅读.md)
- [集成说明.md](./集成说明.md)
- [K8s部署契约.md](./K8s部署契约.md)
- [values-example.yaml](./values-example.yaml)

## 重要说明

- 面向客户已有 Kubernetes / Helm 的集成场景。
- 不含数据库密码、MCP Token 明文。
