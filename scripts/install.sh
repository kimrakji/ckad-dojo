#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="ckad"
KIND_CONFIG="infra/kind.yaml"

ARCH="$(uname -m)"

case "$ARCH" in
  x86_64)
    BIN_ARCH="amd64"
    ;;
  aarch64|arm64)
    BIN_ARCH="arm64"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

echo "[1/8] Installing base packages..."

sudo apt-get update
sudo apt-get install -y \
  ca-certificates \
  curl \
  git \
  jq \
  wget \
  bash-completion


echo "[2/8] Installing Docker..."

if ! command -v docker >/dev/null 2>&1; then
  sudo install -m 0755 -d /etc/apt/keyrings

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo tee /etc/apt/keyrings/docker.asc >/dev/null

  sudo chmod a+r /etc/apt/keyrings/docker.asc

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update

  sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
fi

sudo systemctl enable --now docker

if ! id -nG "$USER" | grep -qw docker; then
  sudo usermod -aG docker "$USER"
fi


echo "[3/8] Installing kubectl..."

if ! command -v kubectl >/dev/null 2>&1; then
  KUBECTL_VERSION="$(
    curl -L -s https://dl.k8s.io/release/stable.txt
  )"

  curl -fsSLo /tmp/kubectl \
    "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${BIN_ARCH}/kubectl"

  sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
  rm -f /tmp/kubectl
fi


echo "[4/8] Installing kind..."

if ! command -v kind >/dev/null 2>&1; then
  curl -fsSLo /tmp/kind \
    "https://kind.sigs.k8s.io/dl/latest/kind-linux-${BIN_ARCH}"

  sudo install -m 0755 /tmp/kind /usr/local/bin/kind
  rm -f /tmp/kind
fi


echo "[5/8] Installing Helm..."

if ! command -v helm >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
    | bash
fi


echo "[6/8] Installing yq..."

if ! command -v yq >/dev/null 2>&1; then
  curl -fsSLo /tmp/yq \
    "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${BIN_ARCH}"

  sudo install -m 0755 /tmp/yq /usr/local/bin/yq
  rm -f /tmp/yq
fi


echo "[7/8] Configuring shell..."

BASHRC="$HOME/.bashrc"

grep -qxF 'alias k=kubectl' "$BASHRC" \
  || echo 'alias k=kubectl' >> "$BASHRC"

grep -qxF 'source <(kubectl completion bash)' "$BASHRC" \
  || echo 'source <(kubectl completion bash)' >> "$BASHRC"

grep -qxF 'complete -o default -F __start_kubectl k' "$BASHRC" \
  || echo 'complete -o default -F __start_kubectl k' >> "$BASHRC"


echo "[8/8] Creating CKAD cluster..."

if ! kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  sg docker -c \
    "kind create cluster \
      --name '${CLUSTER_NAME}' \
      --config '${KIND_CONFIG}'"
fi


echo
echo "======================================"
echo " CKAD DOJO READY"
echo "======================================"
echo

kubectl cluster-info
kubectl get nodes

echo
echo "docker : $(docker --version)"
echo "kubectl: $(kubectl version --client 2>/dev/null | head -n 1)"
echo "kind   : $(kind --version)"
echo "helm   : $(helm version --short)"
echo "yq     : $(yq --version)"
echo
echo "Run: source ~/.bashrc"