# TripReceipt CODEF Backend

Flutter 앱이 CODEF를 직접 호출하지 않도록 중간 백엔드를 두는 구조입니다.

## What this backend does

- CODEF OAuth 토큰 발급 및 캐시
- 카드사 계정 연결 요청 프록시
- 승인내역 조회 및 앱 친화적 거래 포맷으로 정규화
- 연결/거래 조회용 REST API 제공
- 개발 단계에서는 인메모리 저장소 사용

## Endpoints

- `GET /health`
- `GET /api/v1/card/connections`
- `POST /api/v1/card/connections`
- `DELETE /api/v1/card/connections/:connectionId`
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
- `connectedId`는 서버에서만 저장하고, 여기서는 간단히 대칭 암호화 후 메모리에 보관합니다.
- 카드사 ID/PW는 저장하지 않고 연결 생성 요청 시에만 사용합니다.

## CODEF references

- Official developer docs: [developer.codef.io](https://developer.codef.io/)
- Official Node references: [codef-io/codef-node](https://github.com/codef-io/codef-node)

공식 샘플 기준으로 `access_token`은 재사용을 권장하고, 개발 환경은 `sandbox`, `development`, `production` 으로 구분됩니다.
