#!/usr/bin/env bash

set -euo pipefail

# ---------------------------------------------------------
# CKAD Dojo - Cluster Reset
#
# 기존 CKAD 클러스터를 삭제하고
# 동일한 설정으로 깨끗하게 다시 생성한다.
# ---------------------------------------------------------

CLUSTER_NAME="ckad"
KUBERNETES_VERSION="v1.37.0"


# sudo 실행 방지
if [[ "$EUID" -eq 0 ]]; then
  echo "Do not run this script with sudo."
  exit 1
fi


echo "======================================"
echo " RESET CKAD DOJO"
echo "======================================"


# ---------------------------------------------------------
# 1. Delete existing cluster
# ---------------------------------------------------------

CLUSTERS="$(kind get clusters 2>/dev/null || true)"

if echo "$CLUSTERS" | grep -qx "$CLUSTER_NAME"; then

  echo "[1/3] Deleting existing cluster..."

  kind delete cluster \
    --name "$CLUSTER_NAME"

else

  echo "[1/3] Existing cluster not found."

fi


# ---------------------------------------------------------
# 2. Create cluster
# ---------------------------------------------------------

echo "[2/3] Creating cluster..."

kind create cluster \
  --name "$CLUSTER_NAME" \
  --image "kindest/node:${KUBERNETES_VERSION}"


# ---------------------------------------------------------
# 3. Wait until ready
# ---------------------------------------------------------

echo "[3/3] Waiting for Kubernetes..."

kubectl wait \
  --for=condition=Ready \
  nodes \
  --all \
  --timeout=180s


# CoreDNS까지 준비되었는지 확인한다.
kubectl rollout status \
  deployment/coredns \
  -n kube-system \
  --timeout=180s


# ---------------------------------------------------------
# Result
# ---------------------------------------------------------

echo
kubectl get nodes

echo
echo "CKAD DOJO RESET COMPLETE"
