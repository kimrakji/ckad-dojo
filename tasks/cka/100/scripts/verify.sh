#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_DIR="${TASK_DIR}/workspace"
KUBE_CONTEXT="kind-cloud-native-dojo"
NAMESPACE="cka-100"
KUBE=(kubectl --context "$KUBE_CONTEXT" -n "$NAMESPACE")

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

pass() {
  echo "PASS: $*"
}

for tool in kubectl jq; do
  command -v "$tool" >/dev/null || fail "Required tool not found: $tool"
done

[[ -d "$WORKSPACE_DIR" ]] || fail "Workspace is missing. Run scripts/setup.sh first."

NAMESPACE_JSON="$("${KUBE[@]}" get namespace "$NAMESPACE" -o json)" \
  || fail "Namespace not found: $NAMESPACE"
jq -e '.metadata.labels["cloud-native-dojo/task"] == "cka-100"' \
  <<< "$NAMESPACE_JSON" >/dev/null || fail "Namespace is not marked as a CKA Task 100 namespace."

DEPLOYMENT="$("${KUBE[@]}" get deployment playground-web -o json)" \
  || fail "Deployment not found: playground-web"
jq -e '
  .spec.replicas == 3
  and any(.spec.template.spec.containers[];
    .name == "web" and .image == "nginx:1.30.5-alpine")
' <<< "$DEPLOYMENT" >/dev/null || fail "Use the provided image and scale playground-web to 3 replicas."
pass "Deployment uses the provided image and requests 3 replicas."

"${KUBE[@]}" rollout status deployment/playground-web --timeout=180s \
  || fail "Deployment is not ready: playground-web"

# rollout 완료 후 다시 조회하여 이전 준비 상태만으로 성공 처리하지 않음
DEPLOYMENT="$("${KUBE[@]}" get deployment playground-web -o json)" \
  || fail "Could not read the updated Deployment."
jq -e '
  .metadata.deletionTimestamp == null
  and .spec.replicas == 3
  and any(.spec.template.spec.containers[];
    .name == "web" and .image == "nginx:1.30.5-alpine")
  and .status.observedGeneration >= .metadata.generation
  and .status.replicas == 3
  and .status.updatedReplicas == 3
  and .status.readyReplicas == 3
  and .status.availableReplicas == 3
' <<< "$DEPLOYMENT" >/dev/null || fail "Wait until playground-web has 3 updated, ready, and available replicas."
pass "Deployment has 3 updated, ready, and available replicas."

echo "CKA Task 100 complete."
