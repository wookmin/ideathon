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
  static const backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://127.0.0.1:4000',
  );
}
