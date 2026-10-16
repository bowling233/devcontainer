# syntax=docker/dockerfile:1

# 容器镜像代理前缀，本地构建可注入镜像站代理，例如：
#   --build-arg REGISTRY_PROXY=registry.mirrors.zjusct.io/
# https://mirrors.zju.edu.cn/container-images.md
ARG REGISTRY_PROXY=""

# https://mcr.microsoft.com/en-us/artifact/mar/devcontainers/base/about
FROM ${REGISTRY_PROXY}mcr.microsoft.com/devcontainers/base:alpine

# apk 镜像，例如：--build-arg ALPINE_MIRROR=https://mirrors.zju.edu.cn/alpine
# https://mirrors.zju.edu.cn/docs/alpine.md
ARG ALPINE_MIRROR=""

ARG TARGETARCH
ARG OPENCODE_SUFFIX
ARG CODEX_SUFFIX

RUN <<EOF
set -xe

# 构建期 apk 镜像，仅在 ALPINE_MIRROR 非空时启用，不影响 CI 直连构建
# 注意：Alpine 默认的 BusyBox sed 不支持 GNU 扩展 \?，需分别匹配 http 与 https
if [ -n "${ALPINE_MIRROR}" ]; then
    sed -i \
        -e "s#http://dl-cdn.alpinelinux.org/alpine#${ALPINE_MIRROR}#g" \
        -e "s#https://dl-cdn.alpinelinux.org/alpine#${ALPINE_MIRROR}#g" \
        /etc/apk/repositories
fi

# 与 k8s-packer 保持相同的基础/运维工具集（Alpine 对应包名），外加 K8s 工具链；
# pipx 与 python3-venv 由镜像内置的 uv（uv tool / uv venv）替代
apk add --no-cache \
    bash \
    sudo \
    ca-certificates \
    gnupg \
    curl \
    wget \
    jq \
    yq-go \
    yq-go-fish-completion \
    git \
    git-lfs \
    fish \
    python3 \
    py3-pip \
    py3-yaml \
    py3-dotenv \
    py3-jinja2 \
    build-base \
    pkgconf \
    patch \
    file \
    less \
    tree \
    zip \
    xz \
    zstd \
    rsync \
    openssh-client-default \
    procps-ng \
    psmisc \
    lsof \
    strace \
    iproute2 \
    iputils \
    bind-tools \
    netcat-openbsd \
    socat \
    mtr \
    tcpdump \
    openssl \
    gettext-envsubst \
    sqlite \
    tmux \
    vim \
    btop \
    unzip \
    uv \
    uv-fish-completion \
    shellcheck \
    shfmt \
    apache2-utils \
    ripgrep \
    nodejs \
    npm \
    docker-cli \
    docker-cli-buildx \
    kubectl \
    helm \
    kustomize \
    minio-client

echo 'set -g mouse on' > /etc/tmux.conf
EOF

# https://argo-cd.readthedocs.io/en/stable/cli_installation/
ADD --chmod=755 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-${TARGETARCH} /usr/local/bin/argocd

COPY --chmod=755 setup-mirror.sh /opt/setup-mirror.sh

# https://opencode.ai/download
ADD --unpack=true https://github.com/anomalyco/opencode/releases/latest/download/opencode-${OPENCODE_SUFFIX}.tar.gz /usr/local/bin/
RUN <<EOF
set -xe
chmod 755 /usr/local/bin/opencode
EOF

# https://developers.openai.com/codex/cli
ADD --unpack=true https://github.com/openai/codex/releases/latest/download/codex-package-${CODEX_SUFFIX}.tar.gz /usr/local/lib/codex/
RUN <<EOF
set -xe
chmod 755 \
    /usr/local/lib/codex/bin/codex \
    /usr/local/lib/codex/bin/codex-code-mode-host \
    /usr/local/lib/codex/codex-path/rg \
    /usr/local/lib/codex/codex-resources/bwrap
test -x /usr/local/lib/codex/bin/codex
test -x /usr/local/lib/codex/bin/codex-code-mode-host

# Keep the upstream package root intact: Codex's app-server installer hashes
# the complete tree containing codex-package.json.
ln -s ../lib/codex/bin/codex-code-mode-host /usr/local/bin/codex-code-mode-host
# 自带的 rg 为 glibc 动态链接，在 musl 上无法执行；改用 apk 安装的 ripgrep。
# 该符号链接位于包目录之外，不影响上述哈希校验
ln -sf /usr/bin/rg /usr/local/codex-path
ln -s ../lib/codex/codex-resources /usr/local/codex-resources
ln -s ../lib/codex/bin/codex /usr/local/bin/codex
/usr/local/codex-path --version
EOF

# https://x.ai/cli
RUN <<EOF
set -xe
case "${TARGETARCH}" in
    amd64) GROK_ARCH=x86_64 ;;
    arm64) GROK_ARCH=aarch64 ;;
    *) exit 1 ;;
esac
GROK_VERSION=$(curl -fsSL https://x.ai/cli/stable)
curl -fsSL \
    "https://x.ai/cli/grok-${GROK_VERSION}-linux-${GROK_ARCH}" \
    -o /usr/local/bin/grok
chmod 755 /usr/local/bin/grok
grok --version
EOF

# https://claude.ai/install.sh
# 注意：官方默认二进制为 glibc 动态链接，在 Alpine（musl）上需使用 -musl 变体
RUN <<EOF
set -xe
case "${TARGETARCH}" in
    amd64) CLAUDE_PLATFORM=linux-x64-musl ;;
    arm64) CLAUDE_PLATFORM=linux-arm64-musl ;;
    *) exit 1 ;;
esac
CLAUDE_VERSION=$(curl -fsSL https://downloads.claude.ai/claude-code-releases/latest)
curl -fsSL \
    "https://downloads.claude.ai/claude-code-releases/${CLAUDE_VERSION}/${CLAUDE_PLATFORM}/claude" \
    -o /usr/local/bin/claude
chmod 755 /usr/local/bin/claude
claude --version
EOF

USER vscode
