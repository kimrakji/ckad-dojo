#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_DIR="${TASK_DIR}/workspace"
KUBE_CONTEXT="kind-cloud-native-dojo"
NAMESPACE="nginx-static"
KUBE=(kubectl --context "$KUBE_CONTEXT" -n "$NAMESPACE")

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

pass() {
  echo "PASS: $*"
}

for tool in kubectl jq curl; do
  command -v "$tool" >/dev/null || fail "Required tool not found: $tool"
done

[[ -d "$WORKSPACE_DIR" ]] || fail "Workspace is missing. Run scripts/setup.sh first."

CONFIGMAP="$("${KUBE[@]}" get configmap nginx-config -o json)" \
  || fail "ConfigMap not found: nginx-config"
jq -e '
  .data["default.conf"]
  | gsub("#[^\n]*"; "")
  | test("\\bssl_protocols\\s+[^;]*\\bTLSv1\\.2\\b[^;]*;")
' <<< "$CONFIGMAP" >/dev/null 2>&1 || fail "nginx-config does not allow TLS 1.2."
pass "ConfigMap allows TLS 1.2."

"${KUBE[@]}" rollout status deployment/nginx-static --timeout=180s \
  || fail "Deployment is not ready: nginx-static"

SERVICE="$("${KUBE[@]}" get service nginx-static -o json)" \
  || fail "Service not found: nginx-static"
jq -e '.spec.type == "NodePort" and any(.spec.ports[]; .port == 443 and .nodePort == 30007)' \
  <<< "$SERVICE" >/dev/null || fail "The existing HTTPS service on port 30007 must be preserved."

PORT_FORWARD_LOG="$(mktemp "${WORKSPACE_DIR}/port-forward.XXXXXX")"
PORT_FORWARD_PID=""

cleanup() {
  if [[ -n "$PORT_FORWARD_PID" ]]; then
    kill "$PORT_FORWARD_PID" 2>/dev/null || true
    wait "$PORT_FORWARD_PID" 2>/dev/null || true
  fi
  rm -f -- "$PORT_FORWARD_LOG"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# 수동 테스트와 충돌하지 않도록 사용 가능한 임시 로컬 포트 요청
"${KUBE[@]}" port-forward --address 127.0.0.1 service/nginx-static :443 \
  >"$PORT_FORWARD_LOG" 2>&1 &
PORT_FORWARD_PID="$!"

LOCAL_PORT=""
for ((attempt = 0; attempt < 50; attempt++)); do
  LOCAL_PORT="$(sed -n 's/^Forwarding from 127\.0\.0\.1:\([0-9][0-9]*\) -> .*/\1/p' "$PORT_FORWARD_LOG" | head -n 1)"
  [[ -n "$LOCAL_PORT" ]] && break
  if ! kill -0 "$PORT_FORWARD_PID" 2>/dev/null; then
    cat "$PORT_FORWARD_LOG" >&2
    fail "Could not start port-forward for the HTTPS service."
  fi
  sleep 0.2
done
[[ -n "$LOCAL_PORT" ]] || fail "Timed out waiting for port-forward."

curl --fail --silent --show-error --insecure \
  --tlsv1.2 --tls-max 1.2 --noproxy '*' \
  --connect-timeout 5 --max-time 10 \
  --resolve "web.k8s.local:${LOCAL_PORT}:127.0.0.1" \
  "https://web.k8s.local:${LOCAL_PORT}" >/dev/null \
  || fail "TLS 1.2 HTTPS request failed. Apply the ConfigMap change to the running Pods."
pass "The running HTTPS service accepts TLS 1.2."

echo "CKA Task 001 complete."
