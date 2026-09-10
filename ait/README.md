# 멈칫 앱인토스 번들

이 폴더는 기존 Flutter Web 빌드 결과를 앱인토스 WebView `.ait` 번들로 패키징합니다.

## 준비

`apps-in-toss.config.ts`의 `appName`을 앱인토스 콘솔에 등록한 실제 appName으로 변경합니다.

## 빌드

```bash
npm install
npm run build
```

빌드가 성공하면 이 폴더에 `<appName>.ait`가 생성됩니다.

## 배포

`ait/.env.local`의 `AIT_CONSOLE_API_KEY`에 앱인토스 콘솔에서 발급한 콘솔 API 키를 입력한 뒤 실행합니다.

```bash
npm run deploy
```

콘솔 API 키는 `.ait` 번들에 포함되지 않고 배포 명령에서만 사용됩니다.

## 포함된 앱인토스 브리지

`src/ait-bridge.ts`는 Flutter Web에서 사용할 수 있도록 다음 기능을 `window.aitBridge`로 노출합니다.

- `openCamera()`
- `getPhotos()`
- `getLocation()`
- `authorizeTossPay(payToken)`
- `login()`

토스페이 결제 생성·승인·상태 조회 API는 보안상 백엔드에서 구현해야 합니다. 현재 백엔드에는 토스페이 가맹점 키와 결제 라우트가 없으므로, 이 번들은 토스페이 결제창 브리지까지만 준비합니다.
