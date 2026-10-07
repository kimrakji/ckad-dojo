#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TASK_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE_DIR="${TASK_DIR}/workspace"
ARCHIVE="${WORKSPACE_DIR}/packages/branch-notice-2.4.1.tar"
IMAGE_REF="branch-notice:2.4.1"
CONTAINER_TOOL="${CONTAINER_TOOL:-docker}"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

pass() {
  echo "PASS: $*"
}

case "$CONTAINER_TOOL" in
  docker|podman) ;;
  *) fail "Unsupported container tool: $CONTAINER_TOOL" ;;
esac

for tool in "$CONTAINER_TOOL" jq tar gzip; do
  command -v "$tool" >/dev/null || fail "Required tool not found: $tool"
done

sha256() {
  if command -v sha256sum >/dev/null; then
    sha256sum | cut -d ' ' -f 1
  else
    shasum -a 256 | cut -d ' ' -f 1
  fi
}

command -v sha256sum >/dev/null || command -v shasum >/dev/null || fail "A SHA-256 tool is required."
"$CONTAINER_TOOL" info >/dev/null || fail "Cannot connect to $CONTAINER_TOOL."

for file in Containerfile index.html style.css status.json; do
  cmp -s "${TASK_DIR}/fixtures/notice-site/${file}" "${WORKSPACE_DIR}/notice-site/${file}" \
    || fail "Provided file is missing or modified: $file"
done
pass "Provided files are unchanged."

LOCAL_IMAGE="$(
  "$CONTAINER_TOOL" image inspect "$IMAGE_REF" 2>/dev/null \
    | jq -ce '.[0] | select(type == "object")'
)" || fail "Image not found: $IMAGE_REF"
pass "Image exists: $IMAGE_REF"

[[ -s "$ARCHIVE" ]] || fail "Archive is missing or empty: $ARCHIVE"
tar -tf "$ARCHIVE" >/dev/null 2>&1 || fail "The output is not a readable tar archive."
MANIFEST="$(tar -xOf "$ARCHIVE" manifest.json 2>/dev/null)" \
  || fail "Docker archive metadata (manifest.json) is missing."

ENTRY="$(jq -ce --arg ref "$IMAGE_REF" '
  if type != "array" then error("invalid manifest") else
    [.[] | select((.RepoTags // []) | any(
      . == $ref or . == ("docker.io/library/" + $ref) or . == ("docker.io/" + $ref)
    ))]
    | if length == 1 then .[0] else error("expected image tag not found or duplicated") end
  end
  | select((.Config | type) == "string" and (.Layers | type) == "array" and (.Layers | length) > 0)
' <<< "$MANIFEST" 2>/dev/null)" || fail "Archive does not contain valid metadata for $IMAGE_REF."
pass "Archive includes the expected name and tag."

CONFIG_MEMBER="$(jq -r '.Config' <<< "$ENTRY")"
CONFIG="$(tar -xOf "$ARCHIVE" -- "$CONFIG_MEMBER" 2>/dev/null)" \
  || fail "Image configuration is missing from the archive."
jq -e '.config.Labels["io.ckad-dojo.task"] == "400" and .rootfs.type == "layers"' \
  <<< "$CONFIG" >/dev/null 2>&1 || fail "The archive was not built from the provided Containerfile."

LAYER_COUNT="$(jq '.Layers | length' <<< "$ENTRY")"
jq -e --argjson count "$LAYER_COUNT" '
  (.rootfs.diff_ids | type) == "array" and (.rootfs.diff_ids | length) == $count
' <<< "$CONFIG" >/dev/null 2>&1 || fail "Image layer metadata is incomplete."

# 저장 방식에 따라 의미가 다른 이미지 ID 대신 레이어·실행 설정을 비교
jq -e --argjson local "$LOCAL_IMAGE" '
  def runtime_config:
    {
      User: (.User // ""),
      Env: (.Env // []),
      Entrypoint: (.Entrypoint // []),
      Cmd: (.Cmd // []),
      WorkingDir: (.WorkingDir // ""),
      ExposedPorts: (.ExposedPorts // {}),
      Volumes: (.Volumes // {}),
      Labels: (.Labels // {}),
      StopSignal: (.StopSignal // ""),
      Healthcheck: (.Healthcheck // {})
    };

  .rootfs.type == "layers"
  and .rootfs.diff_ids == $local.RootFS.Layers
  and .architecture == $local.Architecture
  and .os == $local.Os
  and (.config | runtime_config) == ($local.Config | runtime_config)
' <<< "$CONFIG" >/dev/null 2>&1 \
  || fail "Archive layers or runtime configuration differ from the local image."
pass "Archive layers and runtime configuration match the local Task 400 image."

# 레이어 파일 이름만 확인하면 손상된 제출물이 통과하므로 내용 해시도 비교
for ((index = 0; index < LAYER_COUNT; index++)); do
  LAYER_MEMBER="$(jq -r --argjson index "$index" '.Layers[$index]' <<< "$ENTRY")"
  EXPECTED_HASH="$(jq -r --argjson index "$index" '.rootfs.diff_ids[$index]' <<< "$CONFIG")"
  LAYER_HASH="$(tar -xOf "$ARCHIVE" -- "$LAYER_MEMBER" 2>/dev/null | sha256)" \
    || fail "Layer is missing or unreadable: $LAYER_MEMBER"
  if [[ "sha256:${LAYER_HASH}" != "$EXPECTED_HASH" ]]; then
    LAYER_HASH="$(tar -xOf "$ARCHIVE" -- "$LAYER_MEMBER" 2>/dev/null | gzip -cd 2>/dev/null | sha256)" \
      || fail "Layer is missing or corrupted: $LAYER_MEMBER"
    [[ "sha256:${LAYER_HASH}" == "$EXPECTED_HASH" ]] || fail "Layer is corrupted: $LAYER_MEMBER"
  fi
done
pass "All $LAYER_COUNT image layers are present and intact."
echo "Task 400 complete."
