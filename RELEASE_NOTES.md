# Lucy K8s Integration Delivery — RELEASE_NOTES

| 字段 | 值 |
|---|---|
| 版本 | `lucy-k8s-integration-20260827-v3` |
| 日期 | 2026-08-27 |
| 镜像 | `project-lucy:customer-amd64-0.16.0-v3`（linux/amd64，ELF 已校验为 x86-64） |
| 镜像 ID | 见 `image/image-digest.txt` |
| KTX | `@kaelio/ktx@0.16.0` |
| 手册仓库 | https://github.com/Forrest219/lucy-customer-delivery |

## 紧急：请用本版替换 v1

`lucy-k8s-integration-20260827-v1` **已作废**。该包镜像元数据标 amd64，但层内 `tini`/`node` 实为 aarch64，在客户 x86_64 上会报：

```text
exec /usr/bin/tini: exec format error
```

v3 已在交付侧重跑 G1–G4（元数据 + 容器内 node/tini/ktx 可执行性 + `docker run` + ktx 版本）后再打包。

## v3 修复

- 基于 amd64 镜像重新生成。
- 清理镜像内历史 `customer-config`、本地开发配置、运行状态库、导出包和密钥目录。
- 镜像仅保留 Lucy 运行时与安全示例模板；客户现有配置继续通过 PVC `/data/lucy` 使用。
- 升级场景下如果 `/data/lucy/ktx.yaml` 已存在，入口脚本会跳过模板同步，避免覆盖客户现有 `semantic-layer`、`wiki` 和 `skills`。

## 客户动作

```bash
shasum -a 256 -c lucy-k8s-integration-delivery-20260827-v3.tar.gz.sha256
tar -xzf lucy-k8s-integration-delivery-20260827-v3.tar.gz
cd lucy-k8s-integration-delivery-20260827-v3
# 先阅读「请先阅读.md」
nerdctl load -i image/project-lucy-customer-amd64-0.16.0-v3-image.tar   # 或 docker load
nerdctl run --rm --platform linux/amd64 --entrypoint /bin/sh project-lucy:customer-amd64-0.16.0-v3 -c 'echo ok'
```

若需单独校验镜像 tar，在包根目录执行：

```bash
shasum -a 256 -c image/project-lucy-customer-amd64-0.16.0-v3-image.tar.sha256
```
