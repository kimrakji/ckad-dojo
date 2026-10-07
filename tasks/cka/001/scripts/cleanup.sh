#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_DIR="${TASK_DIR}/workspace"
KUBE_CONTEXT="kind-cloud-native-dojo"
NAMESPACE="nginx-static"
KUBE=(kubectl --context "$KUBE_CONTEXT")

for tool in kubectl jq; do
  command -v "$tool" >/dev/null || { echo "Required tool not found: $tool" >&2; exit 1; }
done

NAMESPACE_JSON="$("${KUBE[@]}" get namespace "$NAMESPACE" --ignore-not-found -o json)"
if [[ -n "$NAMESPACE_JSON" ]]; then
  # 문제 소유 라벨이 없는 Namespace는 삭제 대상에서 제외
  jq -e '.metadata.labels["cloud-native-dojo/task"] == "cka-001"' \
    <<< "$NAMESPACE_JSON" >/dev/null || {
      echo "Refusing to remove $NAMESPACE: it is not marked as a CKA Task 001 namespace." >&2
      exit 1
    }
  "${KUBE[@]}" delete namespace "$NAMESPACE" --wait=true --timeout=120s
fi

rm -rf -- "$WORKSPACE_DIR"
echo "CKA Task 001 cleaned up."
