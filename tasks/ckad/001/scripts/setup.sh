#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_DIR="${TASK_DIR}/workspace"
IMAGE_REF="branch-notice:2.4.1"
CONTAINER_TOOL="${CONTAINER_TOOL:-docker}"

case "$CONTAINER_TOOL" in
  docker|podman) ;;
  *) echo "Unsupported container tool: $CONTAINER_TOOL" >&2; exit 1 ;;
esac

command -v "$CONTAINER_TOOL" >/dev/null || { echo "Required tool not found: $CONTAINER_TOOL" >&2; exit 1; }
"$CONTAINER_TOOL" info >/dev/null

# 풀이 결과가 남은 환경을 덮어쓰지 않도록 먼저 정리 필요
if [[ -e "$WORKSPACE_DIR" || -L "$WORKSPACE_DIR" ]]; then
  echo "Workspace already exists. Run scripts/cleanup.sh before setting up again." >&2
  exit 1
fi

if "$CONTAINER_TOOL" image inspect "$IMAGE_REF" >/dev/null 2>&1; then
  echo "Image already exists: $IMAGE_REF. Run scripts/cleanup.sh or choose another container tool." >&2
  exit 1
fi

for file in Containerfile index.html style.css status.json; do
  test -f "${TASK_DIR}/fixtures/notice-site/${file}"
done

mkdir -p "$WORKSPACE_DIR"
cp -R "${TASK_DIR}/fixtures/notice-site" "$WORKSPACE_DIR/notice-site"

echo "Task 001 is ready."
echo "Working directory: $TASK_DIR"
echo "Read task.md, solve the task, then run scripts/verify.sh."
