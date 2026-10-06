# Task 001 Solution : 컨테이너 이미지 빌드·저장 해설

## Preparation : 준비

저장소 루트에서 실행합니다.

```bash
./tasks/ckad/001/scripts/setup.sh
cd tasks/ckad/001
```

## Solution : 풀이

문제 디렉터리에서 이미지를 빌드하고 Docker 이미지 아카이브로 저장합니다.

```bash
docker build \
  -f workspace/notice-site/Containerfile \
  -t branch-notice:2.4.1 \
  workspace/notice-site

mkdir -p workspace/packages

docker image save \
  -o workspace/packages/branch-notice-2.4.1.tar \
  branch-notice:2.4.1
```

## Key Points : 핵심

- `-f`: 빌드 파일명이 `Containerfile`이므로 경로를 지정합니다.
- `-t`: 요구한 이미지 이름과 태그를 지정합니다.
- 마지막 인수: `COPY`가 파일을 읽을 빌드 컨텍스트입니다.
- `-o`: 아카이브의 출력 경로를 지정합니다.

이미지를 저장할 때는 `save`를 사용합니다. `export`는 컨테이너의 파일 시스템을 저장합니다. 이미지 복원에는 `load`를 사용합니다.

```text
준비 파일 --build--> 이미지 --save--> 아카이브 --load--> 이미지
```

## Verify and Cleanup : 검증·정리

```bash
./scripts/verify.sh
```

성공하면 `Task 001 complete.`가 출력됩니다. 실습을 마치면 정리합니다.

```bash
./scripts/cleanup.sh
```

## References : 참고 문서

- [Docker build](https://docs.docker.com/reference/cli/docker/buildx/build/)
- [Docker image save](https://docs.docker.com/reference/cli/docker/image/save/)
