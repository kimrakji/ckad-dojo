# CKA Task 001 Solution: ConfigMap의 TLS 설정 변경

## Preparation: 준비

저장소 루트에서 문제를 준비합니다.

```bash
./tasks/cka/001/scripts/setup.sh
cd tasks/cka/001
```

## Solution: 풀이

ConfigMap의 현재 설정을 확인하고 편집합니다.

```bash
kubectl --context kind-cloud-native-dojo -n nginx-static \
  get configmap nginx-config -o yaml

kubectl --context kind-cloud-native-dojo -n nginx-static \
  edit configmap nginx-config
```

`data.default.conf` 안의 프로토콜 설정을 다음과 같이 변경합니다.

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
```

Deployment를 재시작하여 변경된 설정을 적용합니다.

```bash
kubectl --context kind-cloud-native-dojo -n nginx-static \
  rollout restart deployment/nginx-static

kubectl --context kind-cloud-native-dojo -n nginx-static \
  rollout status deployment/nginx-static --timeout=180s
```

## Key Points: 핵심

- `ssl_protocols`는 Nginx가 허용하는 TLS 버전을 지정합니다.
- 이 문제는 ConfigMap 파일을 `subPath`로 마운트합니다. 기존 Pod에는 ConfigMap 변경이 자동 반영되지 않으므로 Pod를 다시 생성해야 합니다.
- ConfigMap 수정과 실행 중인 서버에 적용하는 작업을 모두 완료해야 합니다.
- `--tlsv1.2`와 `--tls-max 1.2`를 함께 사용하면 TLS 1.2로 접속을 확인할 수 있습니다.
- `-k`는 실습용 자체 서명 인증서의 검증을 생략합니다.

```text
ConfigMap 수정 → Pod 재생성 → Nginx 설정 적용 → TLS 1.2 접속 확인
```

## Verify and Cleanup: 검증·정리

```bash
./scripts/verify.sh
```

성공하면 `CKA Task 001 complete.`가 출력됩니다. 수동으로 실행한 port-forward는 `Ctrl+C`로 종료합니다.
다시 연습하려면 문제 Namespace와 작업 파일을 정리한 뒤 준비합니다.

```bash
./scripts/cleanup.sh
./scripts/setup.sh
```

## References: 참고 문서

- 제공된 `2-1 task-configmap (2).pdf`의 ConfigMap·TLS 문제를 로컬 kind 환경에 맞게 구성했습니다.
- [Kubernetes ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Nginx ssl_protocols](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_protocols)
- [curl TLS options](https://curl.se/docs/manpage.html#--tls-max)
