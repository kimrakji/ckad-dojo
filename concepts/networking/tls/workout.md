# TLS Workout: 허용 버전과 인증서 신뢰 비교

로컬 OpenSSL 서버 하나로 TLS 1.2·1.3 연결과 인증서 검증을 실험합니다. OpenSSL 3 이상과 TLS 1.3을 지원하는 `curl`이 필요합니다. 클러스터나 컨테이너는 사용하지 않습니다. Ubuntu VM에서 서버용·요청용 터미널 두 개를 준비합니다.

## Preparation: 준비

두 터미널 모두 저장소 루트에서 다음 디렉터리로 이동합니다.

```bash
cd concepts/networking/tls
```

한 터미널에서 실습용 인증서를 만듭니다. SAN에 접속 이름 `tls-demo.local`을 포함합니다.

```bash
mkdir -p workspace
(
  umask 077
  openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
    -subj '/CN=tls-demo.local' \
    -addext 'subjectAltName=DNS:tls-demo.local' \
    -keyout workspace/tls.key -out workspace/tls.crt
)
```

OpenSSL의 `s_server`는 테스트용 TLS 서버입니다. `-www`는 연결 정보를 담은 HTTP 응답을 제공합니다. [OpenSSL s_server](https://docs.openssl.org/3.0/man1/openssl-s_server/)

## Set 1: TLS 1.3만 허용하기

### Predict: 예측

같은 주소에 TLS 1.2와 TLS 1.3만 사용하는 요청을 보내면 각각 어떤 결과가 나올지 예상합니다.

### Practice: 실행·관찰

서버용 터미널에서 실행하고 유지합니다. `ACCEPT` 안내를 확인합니다.

```bash
openssl s_server -accept 127.0.0.1:18443 \
  -cert workspace/tls.crt -key workspace/tls.key -www -tls1_3
```

요청용 터미널에서 두 요청을 실행합니다. 이 세트는 인증서 검증을 생략하여 버전 협상 결과를 비교합니다.

```bash
curl --fail --show-error -k --tlsv1.2 --tls-max 1.2 --noproxy '*' \
  --connect-timeout 5 --max-time 10 \
  --resolve tls-demo.local:18443:127.0.0.1 https://tls-demo.local:18443

curl --fail --show-error -k --tlsv1.3 --tls-max 1.3 --noproxy '*' \
  --connect-timeout 5 --max-time 10 \
  --resolve tls-demo.local:18443:127.0.0.1 https://tls-demo.local:18443
```

### Review: 되짚어보기

TLS 1.2 요청은 연결 수립에 실패하고 TLS 1.3 요청은 HTML 응답을 받는지 확인합니다. `-k`가 있어도 첫 요청이 실패하는 이유를 설명합니다.

클라이언트가 TLS 1.3 옵션을 지원하지 않는다는 오류는 서버 설정과 구분합니다. `curl --version`으로 사용 중인 TLS 구현을 확인합니다.

## Set 2: TLS 1.2와 TLS 1.3 허용하기

### Predict: 예측

인증서와 주소를 유지하고 허용 버전만 바꾸면 어떤 요청 결과가 달라질지 예상합니다.

### Practice: 실행·관찰

서버용 터미널에서 `Ctrl+C`로 종료한 뒤 두 버전을 허용하여 다시 실행합니다.

```bash
openssl s_server -accept 127.0.0.1:18443 \
  -cert workspace/tls.crt -key workspace/tls.key -www \
  -min_protocol TLSv1.2 -max_protocol TLSv1.3
```

요청용 터미널에서 Set 1의 두 요청을 반복합니다.

### Review: 되짚어보기

두 버전 모두 HTML 응답을 받는지 확인합니다. 인증서가 같은데도 버전별 결과가 달라진 이유를 설명합니다.

## Set 3: 인증서 검증하기

### Predict: 예측

`-k`를 제거한 요청과 생성한 인증서를 `--cacert`로 신뢰하는 요청의 결과를 예상합니다.

### Practice: 실행·관찰

서버는 Set 2 상태로 유지합니다. 요청용 터미널에서 인증서를 별도 지정하지 않고 접속합니다. 자체 서명 인증서를 기본 신뢰 목록에 등록하지 않았다면 검증에 실패합니다.

```bash
curl --fail --show-error --tlsv1.2 --tls-max 1.2 --noproxy '*' \
  --connect-timeout 5 --max-time 10 \
  --resolve tls-demo.local:18443:127.0.0.1 https://tls-demo.local:18443
```

이번에는 생성한 인증서를 신뢰하도록 지정합니다.

```bash
curl --fail --show-error --cacert workspace/tls.crt \
  --tlsv1.2 --tls-max 1.2 --noproxy '*' --connect-timeout 5 --max-time 10 \
  --resolve tls-demo.local:18443:127.0.0.1 https://tls-demo.local:18443
```

### Review: 되짚어보기

두 요청 모두 같은 TLS 버전을 사용하지만 인증서 신뢰 설정에 따라 결과가 달라지는지 확인합니다. SAN과 접속 이름 `tls-demo.local`의 관계도 설명합니다.

## Verification: 검증

Set 2 서버에 아래 두 요청을 보냅니다. 인증서 검증을 유지하면서 두 TLS 버전 모두 HTTP 200을 받으면 완료입니다.

```bash
curl --fail --silent --show-error --cacert workspace/tls.crt \
  --tlsv1.2 --tls-max 1.2 --noproxy '*' --connect-timeout 5 --max-time 10 \
  --resolve tls-demo.local:18443:127.0.0.1 \
  -o /dev/null -w '%{http_code}\n' https://tls-demo.local:18443

curl --fail --silent --show-error --cacert workspace/tls.crt \
  --tlsv1.3 --tls-max 1.3 --noproxy '*' --connect-timeout 5 --max-time 10 \
  --resolve tls-demo.local:18443:127.0.0.1 \
  -o /dev/null -w '%{http_code}\n' https://tls-demo.local:18443
```

## Cleanup: 정리

서버용 터미널에서 `Ctrl+C`로 종료합니다. 개념 디렉터리에서 생성 파일을 삭제합니다.

```bash
rm -rf -- workspace
```

[개념 설명](README.md) · [개념 목록](../../README.md)
