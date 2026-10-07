# CKA Task 100 — Create and Scale a Deployment

**Environment:** Ubuntu VM\
**Difficulty:** EASY\
**Context:** `kind-cloud-native-dojo`\
**Namespace:** `cka-100`\
**Working directory:** `<repository>/tasks/cka/100`

## Task: 문제

This playground introduces creating, viewing, and scaling a Deployment.
The setup script prepares the namespace and a manifest at `workspace/deployment.yaml`.
The manifest defines `playground-web`, using `nginx:1.30.5-alpine` with one replica.

Follow the commands below and observe the output after each step.

1. Create the Deployment and wait for its Pod to become ready.

   ```bash
   kubectl --context kind-cloud-native-dojo -n cka-100 apply -f workspace/deployment.yaml
   kubectl --context kind-cloud-native-dojo -n cka-100 rollout status deployment/playground-web --timeout=180s
   ```

2. View the Deployment and its Pod. Confirm that the Deployment shows `READY 1/1`.

   ```bash
   kubectl --context kind-cloud-native-dojo -n cka-100 get deployment playground-web
   kubectl --context kind-cloud-native-dojo -n cka-100 get pods -l app=playground-web
   ```

3. Increase the replicas to three, wait for the change, and repeat the view commands from step 2. Confirm `READY 3/3` and three ready Pods.

   ```bash
   kubectl --context kind-cloud-native-dojo -n cka-100 scale deployment/playground-web --replicas=3
   kubectl --context kind-cloud-native-dojo -n cka-100 rollout status deployment/playground-web --timeout=180s
   ```

Run `./scripts/verify.sh` to check the final state.

---

## Korean: 한국어 문제

Deployment를 생성하고, 조회하고, 복제본 수를 바꿔보는 플레이그라운드입니다.
준비 스크립트는 Namespace와 `workspace/deployment.yaml`을 준비합니다.
예제에는 `nginx:1.30.5-alpine` 이미지를 사용하는 `playground-web` Deployment와 복제본 1개가 정의되어 있습니다.

아래 명령을 따라 실행하면서 단계별 출력을 확인합니다.

1. Deployment를 생성하고 Pod가 준비될 때까지 기다립니다.

   ```bash
   kubectl --context kind-cloud-native-dojo -n cka-100 apply -f workspace/deployment.yaml
   kubectl --context kind-cloud-native-dojo -n cka-100 rollout status deployment/playground-web --timeout=180s
   ```

2. Deployment와 Pod를 조회합니다. Deployment의 `READY`가 `1/1`이고 Pod가 1개인지 확인합니다.

   ```bash
   kubectl --context kind-cloud-native-dojo -n cka-100 get deployment playground-web
   kubectl --context kind-cloud-native-dojo -n cka-100 get pods -l app=playground-web
   ```

3. 복제본 수를 3개로 늘리고 변경이 완료될 때까지 기다립니다. 2번 조회 명령을 다시 실행하여 `READY 3/3`과 준비된 Pod 3개를 확인합니다.

   ```bash
   kubectl --context kind-cloud-native-dojo -n cka-100 scale deployment/playground-web --replicas=3
   kubectl --context kind-cloud-native-dojo -n cka-100 rollout status deployment/playground-web --timeout=180s
   ```

`./scripts/verify.sh`로 최종 상태를 검증합니다. 검증 스크립트는 앞선 조회 과정을 기록하지 않으므로, 단계별 출력은 직접 비교합니다.
같은 실습을 반복하려면 `./scripts/cleanup.sh`와 `./scripts/setup.sh`를 순서대로 실행합니다.

## Related Concepts: 관련 개념

- [Deployment: 복제본 수와 Pod 관리](../../../concepts/k8s/deployment/README.md)
- [Deployment Workout: 소유 관계와 Pod 교체 관찰](../../../concepts/k8s/deployment/workout.md)

[한국어 해설](solution.md)
