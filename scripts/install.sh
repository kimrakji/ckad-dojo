#!/usr/bin/env bash

set -euo pipefail

# ---------------------------------------------------------
# CKAD Dojo - Environment Installer
#
# Ubuntu Minimal 환경에 CKAD 훈련에 필요한 도구를 설치하고
# kind 기반 Kubernetes 클러스터를 생성한다.
#
# 이 스크립트는 sudo로 실행하지 않는다.
# 필요한 작업에서만 내부적으로 sudo를 사용한다.
# ---------------------------------------------------------


# ---------------------------------------------------------
# Configuration
# ---------------------------------------------------------

CLUSTER_NAME="ckad"

KUBERNETES_VERSION="v1.37.0"
KUBECTL_VERSION="v1.37.1"
KIND_VERSION="v0.33.0"
HELM_VERSION="v3.22.0"
YQ_VERSION="v4.54.1"


# ---------------------------------------------------------
# Paths
#
# install.sh를 어느 디렉터리에서 실행하더라도
# repository root와 kind 설정 파일을 찾을 수 있도록 한다.
# ---------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

KIND_CONFIG="${ROOT_DIR}/infra/kind.yaml"


# ---------------------------------------------------------
# Prevent root execution
#
# root로 실행하면 kubeconfig가 /root 아래 생성되는 등
# 사용자 환경이 꼬일 수 있으므로 일반 사용자 실행만 허용한다.
# ---------------------------------------------------------

if [[ "$EUID" -eq 0 ]]; then
  echo "Do not run this script with sudo."
  exit 1
fi


# ---------------------------------------------------------
# OS check
#
# 현재 CKAD Dojo는 Ubuntu 환경만 지원한다.
# ---------------------------------------------------------

if [[ ! -f /etc/os-release ]]; then
  echo "Unable to detect operating system."
  exit 1
fi

source /etc/os-release

if [[ "$ID" != "ubuntu" ]]; then
  echo "Unsupported OS: $ID"
  echo "CKAD Dojo currently supports Ubuntu only."
  exit 1
fi


# ---------------------------------------------------------
# Architecture detection
#
# UTM + Apple Silicon에서는 aarch64가 나오며
# 다운로드 URL에서는 arm64라는 이름을 사용한다.
# ---------------------------------------------------------

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


# ---------------------------------------------------------
# 1. Base packages
# ---------------------------------------------------------

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


# ---------------------------------------------------------
# 2. Docker
#
# Docker가 없다면 공식 Docker APT repository를 등록하고
# Docker Engine을 설치한다.
# ---------------------------------------------------------

echo "[2/8] Installing Docker..."

if ! command -v docker >/dev/null 2>&1; then

  sudo install -m 0755 -d /etc/apt/keyrings

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo tee /etc/apt/keyrings/docker.asc >/dev/null

  sudo chmod a+r /etc/apt/keyrings/docker.asc

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


# Docker daemon을 현재 부팅과 이후 부팅에서도 활성화한다.
sudo systemctl enable --now docker


# 현재 사용자가 sudo 없이 Docker를 사용할 수 있도록 한다.
#
# group 변경은 현재 shell에 즉시 반영되지 않으므로
# 최초 설치 후에는 SSH 재접속이 필요하다.
if ! id -nG "$USER" | grep -qw docker; then
  sudo usermod -aG docker "$USER"
fi


# ---------------------------------------------------------
# 3. kubectl
#
# 설치된 버전을 확인하고 원하는 버전과 다를 경우 교체한다.
# ---------------------------------------------------------

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

  sudo install -m 0755 \
    /tmp/kubectl \
    /usr/local/bin/kubectl

  rm -f /tmp/kubectl
fi


# ---------------------------------------------------------
# 4. kind
# ---------------------------------------------------------

echo "[4/8] Installing kind ${KIND_VERSION}..."

CURRENT_KIND_VERSION=""

if command -v kind >/dev/null 2>&1; then
  CURRENT_KIND_VERSION="$(kind --version | awk '{print $3}')"
fi

