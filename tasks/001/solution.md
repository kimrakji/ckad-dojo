# Task 001 Solution : 컨테이너 이미지 빌드·저장 해설

[문제](task.md)의 요구사항은 제공된 파일로 이미지를 빌드하고, 다른 장비에서 복원할 수 있는 이미지 아카이브를 만드는 것입니다.

## Requirements : 문제 해석

- 빌드 파일: `workspace/notice-site/Containerfile`
- 빌드 컨텍스트: `workspace/notice-site/`
- 이미지 이름과 태그: `branch-notice:2.4.1`
- 제출 형식: Docker 이미지 아카이브
- 제출 경로: `workspace/packages/branch-notice-2.4.1.tar`
- 제공된 빌드 파일과 애플리케이션 파일은 수정하지 않습니다.

컨테이너 실행이나 Kubernetes 리소스 생성은 제출 조건에 포함되지 않습니다.

## Flow : 전체 흐름

```text
workspace/notice-site/
  Containerfile + index.html + style.css + status.json
      |
      | build
      v
branch-notice:2.4.1
  Local image
      |
      | save
      v
workspace/packages/branch-notice-2.4.1.tar
      |
      | load
      v
branch-notice:2.4.1
  Image restored on the destination host
```

빌드는 준비 파일로 이미지를 만들고, 저장은 이미지를 전달할 파일로 만듭니다. 전달받은 장비에서는 소스 파일을 다시 빌드하지 않고 아카이브에서 이미지를 가져올 수 있습니다.

## Preparation : 실습 준비

저장소 루트에서 실행합니다.

```bash
./tasks/001/scripts/setup.sh
cd tasks/001
```

준비 스크립트는 `fixtures/`의 원본 파일을 `workspace/`로 복사합니다. 이후 명령은 문제 디렉터리에서 실행합니다. 이미 준비된 환경이라면 해당 디렉터리로 이동해서 풀이를 시작합니다.

## Solution : 풀이 명령

### Build : 이미지 빌드

```bash
docker build \
  -f workspace/notice-site/Containerfile \
  -t branch-notice:2.4.1 \
  workspace/notice-site
```

- `-f`: 사용할 빌드 파일을 지정합니다. 파일명이 기본값인 `Dockerfile`과 다르므로 경로를 명시합니다.
- `-t`: 빌드한 이미지에 요구한 이름과 태그를 붙입니다.
- 마지막 인수: 빌드 컨텍스트를 지정합니다. `COPY`의 원본 파일은 이 디렉터리를 기준으로 찾습니다.

제공된 `Containerfile`은 Nginx 베이스 이미지에 웹 파일을 추가합니다.

```dockerfile
COPY index.html style.css status.json /usr/share/nginx/html/
```

빌드 컨텍스트를 `workspace/notice-site/`로 지정하면 위 세 파일을 읽을 수 있습니다. `-f`는 빌드 파일의 위치를 지정하며, 빌드 컨텍스트는 마지막 인수로 별도로 지정합니다.

별도 Buildx builder를 사용해 결과가 로컬 이미지 저장소에 나타나지 않으면 빌드 명령에 `--load`를 추가해 로컬로 가져옵니다.

### Save : 이미지 아카이브 저장

```bash
mkdir -p workspace/packages

docker image save \
  -o workspace/packages/branch-notice-2.4.1.tar \
  branch-notice:2.4.1
```

`mkdir -p`는 제출 파일을 저장할 디렉터리를 준비합니다. `docker image save`는 지정한 이미지의 레이어·설정·태그를 아카이브로 저장하며, `-o`는 출력 경로를 지정합니다.

## Verification : 제출물 검증

```bash
./scripts/verify.sh
```

검증 스크립트는 다음 항목을 확인합니다.

1. 제공된 네 파일이 원본과 같은지 확인합니다.
2. 로컬에 `branch-notice:2.4.1` 이미지가 있는지 확인합니다.
3. 아카이브의 `manifest.json`에 요구한 이름과 태그가 있는지 확인합니다.
4. 아카이브의 레이어 목록·실행 설정·플랫폼이 로컬 이미지와 같은지, 문제용 라벨이 있는지 확인합니다.
5. 모든 이미지 레이어가 포함되어 있고 내용 해시가 맞는지 확인합니다.

