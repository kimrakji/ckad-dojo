# Cloud Native Dojo

`Cloud Native Dojo`는 CKAD(Certified Kubernetes Application Developer) 실전 문제를 출발점으로 컨테이너와 Kubernetes 등 클라우드 네이티브 기술을 반복 실습하는 학습 저장소입니다. `dojo(道場)`는 수련하는 도장을 의미합니다.

문제는 `tasks/ckad/`, `tasks/cka/`처럼 시험·학습 주제별로 분류하고, 각 문제를 독립적인 실습 단위로 관리합니다. 준비된 환경에서 직접 풀이하고, 결과를 검증한 뒤 정리하여 다시 연습합니다. 해설에는 풀이 명령과 핵심 개념을 간결하게 남깁니다.

현재 Ubuntu 기반 환경 관리 스크립트와 첫 번째 컨테이너 이미지 빌드·저장 문제가 준비되어 있습니다. 환경 관리 스크립트는 `kind` 클러스터의 생성·점검·초기화·삭제를 담당합니다.

## Current Status : 현재 상태

- `infra/scripts/install.sh`: 도구 설치, 셸 설정, 클러스터 생성 및 준비 상태 확인
- `infra/scripts/check.sh`: 설치된 도구, Docker daemon, 클러스터 상태 점검
- `infra/scripts/reset.sh`: 기존 클러스터 삭제 후 재생성
- `infra/scripts/destroy.sh`: 클러스터 삭제
- `tasks/ckad/001/`: 컨테이너 이미지 빌드·저장 문제, 준비·검증·정리 스크립트 및 한국어 해설
- `tasks/cka/`: CKA 실습 문제 추가 예정

설치·초기화 스크립트는 `infra/kind.yaml`을 사용해 단일 control-plane 노드 클러스터를 생성합니다.

## Environment : 실행 환경

로컬 실습은 다음 구성을 기준으로 합니다. 설치 스크립트는 Ubuntu의 ARM64(`aarch64` 또는 `arm64`)와 AMD64(`x86_64`)를 지원합니다.

```text
Mac
└── UTM
    └── Ubuntu 24.04 LTS Minimal
        ├── Docker
        ├── kind / kubectl / Helm / yq
        └── Cloud Native Dojo
```

UTM VM 기준 구성은 CPU 2 Core, 메모리 4 GB, 디스크 30 GB입니다. 스크립트는 Ubuntu VM 안에서 일반 사용자로 실행합니다.

다음 버전은 현재 설치·초기화 스크립트에 지정된 값입니다. 실제 설치 버전과 실행 상태는 `infra/scripts/check.sh`로 확인합니다.

| Component | Configured Version |
| --- | --- |
| Kubernetes node image | `kindest/node:v1.37.0` |
| kubectl | `v1.37.1` |
| kind | `v0.33.0` |
| Helm | `v3.22.0` |
| yq | `v4.54.1` |

Docker 버전은 고정하지 않습니다. Docker 명령이 없으면 공식 APT 저장소를 등록해 설치하고, 이미 있으면 기존 설치를 사용합니다.

현재 환경 관리 스크립트의 클러스터 이름은 `ckad`, kubectl context는 `kind-ckad`입니다.

## Project Structure : 프로젝트 구조

```text
cloud-native-dojo/
├── infra/
│   ├── kind.yaml
│   └── scripts/     # 공통 실습 환경 관리
│       ├── check.sh
│       ├── destroy.sh
│       ├── install.sh
│       └── reset.sh
├── tasks/           # 시험·학습 주제별 훈련 문제
│   ├── ckad/
│   │   └── 001/
│   └── cka/         # 실습 문제 추가 예정
├── .gitignore
└── README.md
```

## Installation : 설치

Ubuntu VM에서 저장소를 clone합니다.

```bash
git clone https://github.com/kimrakji/cloud-native-dojo.git
cd cloud-native-dojo
```

설치 스크립트를 실행합니다. 스크립트 자체에 `sudo`를 붙이지 않으며, 필요한 작업에서만 내부적으로 `sudo`를 사용합니다.

```bash
./infra/scripts/install.sh
```

스크립트는 다음 작업을 수행합니다.

- 기본 패키지와 Docker 설치, Docker daemon 활성화 및 사용자 그룹 설정
- 지정된 버전의 kubectl, kind, Helm, yq 설치
- `~/.bashrc`에 `k=kubectl` 별칭 및 Bash 자동완성 설정
- `infra/kind.yaml`과 지정된 Kubernetes 이미지로 `ckad` 클러스터 생성
- 기존 클러스터가 있으면 재생성 대신 kubeconfig 갱신
- `kind-ckad` context 선택 및 Node·CoreDNS 준비 상태 확인

