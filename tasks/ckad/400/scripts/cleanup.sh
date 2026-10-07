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

if "$CONTAINER_TOOL" image inspect "$IMAGE_REF" >/dev/null 2>&1; then
  TASK_LABEL="$("$CONTAINER_TOOL" image inspect --format '{{ index .Config.Labels "io.ckad-dojo.task" }}' "$IMAGE_REF")"
  # 번호 변경 전의 001·300 소유 라벨도 허용하고, 다른 이미지는 삭제 대상에서 제외
  if [[ "$TASK_LABEL" != "400" && "$TASK_LABEL" != "300" && "$TASK_LABEL" != "001" ]]; then
    echo "Refusing to remove $IMAGE_REF: it is not marked as a Task 400 image." >&2
    exit 1
  fi
  "$CONTAINER_TOOL" image rm "$IMAGE_REF"
fi

rm -rf -- "$WORKSPACE_DIR"
echo "Task 400 cleaned up."
