# Deployment Workout: 복제본 수와 Pod 교체 관찰

Nginx Deployment 하나로 소유 관계, scaling, rollout을 비교합니다. 필요한 도구는 `kubectl`이며, Namespace는 `concept-deployment`입니다.

## Preparation: 준비

준비된 `kind-cloud-native-dojo` 클러스터를 사용합니다. 저장소 루트에서 실행합니다.

```bash
cd concepts/k8s/deployment
mkdir -p workspace
kubectl --context kind-cloud-native-dojo create namespace concept-deployment
kubectl --context kind-cloud-native-dojo -n concept-deployment apply -f fixtures/deployment.yaml
kubectl --context kind-cloud-native-dojo -n concept-deployment \
  rollout status deployment/demo-web --timeout=180s
```

Namespace가 이미 있으면 정리 후 다시 준비합니다. 초기 replicas는 2이고 Service나 ConfigMap은 사용하지 않습니다.

## Set 1: 소유 관계와 Pod 복구

### Predict: 예측

Pod 하나를 삭제하면 Deployment, ReplicaSet, Pod 중 어떤 리소스가 새로 만들어질지 예상합니다.

### Practice: 실행·관찰

소유 관계를 조회한 뒤 Pod 하나를 삭제하고 복제본 수가 다시 2가 되는지 확인합니다.

<details>
<summary>명령 힌트</summary>

```bash
kubectl --context kind-cloud-native-dojo -n concept-deployment get deployment demo-web -o jsonpath='{.metadata.uid}{"\n"}'
kubectl --context kind-cloud-native-dojo -n concept-deployment get replicasets -l app=deployment-demo \
  -o custom-columns='NAME:.metadata.name,REPLICAS:.spec.replicas,OWNER:.metadata.ownerReferences[0].name'
kubectl --context kind-cloud-native-dojo -n concept-deployment get pods -l app=deployment-demo \
  -o custom-columns='NAME:.metadata.name,UID:.metadata.uid,OWNER:.metadata.ownerReferences[0].name'

DEPLOYMENT_DEMO_POD=$(kubectl --context kind-cloud-native-dojo -n concept-deployment \
  get pods -l app=deployment-demo -o jsonpath='{.items[0].metadata.name}')
kubectl --context kind-cloud-native-dojo -n concept-deployment delete pod "$DEPLOYMENT_DEMO_POD"
kubectl --context kind-cloud-native-dojo -n concept-deployment \
  rollout status deployment/demo-web --timeout=180s
```

</details>

### Review: 되짚어보기

조회 명령을 반복하고 대체 Pod의 이름과 UID를 확인합니다. 기존 ReplicaSet과 Deployment는 유지되면서 Pod가 다시 만들어지는 이유를 설명합니다.

## Set 2: 복제본 수 늘리기

### Predict: 예측

2개에서 3개로 늘릴 때 새로운 ReplicaSet과 rollout revision이 필요할지 예상합니다.

### Practice: 실행·관찰

현재 ReplicaSet 이름과 revision을 기록하고 scaling 전후를 비교합니다.

```bash
kubectl --context kind-cloud-native-dojo -n concept-deployment rollout history deployment/demo-web
kubectl --context kind-cloud-native-dojo -n concept-deployment scale deployment/demo-web --replicas=3
kubectl --context kind-cloud-native-dojo -n concept-deployment \
  rollout status deployment/demo-web --timeout=180s
kubectl --context kind-cloud-native-dojo -n concept-deployment get replicasets,pods -l app=deployment-demo
kubectl --context kind-cloud-native-dojo -n concept-deployment rollout history deployment/demo-web
```

### Review: 되짚어보기

기존 ReplicaSet의 replicas가 3으로 늘고 revision은 유지되는지 확인합니다. scaling이 Pod template 변경과 다른 이유를 설명합니다.

## Set 3: rollout restart로 Pod 교체하기

### Predict: 예측

이미지를 바꾸지 않고 재시작해도 새 ReplicaSet이 만들어질지 예상합니다.

### Practice: 실행·관찰

Set 1의 Pod UID를 다시 기록하고 재시작 후 비교합니다.

```bash
kubectl --context kind-cloud-native-dojo -n concept-deployment rollout restart deployment/demo-web
kubectl --context kind-cloud-native-dojo -n concept-deployment \
  rollout status deployment/demo-web --timeout=180s
kubectl --context kind-cloud-native-dojo -n concept-deployment get replicasets,pods -l app=deployment-demo
kubectl --context kind-cloud-native-dojo -n concept-deployment rollout history deployment/demo-web
kubectl --context kind-cloud-native-dojo -n concept-deployment get deployment demo-web \
  -o jsonpath='{.spec.template.metadata.annotations.kubectl\.kubernetes\.io/restartedAt}{"\n"}'
```

### Review: 되짚어보기

새 ReplicaSet과 revision을 확인합니다. 완료 후 이전 ReplicaSet의 replicas는 0이고 새 ReplicaSet은 3입니다. Pod UID는 바뀌고 Deployment UID는 유지되는지 확인합니다.

## Verification: 검증

원하는 복제본 수와 업데이트 상태를 확인합니다.

```bash
kubectl --context kind-cloud-native-dojo -n concept-deployment rollout status deployment/demo-web --timeout=180s
kubectl --context kind-cloud-native-dojo -n concept-deployment get deployment demo-web \
  -o custom-columns='DESIRED:.spec.replicas,UPDATED:.status.updatedReplicas,READY:.status.readyReplicas,AVAILABLE:.status.availableReplicas'
```

네 값이 모두 3인지 확인하고, scaling과 restart 전후의 ReplicaSet·revision 차이를 설명합니다.

## Cleanup: 정리

개념 디렉터리에서 실행합니다.

```bash
kubectl --context kind-cloud-native-dojo delete namespace concept-deployment --wait=true --timeout=120s
rm -rf -- workspace
```

[개념 설명](README.md) · [개념 목록](../../README.md)
