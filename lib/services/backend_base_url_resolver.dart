import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';

class BackendBaseUrlResolver {
  BackendBaseUrlResolver(this._dio);

  final Dio _dio;

  static const _cacheKey = 'backend_base_url_v1';
  static const _probeTimeout = Duration(seconds: 2);

  Future<String> resolve() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    final candidates = _dedupe([
      if (cached != null && cached.isNotEmpty) cached,
      ...Env.backendBaseUrlCandidates,
    ]);

    for (final candidate in candidates) {
      final baseUrl = _normalize(candidate);
      if (await _isHealthy(baseUrl)) {
        await prefs.setString(_cacheKey, baseUrl);
        debugPrint('Backend selected: $baseUrl');
        return baseUrl;
      }
    }

    throw StateError('사용 가능한 백엔드를 찾지 못했어요. 확인한 주소: ${candidates.join(', ')}');
  }

  List<String> _dedupe(List<String> values) {
    final seen = <String>{};
    return [
      for (final value in values)
        if (seen.add(_normalize(value))) _normalize(value),
    ];
  }

  String _normalize(String value) => value.trim().replaceAll(RegExp(r'/$'), '');

  Future<bool> _isHealthy(String baseUrl) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '$baseUrl/health',
        options: Options(
          sendTimeout: _probeTimeout,
          receiveTimeout: _probeTimeout,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return response.statusCode == 200 && response.data?['ok'] == true;
    } catch (error) {
      debugPrint('Backend probe failed for $baseUrl: $error');
      return false;
    }
  }
}
