# TripReceipt CODEF Backend

Flutter 앱이 CODEF를 직접 호출하지 않도록 중간 백엔드를 두는 구조입니다.

## What this backend does

- CODEF OAuth 토큰 발급 및 캐시
- 카드사 계정 연결 요청 프록시
- CODEF `public_key` 기반 비밀번호 RSA 암호화
- 승인내역 조회 및 앱 친화적 거래 포맷으로 정규화
- 연결/거래 조회용 REST API 제공
- 개발 단계에서는 인메모리 저장소 사용

## Endpoints

- `GET /health`
- `GET /api/v1/card/connections`
- `POST /api/v1/card/connections`
- `DELETE /api/v1/card/connections/:connectionId`
- `GET /api/v1/card/connections/:connectionId/cards`
- `POST /api/v1/card/connections/:connectionId/sync`
- `GET /api/v1/transactions`

## Quick start

```bash
cd backend
cp .env.example .env
npm install
npm run dev
```

기본 포트는 `4000` 입니다.

`backend/.env`에는 CODEF 데모 화면에서 받은 아래 값을 넣어야 합니다.

- `CODEF_CLIENT_ID`
- `CODEF_CLIENT_SECRET`
- `CODEF_PUBLIC_KEY`

## Deploy on Cloud Run

이 서버는 Cloud Run에 맞게 `PORT` 환경변수를 사용합니다. 루트 URL은 Flutter 앱의 `cloudBackendBaseUrl`에 이미 Cloud Run 주소로 설정되어 있습니다.

1. `backend/cloudrun-env.yaml`을 만듭니다. 이 파일은 git에 올리지 않습니다.

```yaml
NODE_ENV: production
ALLOWED_ORIGINS: ""
CODEF_ENV: development
CODEF_CLIENT_ID: "..."
CODEF_CLIENT_SECRET: "..."
CODEF_PUBLIC_KEY: "..."
APP_ENCRYPTION_SECRET: "..."
GOOGLE_PLACES_API_KEY: "..."
```

2. Cloud Run에 배포합니다.

```bash
gcloud run deploy tripreceipt-backend \
  --source backend \
  --region asia-northeast3 \
  --allow-unauthenticated \
  --min-instances 1 \
  --env-vars-file backend/cloudrun-env.yaml
```

3. 배포 후 헬스체크를 확인합니다.

```bash
curl https://tripreceipt-backend-593945546381.asia-northeast3.run.app/health
```

응답이 `{ "ok": true }`이면 정상입니다.

Cloud Run URL이 바뀌면 Flutter 실행/빌드 때 아래처럼 지정하거나 `lib/config/env.dart`의 `cloudBackendBaseUrl`을 교체합니다.

```bash
flutter run --dart-define=BACKEND_BASE_URL=https://<cloud-run-url>
```

릴리즈 빌드도 같은 값을 넘기면 됩니다.

```bash
flutter build ios --dart-define=BACKEND_BASE_URL=https://<cloud-run-url>
```

## Temporary auth model

MVP 기준으로 간단히 `x-user-id` 헤더를 사용합니다.

예시:

```bash
curl -H "x-user-id: demo-user" http://localhost:4000/api/v1/card/connections
```

실서비스에서는 Firebase Auth 또는 자체 JWT 검증 미들웨어로 교체하세요.

## Example: create a connection

```bash
curl -X POST http://localhost:4000/api/v1/card/connections \
  -H "Content-Type: application/json" \
  -H "x-user-id: demo-user" \
  -d '{
    "organization": "0301",
    "organizationName": "하나카드",
    "loginType": "1",
    "credentials": {
      "id": "user-id",
      "password": "user-password"
    }
  }'
```

## Example: sync transactions

```bash
curl -X POST http://localhost:4000/api/v1/card/connections/<connection-id>/sync \
  -H "Content-Type: application/json" \
  -H "x-user-id: demo-user" \
  -d '{
    "startDate": "20250101",
    "endDate": "20250131"
  }'
```

## Storage notes

- 지금은 인메모리 저장소라 서버 재시작 시 데이터가 사라집니다.
- 구조는 Postgres 교체를 염두에 두고 `repository` 인터페이스로 분리했습니다.

## Security notes

- `CODEF_CLIENT_SECRET`는 절대 Flutter 앱에 넣지 않습니다.
- `CODEF_PUBLIC_KEY`는 계정 연결 시 카드사 비밀번호를 RSA 암호화하는 데 사용합니다.
- `connectedId`는 서버에서만 저장하고, 여기서는 간단히 대칭 암호화 후 메모리에 보관합니다.
- 카드사 ID/PW는 저장하지 않고 연결 생성 요청 시에만 사용합니다.

## CODEF references

- Official developer docs: [developer.codef.io](https://developer.codef.io/)
- Official Node references: [codef-io/codef-node](https://github.com/codef-io/codef-node)

공식 샘플 기준으로 `access_token`은 재사용을 권장하고, 개발 환경은 `sandbox`, `development`, `production` 으로 구분됩니다.
