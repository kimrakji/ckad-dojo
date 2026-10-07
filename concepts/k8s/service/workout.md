# Service Workout: selector와 서로 다른 포트 확인

HTTP 서버 Pod와 NodePort Service로 대상 선택과 접속 경로를 관찰합니다. 필요한 도구는 `kubectl`, `curl`이며, Namespace는 `concept-service`입니다.

## Preparation: 준비

준비된 `kind-cloud-native-dojo` 클러스터를 사용합니다. 저장소 루트에서 실행합니다.

```bash
cd concepts/k8s/service
mkdir -p workspace
kubectl --context kind-cloud-native-dojo create namespace concept-service
kubectl --context kind-cloud-native-dojo -n concept-service apply -f fixtures/resources.yaml
kubectl --context kind-cloud-native-dojo -n concept-service \
  wait --for=condition=Ready pod/service-web --timeout=180s
```

Namespace가 이미 있으면 정리 후 다시 준비합니다. Service 포트는 8080, Pod 포트는 80이며 NodePort 번호는 클러스터가 할당합니다.

## Set 1: Service에서 Pod까지 추적하기

### Predict: 예측

이름이 다른 `web-service`와 `service-web`이 연결되는 이유와 실제 요청을 받을 포트를 예상합니다.

### Practice: 실행·관찰

Service, Pod label, EndpointSlice를 조회합니다.

<details>
<summary>명령 힌트</summary>

```bash
kubectl --context kind-cloud-native-dojo -n concept-service get service web-service -o yaml
kubectl --context kind-cloud-native-dojo -n concept-service get pod service-web --show-labels
kubectl --context kind-cloud-native-dojo -n concept-service get pod service-web -o yaml
kubectl --context kind-cloud-native-dojo -n concept-service \
  get endpointslices -l kubernetes.io/service-name=web-service -o yaml
```

</details>

### Review: 되짚어보기

selector와 Pod label의 `app: service-demo`를 확인합니다. EndpointSlice의 대상이 `service-web`이고 포트가 80인지 확인합니다. 할당된 NodePort 번호도 기록합니다.

## Set 2: 로컬 포트로 접속하기

### Predict: 예측

`18080:8080`이 각각 어느 위치의 포트인지 예상합니다. 로컬 포트를 고르면 NodePort 번호도 바뀔지 생각합니다.

### Practice: 실행·관찰

별도 터미널에서 실행하고 유지합니다.

```bash
kubectl --context kind-cloud-native-dojo -n concept-service \
  port-forward service/web-service 18080:8080
```

같은 컴퓨터의 요청용 터미널에서 접속합니다.

```bash
curl --fail --show-error --noproxy '*' --connect-timeout 5 --max-time 10 http://127.0.0.1:18080
```

### Review: 되짚어보기

Nginx의 기본 HTTP 페이지를 확인합니다. 로컬 18080 → Service 8080을 기준으로 선택된 Pod 80으로 연결되는 경로를 설명합니다. Service를 다시 조회하여 NodePort가 기록과 같은지 확인합니다.

## Set 3: selector가 맞지 않을 때 관찰하기

### Predict: 예측

selector만 바꾸면 Pod 자체도 삭제될지, EndpointSlice의 대상은 어떻게 바뀔지 예상합니다.

### Practice: 실행·관찰

수동 port-forward를 `Ctrl+C`로 종료합니다. selector를 바꾸고 Pod와 EndpointSlice를 조회합니다. 대상 정보가 갱신될 때까지 잠시 뒤 다시 조회할 수 있습니다.

```bash
kubectl --context kind-cloud-native-dojo -n concept-service \
  patch service web-service --type=merge -p '{"spec":{"selector":{"app":"missing"}}}'
kubectl --context kind-cloud-native-dojo -n concept-service get pod service-web
kubectl --context kind-cloud-native-dojo -n concept-service \
  get endpointslices -l kubernetes.io/service-name=web-service -o yaml
```

관찰 후 selector를 원래 값으로 복구합니다.

```bash
kubectl --context kind-cloud-native-dojo -n concept-service \
  patch service web-service --type=merge -p '{"spec":{"selector":{"app":"service-demo"}}}'
```

### Review: 되짚어보기

Pod는 유지되지만 Service의 연결 대상이 없어졌다가 복구되는지 확인합니다. Service가 Pod를 생성·삭제하는 역할을 하지 않는다는 점을 설명합니다.

## Verification: 검증

selector 복구 후 EndpointSlice에 준비된 대상이 있는지 확인합니다. Set 2의 port-forward를 다시 실행하고 `curl --fail` 요청이 성공하는지 확인합니다.

## Cleanup: 정리

port-forward를 `Ctrl+C`로 종료한 뒤 개념 디렉터리에서 실행합니다.

```bash
kubectl --context kind-cloud-native-dojo delete namespace concept-service --wait=true --timeout=120s
rm -rf -- workspace
```

[개념 설명](README.md) · [개념 목록](../../README.md)
