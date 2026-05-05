import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../config/env.dart';
import '../models/receipt_analysis.dart';

class GeminiService {
  GeminiService(this._dio);

  final Dio _dio;
  static const _model = 'gemini-2.5-flash';

  static const _systemPrompt = '''
당신은 해외여행 영수증 분석 전문가입니다.
영수증 이미지와 OCR 텍스트, 위치 정보를 분석하여
아래 JSON 형식만 반환하세요. 마크다운, 설명 텍스트는 절대 포함하지 마세요.

{
  "currency": "통화 코드 (예: JPY, USD, THB)",
  "country_code": "ISO 2자리 국가 코드 (예: JP, US, TH)",
  "country": "국가명 (한국어)",
  "city": "도시명 (한국어, 모르면 빈 문자열)",
  "total_amount": 합계금액(숫자, 세금·서비스료 포함),
  "has_service_charge": true | false,
  "verdict": "fair" | "pricey" | "rip",
  "verdict_label": "합리적인 가격" | "약간 비쌈" | "바가지 의심",
  "verdict_emoji": "✅" | "⚠️" | "🚨",
  "premium_pct": 현지평균대비초과퍼센트(숫자, 0이면 0),
  "tourist_premium": "낮음" | "중간" | "높음",
  "summary": "판정 한 줄 요약 (30자 이내)",
  "items": [
    {
      "name": "항목명",
      "paid": "지불금액 문자열",
      "avg": "현지평균가 문자열",
      "status": "ok" | "warn" | "bad"
    }
  ],
  "analysis": "종합 분석 2~3문장. 관광지 프리미엄, 서비스료 포함 여부 언급.",
  "tip_suggested_pct": 권장팁퍼센트(숫자, 팁불필요국가는 0),
  "tip_culture": "필수" | "선택" | "불필요",
  "saving_tips": ["절약 팁 1", "절약 팁 2"]
}
''';

  Future<ReceiptAnalysis> analyzeReceipt({
    required String imagePath,
    required String ocrText,
    String country = '',
    String city = '',
  }) async {
    if (Env.geminiApiKey.isEmpty) {
      return ReceiptAnalysis.fallback(
        ocrText: ocrText,
        failureReason: 'Gemini API 키가 비어 있어 AI 분석을 건너뛰었습니다.',
        failureDetail: 'lib/config/env_local.dart 또는 --dart-define 값을 확인해 주세요.',
      );
    }

    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await _dio.post<Map<String, dynamic>>(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=${Env.geminiApiKey}',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
                  },
                },
                {
                  'text':
                      '위치: $country $city\nOCR 텍스트: $ocrText\n\n아래 시스템 지시에 따라 분석하세요.',
                },
              ],
            },
          ],
          'system_instruction': {
            'parts': [
              {'text': _systemPrompt},
            ],
          },
          'generationConfig': {'responseMimeType': 'application/json'},
        },
      );

      final text =
          (((response.data ?? const {})['candidates'] as List<dynamic>?)
                      ?.firstOrNull
                  as Map<String, dynamic>?)?['content']
              as Map<String, dynamic>?;
      final parts = text?['parts'] as List<dynamic>?;
      final jsonText = parts?.firstOrNull is Map<String, dynamic>
          ? (parts!.first as Map<String, dynamic>)['text'] as String? ?? '{}'
          : '{}';
      if (jsonText.trim().isEmpty || jsonText.trim() == '{}') {
        return ReceiptAnalysis.fallback(
          ocrText: ocrText,
          failureReason: 'Gemini 응답에서 JSON 본문을 읽지 못했습니다.',
          failureDetail:
              'model=$_model, 후보 응답은 왔지만 content.parts[0].text 가 비어 있습니다.',
        );
      }
      return ReceiptAnalysis.fromResponseText(jsonText);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;
      return ReceiptAnalysis.fallback(
        ocrText: ocrText,
        failureReason: _mapDioFailureReason(error),
        failureDetail:
            'model=$_model, status=$statusCode, type=${error.type}, response=${responseData ?? 'none'}',
      );
    } on FormatException catch (error) {
      return ReceiptAnalysis.fallback(
        ocrText: ocrText,
        failureReason: 'Gemini 응답 JSON 파싱에 실패했습니다.',
        failureDetail: error.message,
      );
    } catch (error) {
      return ReceiptAnalysis.fallback(
        ocrText: ocrText,
        failureReason: '알 수 없는 오류로 AI 분석을 완료하지 못했습니다.',
        failureDetail: error.toString(),
      );
    }
  }

  String _mapDioFailureReason(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 400) {
      return 'Gemini 요청 형식이 잘못되었습니다.';
    }
    if (statusCode == 403) {
      return 'Gemini API 권한이 없거나 키 제한에 걸렸습니다.';
    }
    if (statusCode == 404) {
      return 'Gemini 모델 또는 엔드포인트를 찾지 못했습니다.';
    }
    if (statusCode == 429) {
      return 'Gemini API 쿼터를 초과했습니다.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Gemini 서버 오류가 발생했습니다.';
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Gemini 요청 시간이 초과되었습니다.';
      case DioExceptionType.connectionError:
        return '네트워크 연결 문제로 Gemini 호출에 실패했습니다.';
      case DioExceptionType.badCertificate:
        return 'SSL 인증서 문제로 Gemini 호출에 실패했습니다.';
      default:
        return 'Gemini API 호출에 실패했습니다.';
    }
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
