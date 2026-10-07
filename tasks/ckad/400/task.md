# Task 400 — Build and Package a Container Image

**Environment:** Ubuntu VM\
**Difficulty:** MEDIUM\
**Working directory:** `<repository>/tasks/ckad/400`

## Task

An offline deployment package is required for a branch information service.

A container build file has been prepared at:

```text
workspace/notice-site/Containerfile
```

All required application files are available in the same directory.

Complete the following tasks:

1. Using the provided build file and application files, build a container image with:
   - **Name:** `branch-notice`
   - **Tag:** `2.4.1`
2. Save the built image in **Docker image archive format** at:

   ```text
   workspace/packages/branch-notice-2.4.1.tar
   ```

   Create the destination directory if it does not exist.

The archive must contain the image layers and metadata required to restore the image as `branch-notice:2.4.1`.

Use any available tool to complete the task. Do not modify the provided build file or application files.

---

## 한국어 — 컨테이너 이미지 빌드 및 패키징

**실행 환경:** Ubuntu VM\
**난이도:** MEDIUM\
**작업 디렉터리:** `<repository>/tasks/ckad/400`

지점 안내 서비스를 오프라인으로 배포하기 위한 패키지가 필요합니다.

컨테이너 빌드 파일이 다음 경로에 준비되어 있습니다.

```text
workspace/notice-site/Containerfile
```

필요한 애플리케이션 파일은 모두 같은 디렉터리에 있습니다.

다음 작업을 수행하십시오.

1. 제공된 빌드 파일과 애플리케이션 파일을 사용하여 다음 이름과 태그로 컨테이너 이미지를 빌드하십시오.
   - **이름:** `branch-notice`
   - **태그:** `2.4.1`
2. 빌드한 이미지를 **Docker 이미지 아카이브 형식**으로 다음 경로에 저장하십시오.

   ```text
   workspace/packages/branch-notice-2.4.1.tar
   ```

   대상 디렉터리가 없으면 생성하십시오.

아카이브에는 이미지를 `branch-notice:2.4.1`로 복원하는 데 필요한 이미지 레이어와 메타데이터가 포함되어야 합니다.

사용 가능한 도구를 자유롭게 사용해 작업을 완료하십시오. 제공된 빌드 파일과 애플리케이션 파일은 수정하지 마십시오.
