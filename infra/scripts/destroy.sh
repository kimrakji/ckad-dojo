#!/usr/bin/env bash

set -euo pipefail

# ---------------------------------------------------------
# Cloud Native Dojo - Cluster Destroy
#
# 실습용 kind 클러스터를 완전히 삭제한다.
# Docker, kubectl, kind 등의 도구 자체는 삭제하지 않는다.
# ---------------------------------------------------------

CLUSTER_NAME="ckad"


# sudo 실행 방지
if [[ "$EUID" -eq 0 ]]; then
  echo "Do not run this script with sudo."
  exit 1
fi


# 현재 존재하는 kind cluster 목록을 가져온다.
CLUSTERS="$(kind get clusters 2>/dev/null || true)"


if echo "$CLUSTERS" | grep -qx "$CLUSTER_NAME"; then

  echo "Deleting cluster: $CLUSTER_NAME"

  kind delete cluster \
    --name "$CLUSTER_NAME"

else

  echo "Cluster does not exist: $CLUSTER_NAME"

fi
