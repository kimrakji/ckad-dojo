# Secret: 데이터 형식과 Pod에 전달하는 방법

Secret은 비밀번호, 토큰, 개인 키 같은 데이터를 보관하는 Kubernetes 리소스입니다. 컨테이너 이미지나 애플리케이션 코드에 데이터를 직접 넣지 않고 참조하여 사용할 수 있습니다. [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)

## Data: 데이터 표현

`data`의 값은 Base64로 표현합니다. `stringData`에는 문자열을 직접 적을 수 있고, API에 저장할 때 `data`로 변환됩니다.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-credentials
type: Opaque
stringData:
  username: student
  password: practice-only
```

위 값은 실습용 가상 데이터입니다. Base64는 암호화가 아니므로 Secret을 읽을 권한과 저장 시 보호 설정은 별도로 관리해야 합니다. [Secret 데이터 형식](https://kubernetes.io/docs/concepts/configuration/secret/#constraints-on-secret-names-and-data)

## Types: Secret 타입

| 타입 | 용도와 대표 key |
| --- | --- |
| `Opaque` | 애플리케이션이 정한 임의의 데이터 |
| `kubernetes.io/tls` | 인증서 `tls.crt`와 관련 개인 키 `tls.key` |
| `kubernetes.io/dockerconfigjson` | 이미지 레지스트리 인증 정보 `.dockerconfigjson` |

타입은 데이터의 용도와 형식을 나타냅니다. TLS Secret이 있다는 사실만으로 서버가 실행되거나 특정 TLS 버전이 허용되는 것은 아닙니다. 서버가 이 파일을 사용하도록 설정해야 합니다.

## Consumption: Pod에서 사용하는 방법

| 방식 | 연결하는 필드 | 사용 결과 |
| --- | --- | --- |
| 환경변수 한 개 | `env[].valueFrom.secretKeyRef` | 지정한 key를 환경변수로 전달 |
| 환경변수 여러 개 | `envFrom[].secretRef` | 환경변수로 사용할 수 있는 key와 값 전달 |
| 볼륨 | `volumes[].secret`과 `volumeMounts` | key별 파일로 전달 |

참조할 Secret은 Pod와 같은 Namespace에 있어야 합니다. `volumes[].secret.secretName`은 원본 Secret 이름이고, `volumeMounts[].name`은 Pod에 선언한 볼륨 이름과 연결됩니다.

환경변수는 실행 중인 Pod에서 자동 갱신되지 않습니다. 일반 Secret 볼륨은 갱신 지연 후 파일에 반영되며, `subPath` 마운트는 변경을 전달받지 않습니다. 파일이 갱신되어도 애플리케이션이 다시 읽어야 하는지는 해당 애플리케이션의 동작에 따릅니다. [Secret을 파일로 사용하기](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-files-from-a-pod)

## TLS Secret: 인증서와 개인 키

인증서·개인 키 파일이 있을 때 `kubectl create secret tls`로 TLS Secret을 만들 수 있습니다. `tls.crt`, `tls.key`를 볼륨으로 전달하면 서버가 지정한 경로에서 읽습니다. 서버의 허용 프로토콜 설정과 클라이언트의 인증서 검증은 이 데이터 전달 과정과 각각 다른 역할을 합니다.

## Review: 되짚어보기

- `data`와 `stringData`는 어떤 차이가 있을까요?
- Base64로 저장된 값을 읽을 권한이 있으면 원래 데이터를 알아낼 수 있을까요?
- TLS Secret을 생성하는 것만으로 HTTPS 서버가 시작될까요?

[Secret workout](workout.md) · [개념 목록](../../README.md)
