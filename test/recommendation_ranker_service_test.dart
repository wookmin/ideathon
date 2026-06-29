import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tripreceipt/models/receipt_record.dart';
import 'package:tripreceipt/models/recommend_category.dart';
import 'package:tripreceipt/models/recommend_place.dart';
import 'package:tripreceipt/models/travel.dart';
import 'package:tripreceipt/services/budget_forecast_service.dart';
import 'package:tripreceipt/services/recommendation_ranker_service.dart';

void main() {
  const ranker = RecommendationRankerService();
  final category = RecommendCategory.categories.first;

  test('prioritizes closer and cheaper places when budget is tight', () {
    final forecast = const BudgetForecastService().calculate(
      travel: Travel(
        id: 'trip-1',
        title: '서울 여행',
        country: '한국',
        startDate: DateTime(2026, 6, 25),
        endDate: DateTime(2026, 6, 30),
        budgetKrw: 300000,
        exchangeSourceAmount: null,
        exchangeSourceCurrency: 'KRW',
        exchangeTargetAmount: null,
        exchangeTargetCurrency: 'KRW',
        createdAt: DateTime(2026, 6, 1),
      ),
      records: [
        _record(id: 'r1', amount: 260000, rawOcrText: '한식 식당 restaurant'),
      ],
      now: DateTime(2026, 6, 28),
    );

    final ranked = ranker.rank(
      places: [
        _place(
          id: 'expensive-far',
          rating: 5,
          reviewCount: 3000,
          priceLevel: '가격이 조금 나감',
          distanceText: '2.0km',
        ),
        _place(
          id: 'cheap-near',
          rating: 4.2,
          reviewCount: 100,
          priceLevel: '가격이 저렴함',
          distanceText: '250m',
        ),
      ],
      category: category,
      forecast: forecast,
      records: [
        _record(id: 'r1', amount: 260000, rawOcrText: '한식 식당 restaurant'),
      ],
    );

    expect(forecast.status, ForecastStatus.danger);
    expect(ranked.first.place.id, 'cheap-near');
    expect(ranked.first.aiReason, contains('예산'));
  });
}

RecommendPlace _place({
  required String id,
  required double rating,
  required int reviewCount,
  required String priceLevel,
  required String distanceText,
}) {
  return RecommendPlace(
    id: id,
    name: id,
    category: RecommendCategoryType.restaurant,
    position: const LatLng(37.5665, 126.9780),
    rating: rating,
    reviewCount: reviewCount,
    priceLevel: priceLevel,
    distanceText: distanceText,
    walkTimeText: '도보 3분',
    aiReason: '',
    imageUrl: '',
    description: '',
  );
}

ReceiptRecord _record({
  required String id,
  required double amount,
  required String rawOcrText,
}) {
  return ReceiptRecord(
    id: id,
    date: DateTime(2026, 6, 28),
    country: '한국',
    countryCode: 'KR',
    city: '서울',
    currency: 'KRW',
    originalAmount: amount,
    krwAmount: amount,
    exchangeRate: 1,
    rawOcrText: rawOcrText,
    items: const [],
    verdict: 'unknown',
    tipPct: 0,
    tipKrw: 0,
    memo: '',
    imagePath: null,
    analysis: '',
  );
}
