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

  static const configuredBackendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: '',
  );

  static const cloudBackendBaseUrl =
      'https://tripreceipt-backend-593945546381.asia-northeast3.run.app';

  static const localBackendBaseUrls = [
    'http://imin-ug-ui-MacBookAir.local:4000',
    'http://localhost:4000',
    'http://127.0.0.1:4000',
  ];

  static List<String> get backendBaseUrlCandidates {
    final configured = configuredBackendBaseUrl.trim();
    return [
      if (configured.isNotEmpty) configured,
      ...localBackendBaseUrls,
      cloudBackendBaseUrl,
    ];
  }

  static String get backendBaseUrl {
    final configured = configuredBackendBaseUrl.trim();
    return configured.isNotEmpty ? configured : cloudBackendBaseUrl;
  }
}
