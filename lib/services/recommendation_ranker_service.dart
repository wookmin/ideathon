import 'dart:math' as math;

import '../models/receipt_record.dart';
import '../models/recommend_category.dart';
import '../models/recommend_place.dart';
import '../services/budget_forecast_service.dart';

class RankedRecommendation {
  const RankedRecommendation({
    required this.place,
    required this.aiReason,
    required this.score,
  });

  final RecommendPlace place;
  final String aiReason;
  final double score;
}

class RecommendationRankerService {
  const RecommendationRankerService();

  List<RankedRecommendation> rank({
    required List<RecommendPlace> places,
    required RecommendCategory category,
    required BudgetForecast forecast,
    required List<ReceiptRecord> records,
  }) {
    final categorySpend = _categorySpend(records);
    final totalSpend = categorySpend.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final selectedShare = totalSpend <= 0
        ? 0.0
        : (categorySpend[category.type] ?? 0) / totalSpend;

    final ranked = places.map((place) {
      final priceLevel = _priceLevel(place.priceLevel);
      final distanceMeters = _distanceMeters(place.distanceText);
      final score = _score(
        place: place,
        forecast: forecast,
        selectedShare: selectedShare,
        priceLevel: priceLevel,
        distanceMeters: distanceMeters,
      );

      return RankedRecommendation(
        place: place,
        score: score,
        aiReason: _reason(
          place: place,
          category: category,
          forecast: forecast,
          selectedShare: selectedShare,
          priceLevel: priceLevel,
          distanceMeters: distanceMeters,
        ),
      );
    }).toList()..sort((a, b) => b.score.compareTo(a.score));

    return ranked;
  }

  double _score({
    required RecommendPlace place,
    required BudgetForecast forecast,
    required double selectedShare,
    required int priceLevel,
    required double distanceMeters,
  }) {
    final distanceScore = _clamp01(1 - (distanceMeters / 2500));
    final ratingScore = _clamp01(place.rating / 5);
    final reviewScore = _clamp01(
      math.log(place.reviewCount + 1) / math.log(5000),
    );
    final priceScore = _priceScore(priceLevel: priceLevel, forecast: forecast);
    final habitScore = _habitScore(selectedShare);

    final tightBudget =
        forecast.status == ForecastStatus.caution ||
        forecast.status == ForecastStatus.danger ||
        forecast.status == ForecastStatus.depleted;

    if (tightBudget) {
      return distanceScore * 0.32 +
          priceScore * 0.34 +
          ratingScore * 0.18 +
          reviewScore * 0.08 +
          habitScore * 0.08;
    }

    return distanceScore * 0.25 +
        priceScore * 0.22 +
        ratingScore * 0.28 +
        reviewScore * 0.15 +
        habitScore * 0.10;
  }

  double _priceScore({
    required int priceLevel,
    required BudgetForecast forecast,
  }) {
    final tightBudget =
        forecast.status == ForecastStatus.caution ||
        forecast.status == ForecastStatus.danger ||
        forecast.status == ForecastStatus.depleted;

    if (tightBudget) {
      return switch (priceLevel) {
        0 || 1 => 1.0,
        2 => 0.75,
        3 => 0.35,
        _ => 0.15,
      };
    }

    return switch (priceLevel) {
      0 || 1 => 0.82,
      2 => 1.0,
      3 => 0.78,
      _ => 0.55,
    };
  }

  double _habitScore(double selectedShare) {
    if (selectedShare <= 0) return 0.65;
    if (selectedShare >= 0.45) return 1.0;
    if (selectedShare >= 0.25) return 0.85;
    return 0.7;
  }

