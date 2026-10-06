#!/usr/bin/env bash

set -euo pipefail

# ---------------------------------------------------------
# Cloud Native Dojo - Status Checker
#
# 설치된 도구와 Kubernetes 클러스터 상태를 확인한다.
# ---------------------------------------------------------

CLUSTER_NAME="cloud-native-dojo"


# root로 실행하면 root 사용자의 kubeconfig를 참조하게 되므로
# sudo 실행을 허용하지 않는다.
if [[ "$EUID" -eq 0 ]]; then
  echo "Do not run this script with sudo."
  exit 1
fi


echo "======================================"
echo " CLOUD NATIVE DOJO STATUS"
echo "======================================"
echo


# ---------------------------------------------------------
# Docker
# ---------------------------------------------------------

echo "[Docker]"

docker --version

# Docker daemon에 실제로 연결 가능한지도 확인한다.
docker info >/dev/null

echo "Docker daemon: OK"


# ---------------------------------------------------------
# Tools
# ---------------------------------------------------------

echo
echo "[Tools]"

echo "kubectl: $(kubectl version --client 2>/dev/null | head -n 1)"
echo "kind   : $(kind --version)"
echo "helm   : $(helm version --short)"
echo "yq     : $(yq --version)"


# ---------------------------------------------------------
# Cluster
# ---------------------------------------------------------

echo
echo "[Clusters]"

CLUSTERS="$(kind get clusters 2>/dev/null || true)"

# 클러스터 생성 전에도 도구를 점검할 수 있도록 미생성 상태 허용
if ! echo "$CLUSTERS" | grep -qx "$CLUSTER_NAME"; then
  echo "Cluster not found: $CLUSTER_NAME"
  exit 0
fi

echo "$CLUSTERS"


# ---------------------------------------------------------
# Kubernetes
# ---------------------------------------------------------

echo
echo "[Nodes]"

kubectl --context "kind-${CLUSTER_NAME}" get nodes


echo
echo "[Pods]"

kubectl --context "kind-${CLUSTER_NAME}" get pods -A
