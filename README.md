# ideathon

TripReceipt Flutter prototype with receipt OCR, exchange-rate conversion, and CODEF-backed card sync.

## Run the Flutter app

```bash
flutter run
```

If you want to connect the app to the local backend, pass the backend base URL with `--dart-define`.

```bash
flutter run --dart-define=BACKEND_BASE_URL=http://127.0.0.1:4000
```

Examples by device:

- iOS simulator: `http://127.0.0.1:4000`
- Android emulator: `http://10.0.2.2:4000`
- Physical device: `http://<your-mac-ip>:4000`

## Run the backend

```bash
cd backend
cp .env.example .env
npm install
npm run dev
```
