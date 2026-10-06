# CKAD Dojo

`CKAD Dojo`는 CKAD(Certified Kubernetes Application Developer) 실전 연습을 위한 로컬 Kubernetes 훈련 환경입니다. `dojo(道場)`는 수련하는 도장을 의미합니다.

Ubuntu에서 `kind` 클러스터를 생성하고, 반복해서 점검·초기화·삭제할 수 있도록 환경 관리 스크립트를 제공합니다. 현재는 환경 관리 기능이 구현되어 있으며, 개별 훈련 문제와 모의시험은 아직 준비되지 않았습니다.

## Current Status : 현재 상태

- `scripts/install.sh`: 도구 설치, 셸 설정, 클러스터 생성 및 준비 상태 확인
- `scripts/check.sh`: 설치된 도구, Docker daemon, 클러스터 상태 점검
- `scripts/reset.sh`: 기존 클러스터 삭제 후 재생성
- `scripts/destroy.sh`: 클러스터 삭제
- `drills/`, `mocks/`, `notes/`: 현재 비어 있는 훈련 콘텐츠용 디렉터리

설치·초기화 스크립트는 `infra/kind.yaml`을 참조하지만, 현재 작업 트리에는 이 파일이 없습니다. 클러스터를 생성하기 전에 아래 설치 절차에 따라 설정 파일을 준비해야 합니다.

## Environment : 실행 환경

로컬 실습은 다음 구성을 기준으로 합니다. 설치 스크립트는 Ubuntu의 ARM64(`aarch64` 또는 `arm64`)와 AMD64(`x86_64`)를 지원합니다.

```text
Mac
└── UTM
    └── Ubuntu 24.04 LTS Minimal
        ├── Docker
        ├── kind / kubectl / Helm / yq
        └── CKAD Dojo
```

UTM VM 기준 구성은 CPU 2 Core, 메모리 4 GB, 디스크 30 GB입니다. 스크립트는 Ubuntu VM 안에서 일반 사용자로 실행합니다.

다음 버전은 현재 설치·초기화 스크립트에 지정된 값입니다. 실제 설치 버전과 실행 상태는 `scripts/check.sh`로 확인합니다.

| Component | Configured Version |
| --- | --- |
| Kubernetes node image | `kindest/node:v1.37.0` |
| kubectl | `v1.37.1` |
| kind | `v0.33.0` |
| Helm | `v3.22.0` |
| yq | `v4.54.1` |

Docker 버전은 고정하지 않습니다. Docker 명령이 없으면 공식 APT 저장소를 등록해 설치하고, 이미 있으면 기존 설치를 사용합니다.

클러스터 이름은 `ckad`, kubectl context는 `kind-ckad`입니다.

## Project Structure : 프로젝트 구조

```text
ckad-dojo/
├── drills/          # 개별 훈련 문제용, 현재 비어 있음
├── infra/           # kind 설정 파일 위치, 현재 비어 있음
├── mocks/           # 모의시험용, 현재 비어 있음
├── notes/           # 오답 및 반복 패턴 기록용, 현재 비어 있음
├── scripts/
│   ├── check.sh
│   ├── destroy.sh
│   ├── install.sh
│   └── reset.sh
├── .gitignore
└── README.md
```

빈 디렉터리는 Git에 저장되지 않으므로 새로 clone한 환경에는 없을 수 있습니다.

## Installation : 설치

Ubuntu VM에서 저장소를 clone합니다.

```bash
git clone https://github.com/kimrakji/ckad-dojo.git
cd ckad-dojo
```

`infra/kind.yaml`이 없다면 다음 명령으로 단일 control-plane 노드 설정을 생성합니다. 기존 설정 파일이 있으면 그대로 사용합니다.

```bash
if [ ! -f infra/kind.yaml ]; then
  mkdir -p infra
  cat > infra/kind.yaml <<'YAML'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

nodes:
  - role: control-plane
YAML
fi
```

설치 스크립트를 실행합니다. 스크립트 자체에 `sudo`를 붙이지 않으며, 필요한 작업에서만 내부적으로 `sudo`를 사용합니다.

```bash
./scripts/install.sh
```

스크립트는 다음 작업을 수행합니다.

- 기본 패키지와 Docker 설치, Docker daemon 활성화 및 사용자 그룹 설정
- 지정된 버전의 kubectl, kind, Helm, yq 설치
- `~/.bashrc`에 `k=kubectl` 별칭 및 Bash 자동완성 설정
- `infra/kind.yaml`을 사용해 `ckad` 클러스터 생성
- 기존 클러스터가 있으면 재생성 대신 kubeconfig 갱신
- `kind-ckad` context 선택 및 Node·CoreDNS 준비 상태 확인

설치 후 Bash 설정을 적용합니다.

```bash
source ~/.bashrc
```

처음 Docker 그룹에 추가된 경우 SSH 세션을 재접속해야 이후 점검·초기화 명령에서 `sudo` 없이 Docker를 사용할 수 있습니다.

## Cluster Management : 클러스터 관리

아래 스크립트도 Ubuntu VM에서 일반 사용자로 실행합니다.

### Status : 상태 확인

```bash
./scripts/check.sh
```

Docker 버전 및 daemon 연결, 도구 버전, kind 클러스터 목록, Node와 전체 Namespace의 Pod를 확인합니다. 필요한 도구와 Docker 연결이 정상인 상태에서 `ckad` 클러스터가 없으면 `Cluster not found: ckad`를 출력하고 정상 종료합니다.

Node·Pod 조회는 현재 kubectl context를 사용합니다. 다른 클러스터를 사용한 뒤에는 먼저 훈련 클러스터로 전환합니다.

```bash
kubectl config use-context kind-ckad
```

### Reset : 초기화

`infra/kind.yaml`이 준비되어 있는지 확인한 뒤 실행합니다.

```bash
test -f infra/kind.yaml && ./scripts/reset.sh
```

기존 `ckad` 클러스터와 그 안의 리소스를 삭제한 뒤 지정된 Kubernetes 버전으로 재생성합니다. 기존 클러스터가 없으면 새로 생성하며, Node와 CoreDNS가 준비될 때까지 기다립니다.

### Destroy : 삭제

```bash
./scripts/destroy.sh
```

`ckad` 클러스터를 삭제합니다. Docker와 설치된 도구는 유지하며, 클러스터가 없으면 안내 메시지를 출력하고 종료합니다. 다시 훈련하려면 설정 파일을 준비한 뒤 초기화 절차를 실행합니다.

## Next Steps : 다음 단계

- [ ] `infra/kind.yaml` 복구 또는 생성
- [ ] Drill 구조 정의 및 첫 번째 문제 작성
- [ ] 문제별 준비·검증·정리 스크립트 작성
- [ ] 오답 및 자주 사용하는 패턴 기록
- [ ] CKAD 모의시험 구성

개별 문제는 다음 흐름으로 반복할 수 있도록 구성할 예정입니다.

```text
setup → solve → verify → cleanup
```

예상 파일 구조는 다음과 같습니다. 아직 구현된 문제는 없습니다.

```text
drills/
└── 001/
    ├── task.md
    ├── setup.sh
    ├── verify.sh
    └── cleanup.sh
```
