# Release Notes — lucy-k8s-integration-20260902-v1

## 摘要

v2 交付包布局：受支持 Helm Chart 0.2.0 与镜像同包交付；升级/回滚文档与验收脚本纳入包内。

## 镜像

| 项 | 值 |
|---|---|
| Tag | `project-lucy:customer-amd64-0.16.0-20260902-b262798` |
| Digest | `sha256:5038c872ba54e916474d076be2eb683fbc583b9a5c858fee5da2c964d92157b4` |
| Platform | `linux/amd64` |
| KTX | `@kaelio/ktx@0.16.0` |
| 源码 | `project-lucy@b262798` |

## Chart 0.2.0

- HTTP 探针（`/api/health`），废弃 exec `docker-healthcheck.sh`
- `containerPorts` 与 `service` 端口分离
- 可选 `image.digest` 固定
- `UPGRADE.md` / `ROLLBACK.md`

## 相对 20260901-v1

- Helm Chart 从 reference 升级为 supported delivery artifact
- 平滑升级保留账号与审计日志
- StarRocks 连接兼容补丁
- RoleDetail CheckboxCandidatePicker 修复

## 作废

- `20260901-v1` 及更早（Chart 0.1.x / 旧中文-only 包结构）— 请换用本版

## 升级注意

- 单副本 `Recreate`；PVC 保留
- 必填 `LUCY_PUBLIC_MCP_URL`（外部可达）
- 详见包内 `helm/lucy/UPGRADE.md`
