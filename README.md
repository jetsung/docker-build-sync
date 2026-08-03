# Docker Image Build & Sync

本项目利用 GitHub Actions 实现 Docker 镜像的构建与跨仓库同步:通过 `docker buildx` 构建多平台镜像并推送至 GHCR,通过 `skopeo` 将镜像快速同步、复制到不同镜像仓库。

包含两个工作流:

- **Docker Build** ([build-image.yml](.github/workflows/build-image.yml)):根据 Dockerfile 构建多架构镜像并推送至 GHCR。
- **Copy Image** ([sync-image.yml](.github/workflows/sync-image.yml)):使用 `skopeo copy --all` 将镜像同步到多个目标仓库。

## 配置说明

在使用此流水线之前，必须在 GitHub 项目的 **Settings > Secrets and variables > Actions** 中配置以下 Secrets：

### 1. DOCKER_CONFIG_BASE64 (Copy Image 工作流必填)

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

### 2. GITHUB_TOKEN (Docker Build 工作流)

Docker Build 工作流使用 GitHub 自动提供的 `GITHUB_TOKEN` 登录 GHCR，无需额外配置。首次推送前请确认 **Settings > Packages** 中的写入权限（工作流已声明 `packages: write`）。

## 使用方法

### Docker Build（构建并推送镜像）

1. 进入项目的 **Actions** 选项卡。
2. 选择左侧的 **Docker Build** 工作流。
3. 点击 **Run workflow** 下拉按钮。
4. 填写以下参数：

| 参数名称 | 说明 | 示例 |
| :--- | :--- | :--- |
| **dockerfile_url** | Dockerfile 下载地址（必填） | `https://example.com/Dockerfile` |
| **image_name** | 镜像名称及标签（必填） | `my-app:latest` |
| **platforms** | 构建平台，逗号分隔（可选） | `linux/amd64,linux/arm64` |
| **build_script_url** | 前置构建 bash 脚本 URL（可选） | `https://example.com/build.sh` |

5. 点击 **Run workflow** 开始构建。

### Copy Image（同步镜像）

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

- **多架构构建**：使用 `docker buildx` 构建 `linux/amd64`、`linux/arm64` 等多平台镜像并推送至 GHCR。
- **全平台同步**：使用 `skopeo copy --all`，确保源镜像的所有架构（amd64, arm64 等）都被同步到目标仓库。
- **多目标支持**：一次运行可将镜像推送到多个不同的镜像仓库。
- **可选构建脚本**：支持下载并执行自定义 bash 构建脚本，灵活扩展构建流程。
- **自动安装 Skopeo**：流水线会自动从 [jetsung/install-skopeo](https://github.com/jetsung/install-skopeo) 获取并安装最新的 Skopeo。

## 许可证

[Apache License 2.0](LICENSE)

## 仓库镜像

[MyCode](https://git.jetsung.com/jetsung/docker-build-sync) ● [AtomGit](https://atomgit.com/jetsung/docker-build-sync) ● [GitHub](https://github.com/jetsung/docker-build-sync)

