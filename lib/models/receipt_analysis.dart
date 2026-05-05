import 'dart:convert';

import 'package:hive/hive.dart';

part 'receipt_analysis.g.dart';

@HiveType(typeId: 2)
class ReceiptAnalysis extends HiveObject {
  ReceiptAnalysis({
    required this.currency,
    required this.countryCode,
    required this.country,
    required this.city,
    required this.totalAmount,
    required this.hasServiceCharge,
    required this.verdict,
    required this.verdictLabel,
    required this.verdictEmoji,
    required this.premiumPct,
    required this.touristPremium,
    required this.summary,
    required this.items,
    required this.analysis,
    required this.tipSuggestedPct,
    required this.tipCulture,
    required this.savingTips,
    this.failureReason,
    this.failureDetail,
  });

  @HiveField(0)
  final String currency;
  @HiveField(1)
  final String countryCode;
  @HiveField(2)
  final String country;
  @HiveField(3)
  final String city;
  @HiveField(4)
  final double totalAmount;
  @HiveField(5)
  final bool hasServiceCharge;
  @HiveField(6)
  final String verdict;
  @HiveField(7)
  final String verdictLabel;
  @HiveField(8)
  final String verdictEmoji;
  @HiveField(9)
  final double premiumPct;
  @HiveField(10)
  final String touristPremium;
  @HiveField(11)
  final String summary;
  @HiveField(12)
  final List<ReceiptAnalysisItem> items;
  @HiveField(13)
  final String analysis;
  @HiveField(14)
  final double tipSuggestedPct;
  @HiveField(15)
  final String tipCulture;
  @HiveField(16)
  final List<String> savingTips;
  final String? failureReason;
  final String? failureDetail;
  bool get isFallback => failureReason != null;

  factory ReceiptAnalysis.fromResponseText(String text) {
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    return ReceiptAnalysis.fromJson(decoded);
  }