  String _reason({
    required RecommendPlace place,
    required RecommendCategory category,
    required BudgetForecast forecast,
    required double selectedShare,
    required int priceLevel,
    required double distanceMeters,
  }) {
    final budgetPhrase = switch (forecast.status) {
      ForecastStatus.depleted => '예산을 이미 초과해서 가격 부담이 낮은 곳을 우선했어요.',
      ForecastStatus.danger => '남은 예산이 빠르게 줄고 있어 가까운 거리와 낮은 가격대를 우선했어요.',
      ForecastStatus.caution => '예산 사용 속도가 조금 빨라서 이동 부담과 가격대를 함께 낮췄어요.',
      ForecastStatus.safe => '예산 흐름이 안정적이라 평점과 접근성을 함께 반영했어요.',
      ForecastStatus.noSpend => '아직 소비 기록이 적어 평점과 가까운 거리를 중심으로 골랐어요.',
      ForecastStatus.noTravel => '선택된 여행 예산이 없어 가까운 거리와 평점을 중심으로 골랐어요.',
    };

    final habitPhrase = selectedShare >= 0.35
        ? '최근 ${category.label} 지출 비중이 높아 익숙한 소비 패턴도 반영했어요.'
        : '최근 소비가 한쪽에 치우치지 않아 무난한 선택지를 우선했어요.';

    final pricePhrase = priceLevel <= 1
        ? '가격 부담이 낮은 편이에요.'
        : priceLevel >= 3
        ? '가격대가 조금 있어 평점과 거리 조건을 같이 봤어요.'
        : '가격대는 무난한 편이에요.';

    final distancePhrase = distanceMeters <= 700
        ? '지금 위치에서 가깝습니다.'
        : '이동 시간은 조금 있지만 후보 중 균형이 좋아요.';

    return '$budgetPhrase $habitPhrase $pricePhrase $distancePhrase';
  }

  Map<RecommendCategoryType, double> _categorySpend(
    List<ReceiptRecord> records,
  ) {
    final spend = {
      RecommendCategoryType.restaurant: 0.0,
      RecommendCategoryType.cafe: 0.0,
      RecommendCategoryType.shopping: 0.0,
      RecommendCategoryType.attraction: 0.0,
    };

    for (final record in records) {
      final type = _inferCategory(record);
      if (type != null) {
        spend[type] = (spend[type] ?? 0) + record.krwAmount;
      }
    }

    return spend;
  }

  RecommendCategoryType? _inferCategory(ReceiptRecord record) {
    final text = [
      record.rawOcrText,
      record.memo,
      record.analysis,
      ...record.items.map((item) => item.name),
    ].join(' ').toLowerCase();

    if (_containsAny(text, const [
      'coffee',
      'cafe',
      'latte',
      'americano',
      '카페',
      '커피',
      '라떼',
      '아메리카노',
    ])) {
      return RecommendCategoryType.cafe;
    }
    if (_containsAny(text, const [
      'mall',
      'store',
      'shop',
      'market',
      '쇼핑',
      '마트',
      '상점',
      '매장',
      '백화점',
    ])) {
      return RecommendCategoryType.shopping;
    }
    if (_containsAny(text, const [
      'museum',
      'ticket',
      'tour',
      'park',
      '전시',
      '박물관',
      '입장권',
      '티켓',
      '공원',
      '관광',
    ])) {
      return RecommendCategoryType.attraction;
    }
    if (_containsAny(text, const [
      'restaurant',
      'food',
      'dining',
      'bar',
      '식당',
      '음식',
      '레스토랑',
      '분식',
      '한식',
      '일식',
      '중식',
      '양식',
    ])) {
      return RecommendCategoryType.restaurant;
    }
    return null;
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }

  int _priceLevel(String label) {
    if (label.contains('저렴')) return 1;
    if (label.contains('조금')) return 3;
    if (label.contains('비쌈')) return 4;
    return 2;
  }

  double _distanceMeters(String distanceText) {
    final value = double.tryParse(
      RegExp(r'[\d.]+').firstMatch(distanceText)?.group(0) ?? '',
    );
    if (value == null) return 2500;
    if (distanceText.contains('km')) return value * 1000;
    return value;
  }

  double _clamp01(double value) => value.clamp(0.0, 1.0);
}
