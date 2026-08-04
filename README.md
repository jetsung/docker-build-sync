# Docker Image Build & Sync

本项目利用 GitHub Actions 实现 Docker 镜像的构建与跨仓库同步:通过 `docker buildx` 构建多平台镜像并推送至 GHCR,通过 `skopeo` 将镜像快速同步、复制到不同镜像仓库。

包含两个工作流:

- **Docker Build** ([build-image.yml](.github/workflows/build-image.yml)):根据 Dockerfile 构建多架构镜像并推送至 GHCR。
- **Sync Images** ([sync-images.yml](.github/workflows/sync-images.yml)):使用 `skopeo copy --all` 将镜像同步到多个目标仓库。

## 配置说明

在使用此流水线之前，必须在 GitHub 项目的 **Settings > Secrets and variables > Actions** 中配置以下 Secrets：

### 1. DOCKER_CONFIG_BASE64 (Sync Images 工作流必填)

用于镜像仓库的登录认证。该值是 Docker 配置文件 `config.json` 的 Base64 编码字符串。

**获取方法：**

在本地终端执行以下命令（请确保已先执行 `docker login` 登录了相关仓库）：

> **注意**：`docker login` 实际写入的配置文件路径取决于执行登录命令所使用的用户。普通用户默认保存在 `~/.docker/config.json`（`~` 对应该用户的家目录）；若使用 `root` 用户登录，则通常保存在 `/root/.docker/config.json`，而非 `~/.docker/config.json`（非 root 用户的家目录下）。请确认登录时所用的用户，并取对应用户家目录下的 `config.json` 文件进行编码。

```bash
# Linux / macOS（以实际登录用户对应的路径为准，例如普通用户）
cat ~/.docker/config.json | base64 -w 0

# 若使用 root 用户登录，则路径通常为
cat /root/.docker/config.json | base64 -w 0

# 如果没有 base64 命令，可以使用 python（同样注意替换为正确的路径）
cat ~/.docker/config.json | python3 -c "import base64,sys; print(base64.b64encode(sys.stdin.read().encode()).decode())"
```

![](screenshot/sync-images-1.png)

复制输出的字符串，并将其作为 `DOCKER_CONFIG_BASE64` 的值保存到 GitHub Secrets 中。

![](screenshot/sync-images-2.png)

### 2. GITHUB_TOKEN (Docker Build 工作流)

Docker Build 工作流使用 GitHub 自动提供的 `GITHUB_TOKEN` 登录 GHCR，无需额外配置。

## 使用方法

### Docker Build（构建并推送镜像）

> **注意**：若该镜像包（package）此前已由其它仓库的构建流水线构建并关联了仓库源，推送到 GHCR 时可能会失败。此时需进入该包所在项目的 **Package settings**（包设置），删除其 **Repository source**（仓库源），解除与其它仓库的关联后再重新构建。

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

![](screenshot/docker-build.png)

### Sync Images（同步镜像）

> **注意**：`DST_IMAGE` 中每个目标镜像的注册中心（即地址中的域名或仓库前缀部分，例如 `ghcr.io`、`myreg.com`）必须已在 **DOCKER_CONFIG_BASE64** 配置文件中预先登录并配置好对应的账号及密码。若未在该 Docker 配置文件（登录用户家目录下的 `config.json`，例如普通用户为 `~/.docker/config.json`、root 用户为 `/root/.docker/config.json`）中配置相应注册中心的认证信息，同步到该目标仓库时将会因认证失败而报错。请在执行同步前，确保已对 `DST_IMAGE` 涉及的所有注册中心执行过 `docker login`（使用正确的用户）并重新生成 `DOCKER_CONFIG_BASE64` 保存到 GitHub Secrets 中。

1. 进入项目的 **Actions** 选项卡。
2. 选择左侧的 **Sync Images** 工作流。
3. 点击 **Run workflow** 下拉按钮。
4. 填写以下参数：

| 参数名称 | 说明 | 示例 |
| :--- | :--- | :--- |
| **SRC_IMAGE** | 源镜像地址（包含仓库地址） | `docker.io/library/alpine:latest` |
| **DST_IMAGE** | 目标镜像地址。如有多个目标，使用英文逗号 `,` 分隔。 | `ghcr.io/username/alpine:latest,myreg.com/alpine:latest` |

5. 点击 **Run workflow** 开始同步。

![](screenshot/sync-images.png)

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
