#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_DIR="${TASK_DIR}/workspace"
KUBE_CONTEXT="kind-cloud-native-dojo"
NAMESPACE="cka-100"
KUBE=(kubectl --context "$KUBE_CONTEXT")

command -v kubectl >/dev/null || { echo "Required tool not found: kubectl" >&2; exit 1; }

# 이전 풀이 결과를 덮어쓰지 않도록 정리 후 재준비
if [[ -e "$WORKSPACE_DIR" || -L "$WORKSPACE_DIR" ]]; then
  echo "Workspace already exists. Run scripts/cleanup.sh before setting up again." >&2
  exit 1
fi

EXISTING_NAMESPACE="$("${KUBE[@]}" get namespace "$NAMESPACE" --ignore-not-found -o json)"
if [[ -n "$EXISTING_NAMESPACE" ]]; then
  echo "Namespace already exists: $NAMESPACE. Run scripts/cleanup.sh or use a clean training cluster." >&2
  exit 1
fi

test -f "${TASK_DIR}/fixtures/namespace.yaml"
test -f "${TASK_DIR}/fixtures/deployment.yaml"

umask 077
mkdir -p "$WORKSPACE_DIR"
cp "${TASK_DIR}/fixtures/deployment.yaml" "${WORKSPACE_DIR}/deployment.yaml"
"${KUBE[@]}" create -f "${TASK_DIR}/fixtures/namespace.yaml"

echo "CKA Task 100 is ready."
echo "Context: $KUBE_CONTEXT"
echo "Working directory: $TASK_DIR"
echo "Read task.md, follow the commands, then run scripts/verify.sh."
