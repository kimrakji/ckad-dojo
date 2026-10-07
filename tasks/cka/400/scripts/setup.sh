#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_DIR="${TASK_DIR}/workspace"
KUBE_CONTEXT="kind-cloud-native-dojo"
NAMESPACE="nginx-static"
KUBE=(kubectl --context "$KUBE_CONTEXT")

for tool in kubectl jq openssl; do
  command -v "$tool" >/dev/null || { echo "Required tool not found: $tool" >&2; exit 1; }
done

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

test -f "${TASK_DIR}/fixtures/default.conf"
test -f "${TASK_DIR}/fixtures/namespace.yaml"
test -f "${TASK_DIR}/fixtures/resources.yaml"

umask 077
mkdir -p "${WORKSPACE_DIR}/tls"
cp "${TASK_DIR}/fixtures/default.conf" "${WORKSPACE_DIR}/default.conf"

openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
  -subj '/CN=web.k8s.local' \
  -keyout "${WORKSPACE_DIR}/tls/tls.key" \
  -out "${WORKSPACE_DIR}/tls/tls.crt" \
  >"${WORKSPACE_DIR}/openssl.log" 2>&1

# 기존 Namespace를 덮어쓰지 않도록 생성 충돌 시 실패
"${KUBE[@]}" create -f "${TASK_DIR}/fixtures/namespace.yaml"

"${KUBE[@]}" -n "$NAMESPACE" create secret tls nginx-tls \
  --cert="${WORKSPACE_DIR}/tls/tls.crt" \
  --key="${WORKSPACE_DIR}/tls/tls.key" \
  --dry-run=client -o yaml \
  | "${KUBE[@]}" -n "$NAMESPACE" apply -f -

"${KUBE[@]}" -n "$NAMESPACE" create configmap nginx-config \
  --from-file="default.conf=${WORKSPACE_DIR}/default.conf" \
  --dry-run=client -o yaml \
  | "${KUBE[@]}" -n "$NAMESPACE" apply -f -

"${KUBE[@]}" apply -f "${TASK_DIR}/fixtures/resources.yaml"
"${KUBE[@]}" -n "$NAMESPACE" rollout status deployment/nginx-static --timeout=180s

echo "CKA Task 400 is ready."
echo "Context: $KUBE_CONTEXT"
echo "Working directory: $TASK_DIR"
echo "Read task.md, solve the task, then run scripts/verify.sh."