if [[ "$CURRENT_KIND_VERSION" != "${KIND_VERSION#v}" ]]; then

  curl -fsSLo /tmp/kind \
    "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${BIN_ARCH}"

  sudo install -m 0755 \
    /tmp/kind \
    /usr/local/bin/kind

  rm -f /tmp/kind
fi


# ---------------------------------------------------------
# 5. Helm
# ---------------------------------------------------------

echo "[5/8] Installing Helm ${HELM_VERSION}..."

CURRENT_HELM_VERSION=""

if command -v helm >/dev/null 2>&1; then
  CURRENT_HELM_VERSION="$(
    helm version --short 2>/dev/null \
      | cut -d'+' -f1
  )"
fi

if [[ "$CURRENT_HELM_VERSION" != "$HELM_VERSION" ]]; then

  HELM_ARCHIVE="/tmp/helm.tar.gz"
  HELM_DIR="/tmp/helm-${HELM_VERSION}"

  rm -rf "$HELM_DIR"
  mkdir -p "$HELM_DIR"

  curl -fsSLo "$HELM_ARCHIVE" \
    "https://get.helm.sh/helm-${HELM_VERSION}-linux-${BIN_ARCH}.tar.gz"

  tar -xzf "$HELM_ARCHIVE" \
    -C "$HELM_DIR"

  sudo install -m 0755 \
    "${HELM_DIR}/linux-${BIN_ARCH}/helm" \
    /usr/local/bin/helm

  rm -rf "$HELM_ARCHIVE" "$HELM_DIR"
fi


# ---------------------------------------------------------
# 6. yq
# ---------------------------------------------------------

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

  sudo install -m 0755 \
    /tmp/yq \
    /usr/local/bin/yq

  rm -f /tmp/yq
fi


# ---------------------------------------------------------
# 7. Shell configuration
#
# CKAD 시험 환경처럼 kubectl alias와 completion을 사용한다.
# ---------------------------------------------------------

echo "[7/8] Configuring shell..."

BASHRC="$HOME/.bashrc"

grep -qxF 'alias k=kubectl' "$BASHRC" \
  || echo 'alias k=kubectl' >> "$BASHRC"

grep -qxF 'source <(kubectl completion bash)' "$BASHRC" \
  || echo 'source <(kubectl completion bash)' >> "$BASHRC"

grep -qxF 'complete -o default -F __start_kubectl k' "$BASHRC" \
  || echo 'complete -o default -F __start_kubectl k' >> "$BASHRC"


# ---------------------------------------------------------
# 8. Kubernetes cluster
#
# 이미 ckad 클러스터가 있다면 새로 만들지 않는다.
#
# Docker group 변경 직후에도 실행할 수 있도록
# kind 명령은 sg docker를 통해 실행한다.
# ---------------------------------------------------------

echo "[8/8] Creating CKAD cluster..."

if ! sg docker -c "kind get clusters" 2>/dev/null \
  | grep -qx "$CLUSTER_NAME"; then

  sg docker -c \
    "kind create cluster \
      --name '${CLUSTER_NAME}' \
      --image 'kindest/node:${KUBERNETES_VERSION}' \
      --config '${KIND_CONFIG}'"

else

  # 기존 클러스터가 있다면 kubeconfig를 다시 export한다.
  sg docker -c \
    "kind export kubeconfig \
      --name '${CLUSTER_NAME}'"

fi


# 사용할 kubectl context를 명확하게 지정한다.
kubectl config use-context "kind-${CLUSTER_NAME}" >/dev/null


# ---------------------------------------------------------
# Wait for Kubernetes
# ---------------------------------------------------------

echo "[+] Waiting for Kubernetes node..."

kubectl wait \
  --for=condition=Ready \
  nodes \
  --all \
  --timeout=180s


# CoreDNS까지 정상적으로 올라와야 훈련 환경이 준비된 것으로 본다.
echo "[+] Waiting for CoreDNS..."

kubectl rollout status \
  deployment/coredns \
  -n kube-system \
  --timeout=180s


# ---------------------------------------------------------
# Result
# ---------------------------------------------------------

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