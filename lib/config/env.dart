import 'env_local.dart' as local;

class Env {
  static const geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: local.geminiApiKey,
  );

  static const exchangeApiKey = String.fromEnvironment(
    'EXCHANGE_API_KEY',
    defaultValue: local.exchangeApiKey,
  );

  /// 추가
  static const googlePlacesApiKey = String.fromEnvironment(
    'GOOGLE_PLACES_API_KEY',
    defaultValue: local.mapKey,
  );

  static const backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue:
        'https://tripreceipt-backend-593945546381.asia-northeast3.run.app/',
  );
}
