# ConfigMap: 설정 데이터와 사용 방식

ConfigMap은 비밀 정보가 아닌 설정을 key-value 형태로 보관하는 Kubernetes 리소스입니다. 설정을 컨테이너 이미지에서 분리하여 같은 이미지를 다른 설정으로 실행할 수 있습니다. [Kubernetes ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)

## Data: 설정 데이터

`data`는 문자열을 저장하고, `binaryData`는 바이너리 데이터를 Base64로 표현하여 저장합니다. 다음은 간단한 문자열 설정 예입니다.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  message: hello
  app.properties: |
    mode=development
    log.level=info
```

`message`와 `app.properties`는 데이터의 key입니다. key 이름에 확장자를 붙여도 그 자체로 파일이 만들어지는 것은 아닙니다. Pod에서 볼륨으로 사용하면 key가 파일 이름이 되고 값이 파일 내용으로 제공됩니다.

## Consumption: Pod에서 사용하는 방법

| 방식 | 연결하는 필드 | 컨테이너에서 보이는 형태 |
| --- | --- | --- |
| 환경변수 한 개 | `env[].valueFrom.configMapKeyRef` | 지정한 key의 값 |
| 환경변수 여러 개 | `envFrom[].configMapRef` | 환경변수로 사용할 수 있는 key와 값 |
| 디렉터리 마운트 | `volumes[].configMap`과 `volumeMounts` | key별 파일 |
| 파일 하나 마운트 | 위 볼륨과 `volumeMounts[].subPath` | 선택한 파일 하나 |

Pod가 참조하는 ConfigMap은 같은 Namespace에 있어야 합니다. 볼륨의 `name`은 Pod 내부에서 연결할 이름이고, `configMap.name`은 원본 리소스 이름입니다.

`mountPath`는 컨테이너에 보일 경로입니다. `subPath`는 볼륨 내부에서 선택할 경로입니다. `readOnly: true`는 컨테이너에서 마운트 파일을 수정하지 못하게 하며, API에서 ConfigMap을 편집하는 작업과는 별개입니다.

## Updates: 설정 변경이 반영되는 시점

| 사용 방식 | 실행 중인 Pod에 대한 변경 반영 |
| --- | --- |
| 환경변수 | 자동 갱신되지 않음 |
| 일반 볼륨의 디렉터리 | kubelet의 갱신 과정을 거쳐 반영되므로 지연될 수 있음 |
| `subPath` 마운트 | ConfigMap 변경을 전달받지 않음 |

이 차이는 같은 설정 값을 세 방식으로 전달하여 비교할 수 있습니다. [ConfigMap 갱신 동작](https://kubernetes.io/docs/concepts/configuration/configmap/#mounted-configmaps-are-updated-automatically)

ConfigMap의 값을 바꾸는 작업만으로 Pod가 다시 생성되지는 않습니다. 환경변수나 `subPath` 파일에 새 값을 전달하려면 Pod를 교체하는 등의 처리가 필요합니다. 일반 볼륨의 파일이 갱신되어도 애플리케이션이 다시 읽어야 실행 중인 동작이 바뀝니다. 다시 읽는 방법은 애플리케이션마다 다릅니다.

로컬 원본 파일을 수정하는 것과 API에 저장된 ConfigMap을 수정하는 것도 구분합니다. 원본 파일을 편집했다면 리소스에 적용하는 과정이 필요합니다.

## Review: 되짚어보기

- 이미지에 설정을 넣는 대신 ConfigMap을 사용하면 어떤 점이 편리할까요?
- 같은 값을 환경변수와 파일로 전달하면 변경 후 어떤 차이가 생길까요?
- 파일 내용이 바뀌었다는 사실만으로 애플리케이션 적용까지 확인할 수 있을까요?

[ConfigMap workout](workout.md) · [개념 목록](../../README.md)