  factory ReceiptAnalysis.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return ReceiptAnalysis(
      currency: (json['currency'] as String? ?? 'USD').toUpperCase(),
      countryCode: (json['country_code'] as String? ?? '').toUpperCase(),
      country: json['country'] as String? ?? '미확인 국가',
      city: json['city'] as String? ?? '',
      totalAmount: _toDouble(json['total_amount']),
      hasServiceCharge: json['has_service_charge'] as bool? ?? false,
      verdict: json['verdict'] as String? ?? 'unknown',
      verdictLabel: json['verdict_label'] as String? ?? '분석 불가',
      verdictEmoji: json['verdict_emoji'] as String? ?? '❔',
      premiumPct: _toDouble(json['premium_pct']),
      touristPremium: json['tourist_premium'] as String? ?? '중간',
      summary: json['summary'] as String? ?? '분석 정보를 확인해 주세요.',
      items: itemsJson.map(ReceiptAnalysisItem.fromJson).toList(),
      analysis: json['analysis'] as String? ?? '네트워크 문제로 상세 분석을 완료하지 못했습니다.',
      tipSuggestedPct: _toDouble(json['tip_suggested_pct']),
      tipCulture: json['tip_culture'] as String? ?? '선택',
      savingTips: (json['saving_tips'] as List<dynamic>? ?? [])
          .map((tip) => tip.toString())
          .toList(),
      failureReason: null,
      failureDetail: null,
    );
  }

  factory ReceiptAnalysis.fallback({
    required String ocrText,
    String currency = 'USD',
    String? failureReason,
    String? failureDetail,
  }) {
    final inferred = _inferFallbackContext(ocrText, fallbackCurrency: currency);
    return ReceiptAnalysis(
      currency: inferred.currency,
      countryCode: inferred.countryCode,
      country: inferred.country,
      city: inferred.city,
      totalAmount: inferred.totalAmount,
      hasServiceCharge: inferred.hasServiceCharge,
      verdict: 'unknown',
      verdictLabel: 'AI 분석 생략',
      verdictEmoji: '❔',
      premiumPct: 0,
      touristPremium: '중간',
      summary: '환율만으로 임시 계산했어요.',
      items: const [],
      analysis:
          '네트워크 또는 API 오류로 AI 분석을 건너뛰었습니다. OCR에서 찾은 합계와 통화 힌트만으로 임시 표시합니다.',
      tipSuggestedPct: inferred.countryCode == 'KR' || inferred.countryCode == 'JP'
          ? 0
          : 10,
      tipCulture: inferred.countryCode == 'KR' || inferred.countryCode == 'JP'
          ? '불필요'
          : '선택',
      savingTips: const ['결제 전 총액과 서비스료 포함 여부를 다시 확인하세요.'],
      failureReason: failureReason ?? 'AI 분석에 실패해 폴백 결과를 표시 중입니다.',
      failureDetail: failureDetail,
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _guessTotalAmount(String text) {
    final normalized = text.replaceAll('\r', '');
    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    const priorityKeywords = <String>[
      '합계',
      '총액',
      '결제금액',
      '총 금액',
      'total',
      'amount',
      'grand total',
      'sum',
    ];
    const ignoreKeywords = <String>[
      '카드번호',
      '승인번호',
      '가맹',
      '사업자',
      '전화',
      'tel',
      '문의',
      '거래일시',
      'date',
      'time',
      'vat',
    ];

    for (final keyword in priorityKeywords) {
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        final lower = line.toLowerCase();
        if (!lower.contains(keyword)) {
          continue;
        }
        if (ignoreKeywords.any(lower.contains)) {
          continue;
        }

        // OCR often splits labels like "합계" and the amount across nearby lines.
        final nearbyAmounts = <double>[];
        for (final offset in [-1, 0, 1, 2]) {
          final targetIndex = index + offset;
          if (targetIndex < 0 || targetIndex >= lines.length) {
            continue;
          }
          final amount = _extractAmountFromLine(lines[targetIndex]);
          if (amount != null) {
            nearbyAmounts.add(amount);
          }
        }
        if (nearbyAmounts.isNotEmpty) {
          nearbyAmounts.sort();
          return nearbyAmounts.last;
        }
      }
    }

    final candidates = <double>[];
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (ignoreKeywords.any(lower.contains)) {
        continue;
      }
      final amount = _extractAmountFromLine(line);
      if (amount == null) {
        continue;
      }
      if (amount <= 0 || amount >= 100000000) {
        continue;
      }
      candidates.add(amount);
    }

    if (candidates.isEmpty) {
      return 0;
    }
    candidates.sort();
    return candidates.last;
  }

  static _FallbackContext _inferFallbackContext(
    String text, {
    required String fallbackCurrency,
  }) {
    final lower = text.toLowerCase();
    final amount = _guessTotalAmount(text);

    var currency = fallbackCurrency.toUpperCase();
    var countryCode = '';
    var country = '분석 실패';
    var city = '';

    if (lower.contains('원') ||
        lower.contains('krw') ||
        lower.contains('서울') ||
        lower.contains('대한민국') ||
        lower.contains('한국')) {
      currency = 'KRW';
      countryCode = 'KR';
      country = '대한민국';
      if (lower.contains('서울')) {
        city = '서울';
      }
    } else if (lower.contains('¥') || lower.contains('jpy') || lower.contains('엔')) {
      currency = 'JPY';
      countryCode = 'JP';
      country = '일본';
    } else if (lower.contains('\$') || lower.contains('usd')) {
      currency = 'USD';
      countryCode = 'US';
      country = '미국';
    } else if (lower.contains('€') || lower.contains('eur')) {
      currency = 'EUR';
    } else if (currency.isEmpty) {
      currency = 'USD';
    }

    final hasServiceCharge = lower.contains('service charge') ||
        lower.contains('svc') ||
        lower.contains('봉사료') ||
        lower.contains('서비스');

    return _FallbackContext(
      currency: currency,
      countryCode: countryCode,
      country: country,
      city: city,
      totalAmount: amount,
      hasServiceCharge: hasServiceCharge,
    );
  }

  static double? _extractAmountFromLine(String line) {
    final normalized = line.toLowerCase();
    if (normalized.contains('/') ||
        normalized.contains(':') ||
        normalized.contains('tel') ||
        normalized.contains('카드') ||
        normalized.contains('승인') ||
        normalized.contains('가맹') ||
        normalized.contains('사업자') ||
        normalized.contains('주소')) {
      return null;
    }

    final matches = RegExp(
      r'(?<![\d/:-])(\d{1,3}(?:[,\.\s]\d{3})+|\d{1,7})(?:[.,]\d{1,2})?(?![\d/:])',
    ).allMatches(line);

    double? best;
    for (final match in matches) {
      final raw = match.group(0);
      if (raw == null) {
        continue;
      }
      final digitsOnly = _normalizeAmountString(raw);
      if (digitsOnly.length >= 8 || digitsOnly.length <= 1) {
        continue;
      }
      final value = double.tryParse(digitsOnly);
      if (value == null || value <= 0 || value >= 100000000) {
        continue;
      }
      if (!line.contains('원') &&
          !line.contains('₩') &&
          !line.contains('krw') &&
          value >= 10000) {
        continue;
      }
      best = value;
    }
    return best;
  }

  static String _normalizeAmountString(String raw) {
    final compact = raw.replaceAll(' ', '');
    final separators = RegExp(r'[,.]').allMatches(compact).length;
    if (separators == 1 &&
        RegExp(r'^\d{1,3}[,.]\d{3}$').hasMatch(compact)) {
      return compact.replaceAll(RegExp(r'[,.]'), '');
    }
    if (separators > 1 &&
        RegExp(r'^\d{1,3}(?:[,.]\d{3})+$').hasMatch(compact)) {
      return compact.replaceAll(RegExp(r'[,.]'), '');
    }
    return compact.replaceAll(',', '');
  }
}

class _FallbackContext {
  const _FallbackContext({
    required this.currency,
    required this.countryCode,
    required this.country,
    required this.city,
    required this.totalAmount,
    required this.hasServiceCharge,
  });

  final String currency;
  final String countryCode;
  final String country;
  final String city;
  final double totalAmount;
  final bool hasServiceCharge;
}

@HiveType(typeId: 3)
class ReceiptAnalysisItem extends HiveObject {
  ReceiptAnalysisItem({
    required this.name,
    required this.paid,
    required this.avg,
    required this.status,
  });

  @HiveField(0)
  final String name;
  @HiveField(1)
  final String paid;
  @HiveField(2)
  final String avg;
  @HiveField(3)
  final String status;

  factory ReceiptAnalysisItem.fromJson(Map<String, dynamic> json) {
    return ReceiptAnalysisItem(
      name: json['name'] as String? ?? '항목',
      paid: json['paid'] as String? ?? '',
      avg: json['avg'] as String? ?? '',
      status: json['status'] as String? ?? 'ok',
    );
  }
}
