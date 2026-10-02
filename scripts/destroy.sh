#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="ckad"

if kind get clusters | grep -qx "$CLUSTER_NAME"; then
  echo "Deleting cluster: $CLUSTER_NAME"
  kind delete cluster --name "$CLUSTER_NAME"
else
  echo "Cluster does not exist: $CLUSTER_NAME"
fi