#!/usr/bin/env bash
# 用于 Devcontainer postStartCommand 在容器启动后设置镜像的脚本
# 镜像不应在 Dockerfile 中设置，以免影响 GitHub Action 构建
# Dockerfile 末尾也不行，因为 devcontainer.json 中的 feature 将在其后继续构建

set -euo pipefail

MIRROR="${MIRROR:-mirrors.cernet.edu.cn}"
ALPINE_MIRROR="https://${MIRROR}/alpine"
PYPI_MIRROR="https://${MIRROR}/pypi/web/simple"
NPM_REGISTRY="https://registry.npmmirror.com/"

# shellcheck disable=SC1091
. /etc/os-release

if [ "${ID:-}" != "alpine" ]; then
    echo "setup-mirror.sh only supports Alpine-based devcontainer images" >&2
    exit 1
fi

# Alpine 默认的 BusyBox sed 不支持 GNU 扩展 \?，需分别匹配 http 与 https
sed -i \
    -e "s#http://dl-cdn.alpinelinux.org/alpine#${ALPINE_MIRROR}#g" \
    -e "s#https://dl-cdn.alpinelinux.org/alpine#${ALPINE_MIRROR}#g" \
    /etc/apk/repositories

cat >/etc/pip.conf <<EOF
[global]
index-url = ${PYPI_MIRROR}
EOF

install -d -m 0755 /etc/uv
cat >/etc/uv/uv.toml <<EOF
[[index]]
url = "${PYPI_MIRROR}/"
default = true
EOF

cat >/etc/npmrc <<EOF
registry=${NPM_REGISTRY}
EOF

# 环境变量型镜像注入到各 Shell 配置文件中
# 使用 profile.d / conf.d 落盘文件而非追加，保证脚本可重复执行

install -d -m 0755 /etc/profile.d
cat >/etc/profile.d/goproxy.sh <<EOF
export GO111MODULE=on
export GOPROXY=https://goproxy.cn
EOF

install -d -m 0755 /etc/fish/conf.d
cat >/etc/fish/conf.d/goproxy.fish <<EOF
set -gx GO111MODULE on
set -gx GOPROXY https://goproxy.cn
EOF
