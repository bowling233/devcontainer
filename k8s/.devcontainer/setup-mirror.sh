#!/usr/bin/env bash
# 用于 Devcontainer postStartCommand 在容器启动后设置镜像的脚本
# 镜像不应在 Dockerfile 中设置，以免影响 GitHub Action 构建
# Dockerfile 末尾也不行，因为 devcontainer.json 中的 feature 将在其后继续构建

set -euo pipefail

MIRROR="${MIRROR:-mirrors.cernet.edu.cn}"
DEBIAN_MIRROR="https://${MIRROR}"
DOCKER_MIRROR="https://${MIRROR}/docker-ce/linux/debian"
PYPI_MIRROR="https://${MIRROR}/pypi/web/simple"
NPM_REGISTRY="https://registry.npmmirror.com/"

# shellcheck disable=SC1091
. /etc/os-release

if [ "${ID:-}" != "debian" ]; then
    echo "setup-mirror.sh only supports Debian-based devcontainer images" >&2
    exit 1
fi

find /etc/apt -type f \( -name '*.list' -o -name '*.sources' \) \
    -exec sed -i \
        -e "s|https\?://deb.debian.org|${DEBIAN_MIRROR}|g" \
        -e "s|https\?://security.debian.org|${DEBIAN_MIRROR}|g" \
        -e "s|https\?://download.docker.com/linux/debian|${DOCKER_MIRROR}|g" \
        {} +

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

cat <<EOF | tee -a /etc/profile /etc/fish/config.fish /etc/zsh/zshrc
export GO111MODULE=on
export GOPROXY=https://goproxy.cn
EOF
