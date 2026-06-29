import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/card_account.dart';
import '../models/card_connection.dart';
import '../models/card_transaction.dart';
import 'backend_base_url_resolver.dart';

class FinancialApiService {
  FinancialApiService(this._dio, this._prefs)
    : _baseUrlResolver = BackendBaseUrlResolver(_dio);

  final Dio _dio;
  final SharedPreferences _prefs;
  final BackendBaseUrlResolver _baseUrlResolver;

  static const _userIdKey = 'financial_api_user_id_v1';

  Future<String> get _baseUrl => _baseUrlResolver.resolve();

  Future<List<CardConnection>> listConnections() async {
    final baseUrl = await _baseUrl;
    final response = await _request(
      () => _dio.get<Map<String, dynamic>>('$baseUrl/api/v1/card/connections'),
    );
    final raw = response.data?['connections'] as List<dynamic>? ?? const [];
    return raw
        .map((item) => CardConnection.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CardConnection> createConnection({
    required String organization,
    required String organizationName,
    required String loginType,
    required String loginId,
    required String password,
  }) async {
    final baseUrl = await _baseUrl;
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '$baseUrl/api/v1/card/connections',
        data: {
          'organization': organization,
          'organizationName': organizationName,
          'loginType': loginType,
          'credentials': {'id': loginId, 'password': password},
        },
      ),
    );

    return CardConnection.fromJson(
      response.data?['connection'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<void> deleteConnection(String connectionId) async {
    final baseUrl = await _baseUrl;
    await _request(
      () => _dio.delete<void>('$baseUrl/api/v1/card/connections/$connectionId'),
    );
  }

  Future<List<CardAccount>> listCards({
    required String connectionId,
    required String birthDate,
    required String inquiryType,
  }) async {
    final baseUrl = await _baseUrl;
    final response = await _request(
      () => _dio.get<Map<String, dynamic>>(
        '$baseUrl/api/v1/card/connections/$connectionId/cards',
        queryParameters: {'birthDate': birthDate, 'inquiryType': inquiryType},
      ),
    );
    final raw = response.data?['cards'] as List<dynamic>? ?? const [];
    return raw
        .map((item) => CardAccount.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<CardTransaction>> syncConnection({
    required String connectionId,
    required String startDate,
    required String endDate,
    required String birthDate,
    required String inquiryType,
    required String orderBy,
    String? cardNo,
  }) async {
    final baseUrl = await _baseUrl;
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '$baseUrl/api/v1/card/connections/$connectionId/sync',
        data: {
          'startDate': startDate,
          'endDate': endDate,
          'birthDate': birthDate,
          'inquiryType': inquiryType,
          'orderBy': orderBy,
          if (cardNo != null && cardNo.trim().isNotEmpty)
            'cardNo': cardNo.trim(),
        },
      ),
    );
    final raw = response.data?['transactions'] as List<dynamic>? ?? const [];
    return raw
        .map((item) => CardTransaction.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<CardTransaction>> listTransactions() async {
    final baseUrl = await _baseUrl;
    final response = await _request(
      () => _dio.get<Map<String, dynamic>>('$baseUrl/api/v1/transactions'),
    );
    final raw = response.data?['transactions'] as List<dynamic>? ?? const [];
    return raw
        .map((item) => CardTransaction.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Response<T>> _request<T>(
    Future<Response<T>> Function() request,
  ) async {
    final userId = await _getOrCreateUserId();
    _dio.options.headers['x-user-id'] = userId;
    try {
      return await request();
    } on DioException catch (error) {
      throw Exception(_messageFromDio(error));
    }
  }

  Future<String> _getOrCreateUserId() async {
    final existing = _prefs.getString(_userIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final generated = const Uuid().v4();
    await _prefs.setString(_userIdKey, generated);
    return generated;
  }

  String _messageFromDio(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final errorMap = data['error'];
      if (errorMap is Map<String, dynamic>) {
        final message = errorMap['message'] as String?;
        if (message != null && message.trim().isNotEmpty) {
          return message;
        }
      }
    }

    final statusCode = error.response?.statusCode;
    if (statusCode == null) {
      return '백엔드 서버에 연결하지 못했습니다. BACKEND_BASE_URL 설정을 확인해 주세요.';
    }
    return '요청에 실패했습니다. (HTTP $statusCode)';
  }
}
