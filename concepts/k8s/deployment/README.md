# Deployment: Pod 관리와 업데이트

Deployment는 원하는 Pod 상태를 선언하고 ReplicaSet을 통해 Pod를 관리하는 Kubernetes 리소스입니다. 복제본 수를 유지하고 Pod template 변경에 따라 업데이트를 진행합니다. [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

## Ownership: Deployment·ReplicaSet·Pod 관계

```text
Deployment web
└── ReplicaSet web-<hash>
    ├── Pod web-<hash>-<suffix>
    └── Pod web-<hash>-<suffix>
```

Deployment는 ReplicaSet을 관리하고, ReplicaSet은 원하는 수의 Pod를 유지합니다. Pod 하나가 삭제되면 ReplicaSet이 대체 Pod를 생성합니다. 같은 Pod 안의 컨테이너가 재시작되는 것과 Pod 자체가 교체되는 것은 구분해야 합니다. Pod가 교체되면 UID가 바뀝니다.

`metadata.ownerReferences`를 조회하면 이 소유 관계를 확인할 수 있습니다.

## Specification: 원하는 상태 선언

| 필드 | 역할 |
| --- | --- |
| `spec.replicas` | 원하는 Pod 수 |
| `spec.selector` | 관리할 Pod를 식별하는 label 조건 |
| `spec.template.metadata.labels` | 새 Pod에 붙일 label |
| `spec.template.spec` | 새 Pod의 컨테이너·볼륨 등 실행 구성 |

selector는 template의 label과 일치해야 합니다. Deployment 이름이 어떤 Pod를 관리하는지 결정하는 것은 아닙니다.

## Scaling: 복제본 수 조절

`kubectl scale`로 replicas를 바꾸면 해당 개수에 맞춰 Pod가 늘거나 줄어듭니다. Pod template을 바꾸지 않는 scaling은 새 rollout revision을 만들지 않습니다. [Deployment scaling과 revision](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#rolling-back-a-deployment)

예를 들어 같은 template으로 2개에서 3개로 늘리면 기존 ReplicaSet이 추가 Pod를 만듭니다.

## Rollout: Pod template 변경

이미지, 환경변수, annotation 등 `spec.template`이 바뀌면 rollout이 시작됩니다. 기본 `RollingUpdate` 전략은 새 ReplicaSet을 늘리고 기존 ReplicaSet을 줄이며 Pod를 교체합니다. `maxSurge`와 `maxUnavailable`로 전환 중 복제본 수를 조절할 수 있습니다.

외부 ConfigMap이나 Secret의 데이터만 수정하면 Deployment의 template은 그대로입니다. 따라서 그 수정 자체가 rollout을 시작하지는 않습니다.

`kubectl rollout restart`는 template의 `kubectl.kubernetes.io/restartedAt` annotation을 갱신하여 Pod 교체를 유도합니다. Deployment 자체를 삭제하는 명령은 아닙니다. [Kubernetes restartedAt annotation](https://kubernetes.io/docs/reference/labels-annotations-taints/#kubectl-kubernetes-io-restartedat)

## Status: 업데이트 상태 확인

`kubectl rollout status`로 업데이트 완료를 기다립니다. 이어서 Pod, ReplicaSet, 애플리케이션 응답을 확인합니다. readiness probe가 검사하는 범위에 따라 애플리케이션의 모든 기능이 정상이라는 의미까지 포함하지는 않습니다.

## Review: 되짚어보기

- Pod를 삭제하면 누가 대체 Pod를 만들까요?
- replicas 변경과 이미지 변경은 ReplicaSet에 어떤 차이를 만들까요?
- `rollout restart`가 Pod template을 바꾸는 이유는 무엇일까요?

## Related Tasks: 관련 문제

- [CKA 100 · EASY: Deployment 생성·조회·스케일링](../../../tasks/cka/100/task.md)
- [CKA 400 · MEDIUM: ConfigMap 변경 후 Deployment 재시작](../../../tasks/cka/400/task.md)

[Deployment workout](workout.md) · [개념 목록](../../README.md)