이미지 ID는 저장 방식에 따라 가리키는 대상이 다를 수 있으므로 직접 비교하지 않습니다. 레이어 목록과 실행 설정, 운영체제·아키텍처를 같은 항목끼리 비교합니다.

성공하면 마지막에 다음 메시지가 출력됩니다.

```text
Task 001 complete.
```

## Restore : 아카이브에서 이미지 복원

아카이브를 전달받은 장비에서는 `load`로 이미지를 가져옵니다. 아래는 현재 실습 환경에서 같은 파일을 읽는 예시입니다.

```bash
docker image load \
  -i workspace/packages/branch-notice-2.4.1.tar

docker image inspect branch-notice:2.4.1 \
  --format '{{.Id}}'
```

`save`와 `export`는 저장 대상이 다릅니다.

- `docker image save`: 이미지의 레이어·설정·태그를 저장하며, `docker image load`로 복원합니다.
- `docker container export`: 컨테이너의 파일 시스템을 저장하며, `docker image import`로 새 이미지를 만듭니다.

이번 문제는 이미지의 이름과 태그를 유지한 Docker 이미지 아카이브를 요구하므로 `save`를 사용합니다.

## Common Mistakes : 자주 발생하는 실수

- **Dockerfile을 찾지 못합니다.** `-f`로 실제 파일명인 `Containerfile`을 지정했는지 확인합니다.
- **COPY할 파일을 찾지 못합니다.** 빌드 명령의 마지막 인수가 `workspace/notice-site`인지 확인합니다.
- **이미지나 태그를 찾지 못합니다.** 요구한 이름과 태그를 확인하고, 실제 빌드한 이미지를 `docker image ls`로 조회합니다.
- **출력 경로가 없습니다.** 저장 전에 `workspace/packages` 디렉터리를 만듭니다.
- **manifest.json이 없습니다.** 일반 tar 파일이나 컨테이너 `export` 결과를 제출하지 않았는지 확인합니다.
- **Docker에 연결할 수 없습니다.** Ubuntu VM에서 Docker daemon과 사용자 권한을 `docker info`로 확인합니다.

## Cleanup : 정리와 반복

```bash
./scripts/cleanup.sh
./scripts/setup.sh
```

정리 스크립트는 문제용으로 표시된 `branch-notice:2.4.1` 이미지 태그와 `workspace/`를 제거합니다. 원본 준비 파일은 다음 실습에서 다시 복사됩니다.

이미지를 사용 중인 컨테이너가 있어 삭제가 실패하면 해당 컨테이너를 먼저 정리합니다. 스크립트는 강제 삭제를 수행하지 않습니다.

## Podman : Podman으로 풀이

Podman으로 풀이할 때는 준비·검증·정리 스크립트에도 같은 도구를 지정합니다. 아래 명령은 문제 디렉터리에서 실행합니다.

```bash
CONTAINER_TOOL=podman ./scripts/setup.sh

podman build --format docker \
  -f workspace/notice-site/Containerfile \
  -t docker.io/library/branch-notice:2.4.1 \
  workspace/notice-site

mkdir -p workspace/packages
podman save --format docker-archive \
  -o workspace/packages/branch-notice-2.4.1.tar \
  docker.io/library/branch-notice:2.4.1

CONTAINER_TOOL=podman ./scripts/verify.sh
CONTAINER_TOOL=podman ./scripts/cleanup.sh
```

빌드는 `--format docker`, 저장은 `--format docker-archive`로 형식을 지정합니다. 태그의 `docker.io/library/branch-notice:2.4.1`은 Docker에서 `branch-notice:2.4.1`과 같은 이름으로 해석됩니다. 태그 지정만으로 레지스트리에 업로드되지는 않습니다.

## References : 참고 문서

- [Docker build context](https://docs.docker.com/build/concepts/context/)
- [Docker build options](https://docs.docker.com/reference/cli/docker/buildx/build/)
- [Docker image save](https://docs.docker.com/reference/cli/docker/image/save/)
- [Docker image load](https://docs.docker.com/reference/cli/docker/image/load/)
- [Podman save](https://docs.podman.io/en/latest/markdown/podman-save.1.html)
