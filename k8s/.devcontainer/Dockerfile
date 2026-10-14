# syntax=docker/dockerfile:1

# https://mcr.microsoft.com/en-us/artifact/mar/devcontainers/base/about
FROM mcr.microsoft.com/devcontainers/base:trixie

ARG TARGETARCH
ARG OPENCODE_SUFFIX
ARG CODEX_SUFFIX
ARG ZELLIJ_SUFFIX
ENV DEBIAN_FRONTEND=noninteractive

RUN <<EOF
set -xe

apt-get update
apt-get install -y --no-install-recommends \
    ca-certificates \
    gnupg \
    curl \
    wget \
    jq \
    yq \
    git \
    git-lfs \
    fish \
    python-is-python3 \
    python3-venv \
    python3-yaml \
    python3-dotenv \
    python3-pip \
    python3-jinja2 \
    python3 \
    pipx \
    build-essential \
    pkg-config \
    patch \
    file \
    less \
    tree \
    zip \
    xz-utils \
    zstd \
    rsync \
    openssh-client \
    procps \
    psmisc \
    lsof \
    strace \
    iproute2 \
    iputils-ping \
    dnsutils \
    netcat-openbsd \
    socat \
    mtr-tiny \
    tcpdump \
    openssl \
    gettext-base \
    sqlite3 \
    tmux \
    vim \
    btop \
    pre-commit \
    minio-client \
    unzip \
    shellcheck \
    shfmt \
    apache2-utils \
    ripgrep \
    chromium \
    nodejs \
    npm
apt-get autoremove -y
apt-get distclean
echo 'set -g mouse on' > /etc/tmux.conf
EOF

RUN <<EOF
set -xe
. /etc/os-release

# https://www.hashicorp.com/en/official-packaging-guide
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
chmod 644 /usr/share/keyrings/hashicorp-archive-keyring.gpg
cat <<EOT | tee /etc/apt/sources.list.d/hashicorp.list
deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${VERSION_CODENAME} main
EOT

apt-get update
apt-get install -y --no-install-recommends \
    packer \
    qemu-system-x86 \
    ovmf \
    qemu-system-arm \
    qemu-efi-aarch64 \
    qemu-system-riscv \
    qemu-efi-riscv64 \
    qemu-utils \
    cloud-init \
    cloud-image-utils
apt-get autoremove -y
apt-get distclean
packer plugins install github.com/hashicorp/qemu
EOF

# https://argo-cd.readthedocs.io/en/stable/cli_installation/
ADD --chmod=755 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-${TARGETARCH} /usr/local/bin/argocd

# https://kubevirt.io/user-guide/user_workloads/virtctl_client_tool/
RUN <<EOF
set -xe
export VERSION=$(curl https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
curl -fsSL -o /usr/local/bin/virtctl "https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-linux-${TARGETARCH}"
chmod +x /usr/local/bin/virtctl
EOF

# https://docs.astral.sh/uv/guides/integration/docker/
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

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
ln -s ../lib/codex/codex-path/rg /usr/local/codex-path
ln -s ../lib/codex/codex-resources /usr/local/codex-resources
ln -s ../lib/codex/bin/codex /usr/local/bin/codex
EOF

# https://x.ai/cli/install.sh
RUN <<EOF
set -xe
GROK_BIN_DIR=/usr/local/bin bash -c "\$(curl -fsSL https://x.ai/cli/install.sh)"
grok --version
EOF

# https://claude.ai/install.sh
RUN <<EOF
set -xe
case "${TARGETARCH}" in
    amd64) CLAUDE_PLATFORM=linux-x64 ;;
    arm64) CLAUDE_PLATFORM=linux-arm64 ;;
    *) exit 1 ;;
esac
CLAUDE_VERSION=$(curl -fsSL https://downloads.claude.ai/claude-code-releases/latest)
curl -fsSL \
    "https://downloads.claude.ai/claude-code-releases/${CLAUDE_VERSION}/${CLAUDE_PLATFORM}/claude" \
    -o /usr/local/bin/claude
chmod 755 /usr/local/bin/claude
claude --version
EOF