설치 후 Bash 설정을 적용합니다.

```bash
source ~/.bashrc
```

처음 Docker 그룹에 추가된 경우 SSH 세션을 재접속해야 이후 점검·초기화 명령에서 `sudo` 없이 Docker를 사용할 수 있습니다.

## Cluster Management : 클러스터 관리

아래 스크립트도 Ubuntu VM에서 일반 사용자로 실행합니다.

스크립트는 파일로 실행합니다. 본문을 터미널에 직접 붙여넣거나 `source`로 실행하면 스크립트의 종료 설정이 현재 셸에 적용되어 SSH 세션까지 종료될 수 있습니다.

### Status : 상태 확인

```bash
./infra/scripts/check.sh
```

Docker 버전 및 daemon 연결, 도구 버전, kind 클러스터 목록, Node와 전체 Namespace의 Pod를 확인합니다. 필요한 도구와 Docker 연결이 정상인 상태에서 `ckad` 클러스터가 없으면 `Cluster not found: ckad`를 출력하고 정상 종료합니다.

Node·Pod 조회는 현재 kubectl context를 사용합니다. 다른 클러스터를 사용한 뒤에는 먼저 훈련 클러스터로 전환합니다.

```bash
kubectl config use-context kind-ckad
```

### Reset : 초기화

```bash
./infra/scripts/reset.sh
```

기존 `ckad` 클러스터와 그 안의 리소스를 삭제한 뒤 지정된 Kubernetes 버전으로 재생성합니다. 기존 클러스터가 없으면 새로 생성하며, Node와 CoreDNS가 준비될 때까지 기다립니다.

### Destroy : 삭제

```bash
./infra/scripts/destroy.sh
```

`ckad` 클러스터를 삭제합니다. Docker와 설치된 도구는 유지하며, 클러스터가 없으면 안내 메시지를 출력하고 종료합니다. 다시 훈련하려면 초기화 절차를 실행합니다.

## Task Workflow : 반복 실습

각 문제는 `tasks/<track>/<number>/` 아래에서 다음 구조를 사용합니다. `<track>`은 `ckad`, `cka`처럼 시험·학습 주제를 나타내며, 문제 번호는 각 분류 안에서 관리합니다. 문제별 `scripts/`는 준비·검증·정리를 담당하고, `fixtures/`는 준비 파일 원본을 보관합니다. 풀이와 생성 결과는 `workspace/`에서 관리하며 Git에 저장하지 않습니다.

```text
tasks/ckad/001/
├── task.md                    # 상단 영문·하단 한글 문제
├── solution.md                # 한국어 풀이·해설
├── scripts/
│   ├── setup.sh
│   ├── verify.sh
│   └── cleanup.sh
├── fixtures/                  # 준비 파일 원본
└── workspace/                 # 실습 중 생성
```

저장소 루트에서 첫 번째 CKAD 문제를 준비합니다.

```bash
./tasks/ckad/001/scripts/setup.sh
cd tasks/ckad/001
```

[CKAD Task 001](tasks/ckad/001/task.md)을 읽고 직접 풀이한 뒤 검증합니다.

```bash
./scripts/verify.sh
```

풀이 후 [한국어 해설](tasks/ckad/001/solution.md)에서 풀이 명령과 핵심 개념을 확인할 수 있습니다. 문제 디렉터리에서는 터미널로 읽을 수 있습니다.

```bash
less solution.md
```

다시 연습하려면 문제 디렉터리에서 정리 후 준비합니다. 준비 스크립트는 기존 풀이 결과가 있으면 덮어쓰지 않고 종료합니다.

```bash
./scripts/cleanup.sh
./scripts/setup.sh
```

검증에는 Docker, `jq`, `tar`, `gzip`, SHA-256 도구가 필요합니다. Ubuntu 환경 설치 스크립트에서 필요한 패키지를 설치합니다. Podman으로 풀이할 때는 준비·검증·정리 명령에 `CONTAINER_TOOL=podman`을 지정합니다.

## Next Steps : 다음 단계

- [x] Task 구조 정의 및 첫 번째 문제 작성
- [x] 문제별 준비·검증·정리 스크립트 작성
- [ ] 컨테이너·Kubernetes 등 주제별 실습 문제 추가
- [ ] CKA 실습 문제 추가
- [ ] 오답 및 자주 사용하는 패턴 기록
- [ ] CKAD 모의시험 구성

개별 문제는 다음 흐름으로 반복합니다.

```text
setup → solve → verify → cleanup
```
