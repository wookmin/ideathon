# 멈칫 (TripReceipt)

> 영수증 OCR · 실시간 환율 변환 · 카드 동기화로 여행 경비를 자동으로 정리하는 Flutter 앱

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-Express-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![Firestore](https://img.shields.io/badge/Firestore-Cloud-FFCA28?logo=firebase&logoColor=white)](https://firebase.google.com/products/firestore)

---

## ✨ 주요 기능

| 기능           | 설명                                                      |
| -------------- | --------------------------------------------------------- |
| 🧾 영수증 OCR  | 카메라/갤러리로 촬영한 영수증에서 자동으로 항목·금액 추출 |
| 💱 환율 변환   | 여행지 통화 → 원화 실시간 환산                            |
| 💳 카드 동기화 | 카드사 승인내역 자동 수집                                 |
| 📊 소비 분석   | 카테고리별 지출, 예산 대비 페이스, AI 인사이트 제공       |
| 🗺️ 여행 관리   | 여러 여행을 만들고 전환하며 가계부를 분리 관리            |

## 🏗️ 아키텍처

```
┌─────────────────┐      HTTPS       ┌──────────────────────┐      OAuth/RSA      ┌────────────┐
│  Flutter App     │ ───────────────▶ │  Node/Express Backend │ ───────────────────▶ │   카드사 API   │
│  (lib/)          │ ◀─────────────── │  (backend/)            │ ◀─────────────────── │              │
└─────────────────┘                  └──────────────────────┘                       └────────────┘
                                              │
                                              ▼
                                   Firestore (Cloud Run)
```

앱은 카드사 API 비밀키를 직접 다루지 않고, 백엔드가 OAuth 토큰 발급·비밀번호 RSA 암호화·승인내역 정규화를 대신 처리합니다.

## 📁 폴더 구조

```
.
├── lib/                  # Flutter 앱
│   ├── screens/          # 화면 단위 위젯
│   ├── widgets/          # 공용 위젯
│   ├── providers/        # Riverpod 상태 관리
│   ├── models/           # 데이터 모델
│   └── config/           # 테마, 환경 설정
├── backend/               # Node/Express 백엔드 (CODEF 프록시)
│   ├── src/modules/cards/ # 카드 연결·동기화 도메인 로직
│   └── README.md          # 백엔드 상세 문서
└── README.md
```

## 🚀 시작하기

### 1. Flutter 앱 실행

```bash
flutter pub get
flutter run
```

로컬 백엔드에 연결하려면 `--dart-define`으로 base URL을 지정합니다.

```bash
flutter run --dart-define=BACKEND_BASE_URL=http://127.0.0.1:4000
```

| 디바이스           | Base URL                |
| ------------------ | ----------------------- |
| iOS 시뮬레이터     | `http://127.0.0.1:4000` |
| Android 에뮬레이터 | `http://10.0.2.2:4000`  |
| 실제 기기          | `http://<맥-IP>:4000`   |

### 2. 백엔드 실행

```bash
cd backend
cp .env.example .env
npm install
npm run dev
```

기본 포트는 `4000`이며, `.env`에 CODEF 인증 정보(`CODEF_CLIENT_ID`, `CODEF_CLIENT_SECRET`, `CODEF_PUBLIC_KEY`)를 채워야 합니다. 엔드포인트, 배포, 보안 등 자세한 내용은 [backend/README.md](backend/README.md)를 참고하세요.

## 🧰 기술 스택

- **Frontend**: Flutter, Riverpod, Hive(로컬 캐시), Google Maps
- **Backend**: Node.js, Express, TypeScript, Zod
- **외부 연동**: CODEF(카드사 데이터), Firestore, Google Places

## 📌 참고

- CODEF 공식 문서: [developer.codef.io](https://developer.codef.io/)
- 백엔드 상세 가이드: [backend/README.md](backend/README.md)
