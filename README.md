# Skopeo Copy Image

本项目利用 GitHub Actions 和 `skopeo` 工具，实现 Docker 镜像在不同镜像仓库之间的快速同步与复制。支持多架构镜像同步及多目标地址推送。

## 配置说明

在使用此流水线之前，必须在 GitHub 项目的 **Settings > Secrets and variables > Actions** 中配置以下 Secrets：

### 1. DOCKER_CONFIG_BASE64 (必填)

用于镜像仓库的登录认证。该值是 Docker 配置文件 `~/.docker/config.json` 的 Base64 编码字符串。

**获取方法：**

在本地终端执行以下命令（请确保已先执行 `docker login` 登录了相关仓库）：

```bash
# Linux / macOS
cat ~/.docker/config.json | base64 -w 0

# 如果没有 base64 命令，可以使用 python
cat ~/.docker/config.json | python3 -c "import base64,sys; print(base64.b64encode(sys.stdin.read().encode()).decode())"
```

复制输出的字符串，并将其作为 `DOCKER_CONFIG_BASE64` 的值保存到 GitHub Secrets 中。

## 使用方法

手动触发 GitHub Actions 流水线：

1. 进入项目的 **Actions** 选项卡。
2. 选择左侧的 **Copy Image** 工作流。
3. 点击 **Run workflow** 下拉按钮。
4. 填写以下参数：

| 参数名称 | 说明 | 示例 |
| :--- | :--- | :--- |
| **SRC_IMAGE** | 源镜像地址（包含仓库地址） | `docker.io/library/alpine:latest` |
| **DST_IMAGE** | 目标镜像地址。如有多个目标，使用英文逗号 `,` 分隔。 | `ghcr.io/username/alpine:latest,myreg.com/alpine:latest` |

5. 点击 **Run workflow** 开始同步。

## 功能特性

- **全平台同步**：使用 `skopeo copy --all`，确保源镜像的所有架构（amd64, arm64 等）都被同步到目标仓库。
- **多目标支持**：一次运行可将镜像推送到多个不同的镜像仓库。
- **自动安装 Skopeo**：流水线会自动从 [jetsung/install-skopeo](https://github.com/jetsung/install-skopeo) 获取并安装最新的 Skopeo。

## 许可证

[Apache License 2.0](LICENSE)
