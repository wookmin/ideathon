import 'package:flutter/foundation.dart';

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

  static String get backendBaseUrl {
    const configured = String.fromEnvironment(
      'BACKEND_BASE_URL',
      defaultValue: '',
    );
    if (configured.isNotEmpty) {
      return configured;
    }
    return kIsWeb ? '' : 'http://127.0.0.1:4000';
  }
}
