#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="ckad"

KUBECTL_VERSION="v1.37.1"
KIND_VERSION="v0.33.0"
HELM_VERSION="v3.22.0"
YQ_VERSION="v4.54.1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
KIND_CONFIG="${ROOT_DIR}/infra/kind.yaml"

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
  bash-completion \
  ca-certificates \
  curl \
  git \
  gzip \
  jq \
  tar \
  wget


echo "[2/8] Installing Docker..."

if ! command -v docker >/dev/null 2>&1; then
  sudo install -m 0755 -d /etc/apt/keyrings

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo tee /etc/apt/keyrings/docker.asc >/dev/null

  sudo chmod a+r /etc/apt/keyrings/docker.asc

  . /etc/os-release

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    ${UBUNTU_CODENAME:-$VERSION_CODENAME} stable" \
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


echo "[3/8] Installing kubectl ${KUBECTL_VERSION}..."

CURRENT_KUBECTL_VERSION=""

if command -v kubectl >/dev/null 2>&1; then
  CURRENT_KUBECTL_VERSION="$(
    kubectl version --client -o json 2>/dev/null \
      | jq -r '.clientVersion.gitVersion // empty'
  )"
fi

if [[ "$CURRENT_KUBECTL_VERSION" != "$KUBECTL_VERSION" ]]; then
  curl -fsSLo /tmp/kubectl \
    "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${BIN_ARCH}/kubectl"

  sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
  rm -f /tmp/kubectl
fi


echo "[4/8] Installing kind ${KIND_VERSION}..."

CURRENT_KIND_VERSION=""

if command -v kind >/dev/null 2>&1; then
  CURRENT_KIND_VERSION="$(kind --version | awk '{print $3}')"
fi

if [[ "$CURRENT_KIND_VERSION" != "${KIND_VERSION#v}" ]]; then
  curl -fsSLo /tmp/kind \
    "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${BIN_ARCH}"

  sudo install -m 0755 /tmp/kind /usr/local/bin/kind
  rm -f /tmp/kind
fi


echo "[5/8] Installing Helm ${HELM_VERSION}..."

CURRENT_HELM_VERSION=""

if command -v helm >/dev/null 2>&1; then
  CURRENT_HELM_VERSION="$(helm version --short 2>/dev/null | cut -d'+' -f1)"
fi

if [[ "$CURRENT_HELM_VERSION" != "$HELM_VERSION" ]]; then
  HELM_ARCHIVE="/tmp/helm.tar.gz"
  HELM_DIR="/tmp/helm-${HELM_VERSION}"

  rm -rf "$HELM_DIR"
  mkdir -p "$HELM_DIR"

  curl -fsSLo "$HELM_ARCHIVE" \
    "https://get.helm.sh/helm-${HELM_VERSION}-linux-${BIN_ARCH}.tar.gz"

  tar -xzf "$HELM_ARCHIVE" -C "$HELM_DIR"

  sudo install -m 0755 \
    "${HELM_DIR}/linux-${BIN_ARCH}/helm" \
    /usr/local/bin/helm

  rm -rf "$HELM_ARCHIVE" "$HELM_DIR"
fi


echo "[6/8] Installing yq ${YQ_VERSION}..."

CURRENT_YQ_VERSION=""

if command -v yq >/dev/null 2>&1; then
  CURRENT_YQ_VERSION="$(
    yq --version 2>/dev/null \
      | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' \
      | head -n 1
  )"
fi

if [[ "$CURRENT_YQ_VERSION" != "$YQ_VERSION" ]]; then
  curl -fsSLo /tmp/yq \
    "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${BIN_ARCH}"

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

if ! sg docker -c "kind get clusters" 2>/dev/null \
  | grep -qx "$CLUSTER_NAME"; then

  sg docker -c \
    "kind create cluster \
      --name '${CLUSTER_NAME}' \
      --config '${KIND_CONFIG}'"
else
  sg docker -c \
    "kind export kubeconfig \
      --name '${CLUSTER_NAME}'"
fi

kubectl config use-context "kind-${CLUSTER_NAME}" >/dev/null

echo "[+] Waiting for Kubernetes node..."

kubectl wait \
  --for=condition=Ready \
  nodes \
  --all \
  --timeout=180s


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
echo "Reconnect SSH to apply Docker group membership."