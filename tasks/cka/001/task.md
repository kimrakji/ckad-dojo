# CKA Task 001 — Update a ConfigMap to Allow TLS 1.2

**Environment:** Ubuntu VM\
**Context:** `kind-cloud-native-dojo`\
**Namespace:** `nginx-static`\
**Working directory:** `<repository>/tasks/cka/001`

## Task: 문제

An existing Deployment named `nginx-static` runs in the `nginx-static` namespace.
It uses the `nginx-config` ConfigMap to configure its HTTPS server, which currently accepts only TLS 1.3 connections.

Update `nginx-config` to allow TLS 1.2 connections. Re-create, restart, or scale resources as necessary to apply the change.

The existing HTTPS endpoint must remain available at `https://web.k8s.local:30007`.
Keep the existing Deployment, ConfigMap, Service, and TLS Secret names.

Use the local connection procedure below to test the endpoint. You may use any available tool to solve the task.

---

## Korean: 한국어 문제

`nginx-static` Namespace에 같은 이름의 Deployment가 실행 중입니다.
이 Deployment는 `nginx-config` ConfigMap으로 HTTPS 서버를 설정하며, 현재 TLS 1.3 연결만 허용합니다.

`nginx-config`를 수정하여 TLS 1.2 연결을 허용하십시오. 변경 사항을 적용하는 데 필요한 리소스 재생성, 재시작 또는 스케일 조정을 수행하십시오.

기존 HTTPS 엔드포인트 `https://web.k8s.local:30007`을 유지하십시오.
Deployment, ConfigMap, Service, TLS Secret의 기존 이름을 유지하십시오.

아래 로컬 접속 절차로 결과를 확인할 수 있습니다. 사용 가능한 도구를 자유롭게 사용해 문제를 해결하십시오.

## Test Access: 접속 테스트

원본 문제의 시험 호스트 대신 Ubuntu VM의 `kind-cloud-native-dojo` context를 사용합니다.
kind 클러스터에 접속하기 위해 별도 터미널에서 다음 명령을 실행하고 유지합니다.

```bash
kubectl --context kind-cloud-native-dojo -n nginx-static \
  port-forward service/nginx-static 30007:443
```

다른 터미널에서 TLS 1.2 접속을 확인합니다. `--resolve`는 호스트 이름을 로컬 주소로 연결하며, 시스템의 hosts 파일은 수정하지 않습니다.

```bash
curl -k --tlsv1.2 --tls-max 1.2 --noproxy '*' \
  --resolve web.k8s.local:30007:127.0.0.1 \
  https://web.k8s.local:30007
```

문제 준비 직후에는 위 요청이 실패합니다. 풀이 후에는 HTTPS 응답을 받을 수 있어야 합니다.

자동 검증은 문제 디렉터리에서 `./scripts/verify.sh`로 실행합니다.
검증 스크립트는 임시 포트로 접속하므로 위 수동 port-forward와 함께 사용할 수 있습니다.

## Related Concepts: 관련 개념

필요한 개념은 아래 문서에서 학습할 수 있습니다. 개념별 workout은 자체 환경에서 진행하므로 이 문제의 풀이 상태를 변경하지 않습니다.

- [ConfigMap: 설정 파일과 subPath](../../../concepts/k8s/configmap/README.md)
- [Deployment: Pod 관리와 설정 반영](../../../concepts/k8s/deployment/README.md)
- [Service: selector와 접속 포트](../../../concepts/k8s/service/README.md)
- [Secret: 인증서와 개인 키 전달](../../../concepts/k8s/secret/README.md)
- [TLS: 허용 프로토콜과 연결 검증](../../../concepts/networking/tls/README.md)
