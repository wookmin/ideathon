import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/exchange_service.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return SharedPreferences.getInstance();
});

final exchangeServiceProvider = FutureProvider<ExchangeService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return ExchangeService(ref.watch(dioProvider), prefs);
});

final exchangeRatesProvider = FutureProvider<ExchangeRatesSnapshot>((
  ref,
) async {
  final service = await ref.watch(exchangeServiceProvider.future);
  return service.getRates();
});
