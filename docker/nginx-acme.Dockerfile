# syntax=docker/dockerfile:1
#
# nginx-acme 动态模块构建 Dockerfile
# 构建 ngx_http_acme_module.so 动态模块
# 支持 Debian/Ubuntu (apt) 和 Alpine (apk) 基础镜像
#
# 构建参数:
#   BASE_IMAGE    - 基础镜像 (例如: ubuntu:24.04, debian:12, alpine:3.21)
#   NGINX_VERSION - Nginx 版本 (例如: 1.26.3, 1.27.4)
#   ACME_VERSION  - nginx-acme 版本 (例如: 0.4.1)

ARG BASE_IMAGE
ARG NGINX_VERSION
ARG ACME_VERSION

# ── 构建阶段 ──────────────────────────────────────────────────
FROM ${BASE_IMAGE} AS builder

ARG NGINX_VERSION
ARG ACME_VERSION

# 安装编译依赖（支持 apt 和 apk）
RUN set -eux; \
    if command -v apt-get > /dev/null 2>&1; then \
        apt-get update && \
        apt-get install -y --no-install-recommends \
            curl ca-certificates jq \
            clang pkg-config \
            libssl-dev libpcre2-dev zlib1g-dev \
            make && \
        rm -rf /var/lib/apt/lists/*; \
    elif command -v apk > /dev/null 2>&1; then \
        apk add --no-cache \
            curl ca-certificates jq \
            clang pkgconfig \
            openssl-dev pcre2-dev zlib-dev \
            linux-headers make; \
    else \
        echo "Unsupported base image: only Debian/Ubuntu and Alpine are supported"; \
        exit 1; \
    fi

# 下载 Nginx 源码
RUN echo "Downloading nginx-${NGINX_VERSION}..." && \
    curl -fsSL "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -o /tmp/nginx.tar.gz && \
    tar -xzf /tmp/nginx.tar.gz -C /tmp && \
    rm /tmp/nginx.tar.gz

# 下载 nginx-acme 源码
RUN echo "Downloading nginx-acme v${ACME_VERSION}..." && \
    curl -fsSL \
        "https://github.com/nginx/nginx-acme/archive/refs/tags/v${ACME_VERSION}.tar.gz" \
        -o /tmp/acme.tar.gz && \
    tar -xzf /tmp/acme.tar.gz -C /tmp && \
    rm /tmp/acme.tar.gz

# 编译动态模块
RUN echo "Building nginx-acme module..." && \
    cd "/tmp/nginx-${NGINX_VERSION}" && \
    ./configure \
        --with-compat \
        --with-http_ssl_module \
        "--add-dynamic-module=/tmp/nginx-acme-v${ACME_VERSION}" && \
    make modules && \
    ls -lh objs/ngx_http_acme_module.so

# ── 输出阶段 ──────────────────────────────────────────────────
FROM scratch AS output

ARG NGINX_VERSION

COPY --from=builder "/tmp/nginx-${NGINX_VERSION}/objs/ngx_http_acme_module.so" /