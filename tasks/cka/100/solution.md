# CKA Task 100 Solution: Deployment 생성과 복제본 수 변경

## Preparation: 준비

공통 클러스터가 준비된 Ubuntu VM의 저장소 루트에서 실행합니다. 필요한 도구는 `kubectl`과 `jq`입니다.

```bash
./tasks/cka/100/scripts/setup.sh
cd tasks/cka/100
```

준비 스크립트는 `cka-100` Namespace와 작업용 YAML을 준비합니다. Deployment는 직접 생성합니다.

## Solution: 풀이

예제를 적용하고 초기 상태를 조회합니다.

```bash
kubectl --context kind-cloud-native-dojo -n cka-100 apply -f workspace/deployment.yaml
kubectl --context kind-cloud-native-dojo -n cka-100 rollout status deployment/playground-web --timeout=180s
kubectl --context kind-cloud-native-dojo -n cka-100 get deployment playground-web
kubectl --context kind-cloud-native-dojo -n cka-100 get pods -l app=playground-web
```

Deployment의 `READY`가 `1/1`인 것을 확인한 뒤 복제본 수를 늘립니다.

```bash
kubectl --context kind-cloud-native-dojo -n cka-100 scale deployment/playground-web --replicas=3
kubectl --context kind-cloud-native-dojo -n cka-100 rollout status deployment/playground-web --timeout=180s
kubectl --context kind-cloud-native-dojo -n cka-100 get deployment playground-web
kubectl --context kind-cloud-native-dojo -n cka-100 get pods -l app=playground-web
```

최종적으로 `READY 3/3`과 준비된 Pod 3개가 보입니다.

## Explanation: 해설

- `apply -f`는 YAML의 정의를 클러스터에 반영합니다. 첫 실행에서는 Deployment를 생성합니다.
- `get`은 현재 리소스 상태를 조회합니다.
- `scale --replicas=3`은 Deployment가 유지할 복제본 수를 3으로 변경합니다.
- `rollout status`는 원하는 상태가 반영될 때까지 기다립니다. 명령 직후에는 Pod가 아직 준비 중일 수 있습니다.

`scale`은 클러스터의 값을 바꾸며 `workspace/deployment.yaml`을 수정하지 않습니다. 이 예제 파일을 다시 적용하면 복제본 수가 파일에 적힌 1로 돌아갑니다. [Kubernetes Deployment 문서](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#replicas)

[Deployment 개념](../../../concepts/k8s/deployment/README.md)에서 복제본 수와 Pod 관리 원리를 학습할 수 있습니다.

## Review: 되짚어보기

- `get`과 `scale` 중 클러스터의 상태를 바꾸는 명령은 무엇일까요?
- 복제본 수를 바꾼 직후에 `READY 3/3`이 보이지 않을 수 있는 이유는 무엇일까요?
- 예제 파일을 다시 적용하면 복제본 수는 어떻게 될까요?

## Verify and Cleanup: 검증·정리

```bash
./scripts/verify.sh
```

검증은 지정된 이미지, 복제본 수 3, 최신 설정이 반영된 준비 상태를 확인합니다.
성공하면 `CKA Task 100 complete.`가 출력됩니다. 실습을 마치면 정리합니다.

```bash
./scripts/cleanup.sh
```
