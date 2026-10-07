# Service: Pod 선택과 포트 연결

Service는 Pod들에 접근할 수 있는 네트워크 접점을 제공하는 Kubernetes 리소스입니다. selector가 있는 Service는 Pod label을 기준으로 연결 대상을 선택합니다. [Kubernetes Service](https://kubernetes.io/docs/concepts/services-networking/service/)

## Selection: 연결 대상 선택

다음 Service는 `app: web` label을 가진 Pod를 선택합니다. Pod나 Deployment의 리소스 이름이 `web-service`일 필요는 없습니다.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web
  ports:
    - port: 8080
      targetPort: http
```

대상 Pod에 `name: http`, `containerPort: 80`이 선언되어 있으면 Service의 8080 포트는 Pod의 80 포트로 연결됩니다. `containerPort` 선언만으로 서버가 시작되지는 않으므로 애플리케이션이 실제로 그 포트에서 요청을 받아야 합니다.

대상 주소, 포트, 준비 상태는 EndpointSlice에서 확인할 수 있습니다. selector와 일치하는 Pod가 없으면 연결할 대상도 없어집니다.

## Ports: 포트의 역할

| 필드 | 역할 |
| --- | --- |
| `port` | Service가 제공하는 포트 |
| `targetPort` | 대상 Pod의 숫자 포트 또는 이름 있는 포트 |
| `nodePort` | NodePort 타입에서 Node IP를 통해 접근할 포트 |

세 포트는 같을 필요가 없습니다. 예를 들어 Service 8080 → Pod 80으로 연결하고, NodePort는 별도 번호를 사용할 수 있습니다. [Service의 targetPort](https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service)

## Types: 노출 방식

| 타입 | 접속 방식 |
| --- | --- |
| `ClusterIP` | 클러스터 내부에서 Service IP로 접속하는 기본 타입 |
| `NodePort` | ClusterIP에 더해 Node IP의 할당된 포트로 접근 |
| `LoadBalancer` | 외부 로드밸런서와 연동하여 노출; 실제 제공 방식은 환경에 따름 |
| `ExternalName` | Service 이름을 지정한 외부 DNS 이름으로 연결 |

NodePort에서 `nodePort`를 생략하면 허용 범위 안에서 포트가 할당됩니다.

## Port Forward: 로컬에서 접속하기

```bash
kubectl --context kind-cloud-native-dojo -n example \
  port-forward service/web-service 18080:8080
```

이 예에서 `18080`은 명령을 실행한 컴퓨터의 로컬 포트이고 `8080`은 Service 포트입니다. kubectl이 Service의 대상 Pod와 `targetPort`를 찾아 터널을 만듭니다. NodePort 네트워크 경로를 거치는 접속은 아닙니다.

port-forward는 선택한 Pod를 대상으로 유지됩니다. 그 Pod가 종료되면 세션도 종료되므로 다시 실행해야 합니다. [kubectl port-forward](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_port-forward/)

## Review: 되짚어보기

- Service와 Pod의 이름이 달라도 연결되는 이유는 무엇일까요?
- Service 포트가 8080이면 애플리케이션도 반드시 8080에서 실행되어야 할까요?
- port-forward로 성공한 접속은 직접 NodePort 접속도 성공한다는 근거가 될까요?

[Service workout](workout.md) · [개념 목록](../../README.md)
