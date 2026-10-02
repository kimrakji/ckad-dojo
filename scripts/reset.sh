#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="ckad"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
KIND_CONFIG="${ROOT_DIR}/infra/kind.yaml"

echo "======================================"
echo " RESET CKAD DOJO"
echo "======================================"

if kind get clusters | grep -qx "$CLUSTER_NAME"; then
  echo "[1/3] Deleting existing cluster..."
  kind delete cluster --name "$CLUSTER_NAME"
else
  echo "[1/3] Existing cluster not found."
fi

echo "[2/3] Creating cluster..."

kind create cluster \
  --name "$CLUSTER_NAME" \
  --config "$KIND_CONFIG"

echo "[3/3] Waiting for node..."

kubectl wait \
  --for=condition=Ready \
  nodes \
  --all \
  --timeout=180s

echo
kubectl get nodes

echo
echo "CKAD DOJO RESET COMPLETE"