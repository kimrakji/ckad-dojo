# ConfigMap Workout: 환경변수와 파일의 갱신 비교

하나의 ConfigMap 값을 환경변수, 디렉터리, `subPath` 파일로 전달하고 변경 시점을 비교합니다. 필요한 도구는 `kubectl`이며, 이 workout의 Namespace는 `concept-configmap`입니다.

## Preparation: 준비

저장소 루트에서 이동합니다. 클러스터는 `kind-cloud-native-dojo` context에 준비되어 있어야 합니다.

```bash
cd concepts/k8s/configmap
mkdir -p workspace
kubectl --context kind-cloud-native-dojo create namespace concept-configmap
kubectl --context kind-cloud-native-dojo -n concept-configmap apply -f fixtures/configmap.yaml
kubectl --context kind-cloud-native-dojo -n concept-configmap apply -f fixtures/pod.yaml
kubectl --context kind-cloud-native-dojo -n concept-configmap \
  wait --for=condition=Ready pod/config-reader --timeout=180s
```

Namespace가 이미 있으면 이 문서의 정리 절차를 수행한 뒤 다시 준비합니다. 예제 Pod는 BusyBox로 파일과 환경변수를 읽는 용도입니다. 별도 애플리케이션 설정은 필요하지 않습니다.

## Set 1: 같은 값을 세 방식으로 읽기

### Predict: 예측

`MESSAGE`, `/etc/config/message`, `/etc/single/message.txt`가 각각 어떤 값을 보여줄지 적습니다.

### Practice: 실행·관찰

[Pod 예제](fixtures/pod.yaml)에서 세 전달 방식을 찾고 값을 읽습니다. Pod UID도 기록합니다.

<details>
<summary>명령 힌트</summary>

```bash
kubectl --context kind-cloud-native-dojo -n concept-configmap get configmap demo-config -o yaml
kubectl --context kind-cloud-native-dojo -n concept-configmap exec config-reader -- printenv MESSAGE
kubectl --context kind-cloud-native-dojo -n concept-configmap exec config-reader -- cat /etc/config/message
kubectl --context kind-cloud-native-dojo -n concept-configmap exec config-reader -- cat /etc/single/message.txt
kubectl --context kind-cloud-native-dojo -n concept-configmap get pod config-reader -o jsonpath='{.metadata.uid}{"\n"}'
```

</details>

### Review: 되짚어보기

세 값이 모두 `hello-v1`인지 확인합니다. `configMapKeyRef`, `mountPath`, `subPath`가 각각 어떤 연결을 만드는지 설명합니다.

## Set 2: ConfigMap 값만 바꾸기

### Predict: 예측

값을 `hello-v2`로 바꾼 뒤 세 전달 방식과 Pod UID 중 무엇이 바뀔지 예상합니다.

### Practice: 실행·관찰

ConfigMap을 변경하고 Set 1의 조회를 반복합니다.

```bash
kubectl --context kind-cloud-native-dojo -n concept-configmap \
  patch configmap demo-config --type=merge -p '{"data":{"message":"hello-v2"}}'
```

디렉터리 마운트에는 갱신 지연이 있으므로 잠시 뒤 다시 조회합니다. 이 세트에서는 Pod를 교체하지 않습니다.

### Review: 되짚어보기

| 관찰 대상 | 갱신 후 예상 결과 |
| --- | --- |
| API의 `data.message` | `hello-v2` |
| 환경변수 `MESSAGE` | `hello-v1` |
| `/etc/config/message` | `hello-v2` |
| `/etc/single/message.txt` | `hello-v1` |
| Pod UID | 변경 전과 동일 |

왜 디렉터리의 파일만 갱신되는지 설명합니다. 오래 기다려도 예상과 다르면 Pod의 마운트 방식과 실제 ConfigMap 값을 다시 확인합니다.

## Set 3: Pod를 교체하기

### Predict: 예측

같은 이름으로 Pod를 다시 만들면 UID와 세 값이 어떻게 달라질지 예상합니다.

### Practice: 실행·관찰

Pod만 삭제하고 [Pod 예제](fixtures/pod.yaml)로 다시 만듭니다. `configmap.yaml`은 다시 적용하지 않습니다. 적용하면 `hello-v1`으로 돌아갑니다.

```bash
kubectl --context kind-cloud-native-dojo -n concept-configmap delete pod config-reader
kubectl --context kind-cloud-native-dojo -n concept-configmap apply -f fixtures/pod.yaml
kubectl --context kind-cloud-native-dojo -n concept-configmap \
  wait --for=condition=Ready pod/config-reader --timeout=180s
```

### Review: 되짚어보기

Set 1의 조회를 반복합니다. UID가 바뀌고 세 값이 모두 `hello-v2`가 되는지 확인합니다. Pod 이름이 같아도 새 리소스라는 점을 설명합니다.

## Verification: 검증

세 값을 직접 검사합니다. 모두 일치하면 명령이 성공합니다.

```bash
test "$(kubectl --context kind-cloud-native-dojo -n concept-configmap exec config-reader -- printenv MESSAGE)" = hello-v2
test "$(kubectl --context kind-cloud-native-dojo -n concept-configmap exec config-reader -- cat /etc/config/message)" = hello-v2
test "$(kubectl --context kind-cloud-native-dojo -n concept-configmap exec config-reader -- cat /etc/single/message.txt)" = hello-v2
```

## Cleanup: 정리

현재 개념 디렉터리에서 실행합니다. Namespace의 실습 리소스와 로컬 생성 파일을 삭제합니다.

```bash
kubectl --context kind-cloud-native-dojo delete namespace concept-configmap --wait=true --timeout=120s
rm -rf -- workspace
```

[개념 설명](README.md) · [개념 목록](../../README.md)
