# Concepts: 개념 학습

`concepts/`에서는 기술 개념을 독립적으로 읽고 실습합니다. 각 디렉터리의 `README.md`는 동작 원리를 설명하고, `workout.md`는 해당 개념의 작은 실험을 제공합니다. 원하는 개념부터 시작할 수 있습니다.

## Topics: 학습 주제

| 개념 | 다루는 내용 | 실습 |
| --- | --- | --- |
| [ConfigMap](k8s/configmap/README.md) | 설정 데이터, 환경변수와 볼륨, 갱신 시점 | [Workout](k8s/configmap/workout.md) |
| [Deployment](k8s/deployment/README.md) | Pod 관리, 복제본 수 조절, rollout | [Workout](k8s/deployment/workout.md) |
| [Service](k8s/service/README.md) | selector, EndpointSlice, 포트 연결 | [Workout](k8s/service/workout.md) |
| [Secret](k8s/secret/README.md) | 데이터 형식, 환경변수와 파일 전달, TLS Secret | [Workout](k8s/secret/workout.md) |
| [TLS](networking/tls/README.md) | 프로토콜 협상, 인증서 검증, HTTPS 테스트 | [Workout](networking/tls/workout.md) |

## Workout Workflow: 훈련 방식

각 workout 안에서 준비부터 정리까지 진행합니다. 다른 workout의 리소스나 실행 결과를 이어받지 않습니다.

```text
준비 → 예측 → 실행 → 관찰 → 되짚어보기 → 검증 → 정리
```

- 1회차: 개념을 읽고 명령 힌트를 사용하여 결과를 관찰합니다.
- 2회차: 정리 후 다시 준비하고 과제만 보고 수행합니다.
- 3회차: 관찰 결과를 근거로 동작 원리를 자신의 말로 설명합니다.

리소스나 요청 결과는 명령으로 검증하고, 이해 여부는 되짚어보기 질문으로 확인합니다.

## Environment: 실습 환경

Kubernetes workout은 [공통 실행 환경](../README.md#installation-설치)의 `kind-cloud-native-dojo` context를 사용합니다. context는 접속할 클러스터를 지정하고, Namespace는 리소스의 범위를 지정합니다. 각 workout은 다음의 전용 Namespace를 사용합니다.

| Workout | Namespace | 필요한 도구 |
| --- | --- | --- |
| ConfigMap | `concept-configmap` | `kubectl` |
| Deployment | `concept-deployment` | `kubectl` |
| Service | `concept-service` | `kubectl`, `curl` |
| Secret | `concept-secret` | `kubectl`, `jq`, `openssl` |
| TLS | 사용하지 않음 | OpenSSL 3 이상, TLS 1.3을 지원하는 `curl` |

TLS workout은 로컬 OpenSSL 서버로 진행합니다. Kubernetes 클러스터가 없어도 실행할 수 있습니다.

각 workout의 `Preparation`에 적힌 디렉터리로 이동한 뒤 명령을 실행합니다. Kubernetes 예제는 해당 디렉터리의 `fixtures/`를 사용합니다. 생성 파일과 메모는 각 개념의 `workspace/`에 보관하며 Git에 저장하지 않습니다. 정리하면 이 파일도 삭제되므로 보관할 메모는 먼저 옮깁니다.

## Structure: 개념 문서 구조

```text
concepts/<topic>/<name>/
├── README.md       # 정의, 동작 원리, 예시, 되짚어보기
├── workout.md      # 자체 준비, 실험, 검증, 정리
├── fixtures/       # 실습용 원본 파일이 필요할 때 사용
└── workspace/      # 실습 중 생성되는 파일과 메모
```

각 문제의 `task.md`에는 관련 개념 링크를, `solution.md`에는 풀이와 개념이 적용되는 방식을 안내합니다. 개념 설명과 예제는 다른 문제에서도 활용할 수 있도록 작성합니다.
