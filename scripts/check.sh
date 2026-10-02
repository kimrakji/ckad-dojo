#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="ckad"

echo "======================================"
echo " CKAD DOJO STATUS"
echo "======================================"
echo

echo "[Docker]"
docker --version
docker info >/dev/null
echo "Docker daemon: OK"

echo
echo "[Tools]"
echo "kubectl: $(kubectl version --client 2>/dev/null | head -n 1)"
echo "kind   : $(kind --version)"
echo "helm   : $(helm version --short)"
echo "yq     : $(yq --version)"

echo
echo "[Clusters]"
kind get clusters

echo
echo "[Nodes]"
kubectl get nodes

echo
echo "[Pods]"
kubectl get pods -A