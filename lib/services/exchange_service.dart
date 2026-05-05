import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';

class ExchangeRatesSnapshot {
  const ExchangeRatesSnapshot({
    required this.rates,
    required this.fetchedAt,
    required this.fromCache,
  });

  final Map<String, double> rates;
  final DateTime fetchedAt;
  final bool fromCache;

  double rateFor(String currency) => rates[currency.toUpperCase()] ?? 0;
}

class ExchangeService {
  ExchangeService(this._dio, this._prefs);

  final Dio _dio;
  final SharedPreferences _prefs;

  static const _cacheKey = 'exchange_rates_cache_v1';
  static const _cacheDateKey = 'exchange_rates_cache_date_v1';
  static const supportedCurrencies = <String>[
    'KRW',
    'USD',
    'JPY',
    'EUR',
    'THB',
    'VND',
    'CNY',
    'TWD',
    'HKD',
    'SGD',
    'GBP',
    'AUD',
  ];

  Future<ExchangeRatesSnapshot> getRates() async {
    final cached = _readCache();
    final isFresh =
        cached != null &&
        DateTime.now().difference(cached.fetchedAt) < const Duration(hours: 24);

    if (Env.exchangeApiKey.isEmpty) {
      return cached ??
          ExchangeRatesSnapshot(
            rates: const {},
            fetchedAt: DateTime.fromMillisecondsSinceEpoch(0),
            fromCache: true,
          );
    }

    if (isFresh) {
      return cached;
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://v6.exchangerate-api.com/v6/${Env.exchangeApiKey}/latest/KRW',
      );
      final body = response.data ?? <String, dynamic>{};
      final rawRates = body['conversion_rates'] as Map<String, dynamic>? ?? {};
      final rates = <String, double>{};
      for (final currency in supportedCurrencies) {
        final value = rawRates[currency];
        if (value is num) {
          rates[currency] = value.toDouble();
        }
      }
      final snapshot = ExchangeRatesSnapshot(
        rates: rates,
        fetchedAt: DateTime.now(),
        fromCache: false,
      );
      await _writeCache(snapshot);
      return snapshot;
    } catch (_) {
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  double convertToKrw({
    required double originalAmount,
    required String currency,
    required ExchangeRatesSnapshot snapshot,
  }) {
    final rate = snapshot.rateFor(currency);
    if (currency.toUpperCase() == 'KRW') {
      return originalAmount;
    }
    if (rate <= 0) {
      return 0;
    }
    return originalAmount / rate;
  }

  ExchangeRatesSnapshot? _readCache() {
    final rawJson = _prefs.getString(_cacheKey);
    final rawDate = _prefs.getString(_cacheDateKey);
    if (rawJson == null || rawDate == null) {
      return null;
    }

    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    return ExchangeRatesSnapshot(
      rates: decoded.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      fetchedAt: DateTime.tryParse(rawDate) ?? DateTime.now(),
      fromCache: true,
    );
  }

  Future<void> _writeCache(ExchangeRatesSnapshot snapshot) async {
    await _prefs.setString(_cacheKey, jsonEncode(snapshot.rates));
    await _prefs.setString(_cacheDateKey, snapshot.fetchedAt.toIso8601String());
  }
}
