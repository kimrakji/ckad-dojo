# Secret Workout: 문자열·환경변수·파일과 TLS Secret

가상 인증 정보를 Pod에 전달하고, 별도로 인증서와 개인 키를 TLS Secret에 담습니다. 필요한 도구는 `kubectl`, `jq`, `openssl`이며, Namespace는 `concept-secret`입니다.

## Preparation: 준비

준비된 `kind-cloud-native-dojo` 클러스터를 사용합니다. 저장소 루트에서 실행합니다.

```bash
cd concepts/k8s/secret
mkdir -p workspace
kubectl --context kind-cloud-native-dojo create namespace concept-secret
kubectl --context kind-cloud-native-dojo -n concept-secret create secret generic demo-credentials \
  --from-literal=username=student --from-literal=password=practice-only
kubectl --context kind-cloud-native-dojo -n concept-secret apply -f fixtures/pod.yaml
kubectl --context kind-cloud-native-dojo -n concept-secret \
  wait --for=condition=Ready pod/secret-reader --timeout=180s
```

Namespace가 이미 있으면 정리 후 다시 준비합니다. 예제의 인증 정보는 실습용 가상 데이터입니다.

## Set 1: 저장 형식 살펴보기

### Predict: 예측

`--from-literal`로 전달한 문자열이 API의 `data`에 어떻게 나타날지 예상합니다.

### Practice: 실행·관찰

타입과 key를 조회하고 username 값을 복원합니다.

<details>
<summary>명령 힌트</summary>

```bash
kubectl --context kind-cloud-native-dojo -n concept-secret get secret demo-credentials -o json \
  | jq '{type: .type, keys: (.data | keys), username: .data.username}'
kubectl --context kind-cloud-native-dojo -n concept-secret get secret demo-credentials \
  -o jsonpath='{.data.username}' | base64 --decode
```

</details>

### Review: 되짚어보기

타입이 `Opaque`이고 복원된 username이 `student`인지 확인합니다. Base64를 암호화로 볼 수 없는 이유를 설명합니다.

## Set 2: Pod에서 데이터 읽기

### Predict: 예측

환경변수 `DEMO_USER`와 `/etc/credentials/username`이 어떤 값을 보여줄지 적습니다.

### Practice: 실행·관찰

[Pod 예제](fixtures/pod.yaml)에서 환경변수와 볼륨 참조를 찾고 실제 값을 읽습니다.

```bash
kubectl --context kind-cloud-native-dojo -n concept-secret exec secret-reader -- printenv DEMO_USER
kubectl --context kind-cloud-native-dojo -n concept-secret exec secret-reader -- ls /etc/credentials
kubectl --context kind-cloud-native-dojo -n concept-secret exec secret-reader -- cat /etc/credentials/username
```

### Review: 되짚어보기

username 값이 두 방식으로 전달되는지 확인합니다. `secretKeyRef`와 `volumes[].secret.secretName`이 각각 어떤 연결을 만드는지 설명합니다.

## Set 3: TLS Secret 만들기

### Predict: 예측

인증서와 개인 키를 TLS Secret에 저장하면 어떤 타입과 key가 생길지 예상합니다.

### Practice: 실행·관찰

이 실습만의 자체 서명 인증서를 생성하고 TLS Secret을 만듭니다.

```bash
(
  umask 077
  openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
    -subj '/CN=secret-demo.local' \
    -keyout workspace/tls.key -out workspace/tls.crt
)
kubectl --context kind-cloud-native-dojo -n concept-secret create secret tls demo-tls \
  --cert=workspace/tls.crt --key=workspace/tls.key
kubectl --context kind-cloud-native-dojo -n concept-secret get secret demo-tls -o json \
  | jq '{type: .type, keys: (.data | keys)}'
```

### Review: 되짚어보기

타입이 `kubernetes.io/tls`이고 key가 `tls.crt`, `tls.key`인지 확인합니다. 이 세트는 데이터 저장까지만 수행합니다. 인증서를 서버에서 사용하려면 어떤 연결이 더 필요한지 설명합니다.

## Verification: 검증

Pod의 데이터 전달과 TLS Secret 형식을 검사합니다.

```bash
test "$(kubectl --context kind-cloud-native-dojo -n concept-secret exec secret-reader -- printenv DEMO_USER)" = student
test "$(kubectl --context kind-cloud-native-dojo -n concept-secret exec secret-reader -- cat /etc/credentials/username)" = student
kubectl --context kind-cloud-native-dojo -n concept-secret get secret demo-tls -o json \
  | jq -e '.type == "kubernetes.io/tls" and (.data | has("tls.crt") and has("tls.key"))'
```

## Cleanup: 정리

개념 디렉터리에서 실행합니다.

```bash
kubectl --context kind-cloud-native-dojo delete namespace concept-secret --wait=true --timeout=120s
rm -rf -- workspace
```

[개념 설명](README.md) · [개념 목록](../../README.md)
