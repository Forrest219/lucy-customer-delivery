# Lucy K8s Integration Delivery — RELEASE_NOTES

| 字段 | 值 |
|---|---|
| 版本 | `lucy-k8s-integration-20260827-v2` |
| 日期 | 2026-08-27 |
| 镜像 | `project-lucy:customer-amd64-0.16.0`（linux/amd64，ELF 已校验为 x86-64） |
| 镜像 digest | 见 `image/image-digest.txt` |
| KTX | `@kaelio/ktx@0.16.0` |
| 手册仓库 | https://github.com/Forrest219/lucy-customer-delivery |

## 紧急：请用本版替换 v1

`lucy-k8s-integration-20260827-v1` **已作废**。该包镜像元数据标 amd64，但层内 `tini`/`node` 实为 aarch64，在客户 x86_64 上会报：

```text
exec /usr/bin/tini: exec format error
```

v2 已在交付侧重跑 G1–G4（元数据 + ELF node/tini + `docker run` + ktx 版本）后再打包。

## 客户动作

```bash
shasum -a 256 -c lucy-k8s-integration-delivery-20260827-v2.tar.gz.sha256
tar -xzf lucy-k8s-integration-delivery-20260827-v2.tar.gz
cd lucy-k8s-integration-delivery-20260827-v2
# 先阅读「请先阅读.md」
nerdctl load -i image/project-lucy-customer-amd64-0.16.0-image.tar   # 或 docker load
nerdctl run --rm project-lucy:customer-amd64-0.16.0 /bin/sh -c 'echo ok'
```
