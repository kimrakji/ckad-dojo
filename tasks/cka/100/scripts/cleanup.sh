#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_DIR="${TASK_DIR}/workspace"
KUBE_CONTEXT="kind-cloud-native-dojo"
NAMESPACE="cka-100"
KUBE=(kubectl --context "$KUBE_CONTEXT")

for tool in kubectl jq; do
  command -v "$tool" >/dev/null || { echo "Required tool not found: $tool" >&2; exit 1; }
done

NAMESPACE_JSON="$("${KUBE[@]}" get namespace "$NAMESPACE" --ignore-not-found -o json)"
if [[ -n "$NAMESPACE_JSON" ]]; then
  # 이 문제의 소유 라벨이 있는 Namespace만 삭제
  jq -e '.metadata.labels["cloud-native-dojo/task"] == "cka-100"' \
    <<< "$NAMESPACE_JSON" >/dev/null || {
      echo "Refusing to remove $NAMESPACE: it is not marked as a CKA Task 100 namespace." >&2
      exit 1
    }
  "${KUBE[@]}" delete namespace "$NAMESPACE" --wait=true --timeout=120s
fi

rm -rf -- "$WORKSPACE_DIR"
echo "CKA Task 100 cleaned up."
