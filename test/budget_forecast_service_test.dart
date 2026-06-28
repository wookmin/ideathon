import 'package:flutter_test/flutter_test.dart';
import 'package:tripreceipt/models/receipt_record.dart';
import 'package:tripreceipt/models/travel.dart';
import 'package:tripreceipt/services/budget_forecast_service.dart';
import 'package:tripreceipt/services/demo_location_trigger_source.dart';

void main() {
  const service = BudgetForecastService();

  Travel travel({
    double budgetKrw = 1500000,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Travel(
      id: 'trip-1',
      title: '도쿄 여행',
      country: '일본',
      startDate: startDate ?? DateTime(2026, 6, 25),
      endDate: endDate ?? DateTime(2026, 7, 4),
      budgetKrw: budgetKrw,
      exchangeSourceAmount: null,
      exchangeSourceCurrency: 'KRW',
      exchangeTargetAmount: null,
      exchangeTargetCurrency: 'JPY',
      createdAt: DateTime(2026, 6, 1),
    );
  }

  ReceiptRecord record(double amount, DateTime date) {
    return ReceiptRecord(
      id: 'record-$amount-${date.day}',
      date: date,
      country: '일본',
      countryCode: 'JP',
      city: '도쿄',
      currency: 'JPY',
      originalAmount: amount,
      krwAmount: amount,
      exchangeRate: 1,
      rawOcrText: '',
      items: const [],
      verdict: 'unknown',
      tipPct: 0,
      tipKrw: 0,
      memo: '',
      imagePath: null,
      analysis: '',
    );
  }

  test('calculates depletion timing from remaining budget and trip days', () {
    final forecast = service.calculate(
      travel: travel(),
      records: [
        record(400000, DateTime(2026, 6, 25)),
        record(360000, DateTime(2026, 6, 26)),
        record(360000, DateTime(2026, 6, 27)),
      ],
      now: DateTime(2026, 6, 27),
    );

    expect(forecast.usedKrw, 1120000);
    expect(forecast.remainingKrw, 380000);
    expect(forecast.elapsedDays, 3);
    expect(forecast.remainingDays, 8);
    expect(forecast.dailyAverageKrw.round(), 373333);
    expect(forecast.safeDailyBudgetKrw.round(), 47500);
    expect(forecast.projectedDepletionDate, DateTime(2026, 6, 29));
    expect(forecast.status, ForecastStatus.danger);
  });

  test('handles no travel and no spend states', () {
    final noTravel = service.calculate(
      travel: null,
      records: const [],
      now: DateTime(2026, 6, 27),
    );
    expect(noTravel.status, ForecastStatus.noTravel);

    final noSpend = service.calculate(
      travel: travel(),
      records: const [],
      now: DateTime(2026, 6, 27),
    );
    expect(noSpend.status, ForecastStatus.noSpend);
    expect(noSpend.safeDailyBudgetKrw.round(), 187500);
  });

  test('marks depleted when spend exceeds budget', () {
    final forecast = service.calculate(
      travel: travel(budgetKrw: 100000),
      records: [record(120000, DateTime(2026, 6, 27))],
      now: DateTime(2026, 6, 27),
    );

    expect(forecast.remainingKrw, 0);
    expect(forecast.status, ForecastStatus.depleted);
    expect(forecast.projectedDepletionDate, DateTime(2026, 6, 27));
  });

  test('alerts when a small spend meaningfully shortens safe days', () {
    final before = service.calculate(
      travel: travel(budgetKrw: 300000),
      records: [record(100000, DateTime(2026, 6, 25))],
      now: DateTime(2026, 6, 27),
    );
    final after = service.calculate(
      travel: travel(budgetKrw: 300000),
      records: [
        record(100000, DateTime(2026, 6, 25)),
        record(50000, DateTime(2026, 6, 27)),
      ],
      now: DateTime(2026, 6, 27),
    );

    expect(service.shouldAlertAfterSpend(before: before, after: after), isTrue);
  });

  test('demo location trigger produces an actionable alert candidate', () {
    final forecast = service.calculate(
      travel: travel(),
      records: [record(1120000, DateTime(2026, 6, 27))],
      now: DateTime(2026, 6, 27),
    );
    const source = DemoLocationTriggerSource();

    final candidate = source.candidateFor(
      trigger: source.triggers.first,
      forecast: forecast,
      now: DateTime(2026, 6, 27),
    );

    expect(candidate.placeType, '트럭스토어');
    expect(candidate.estimatedSpendKrw, 370000);
    expect(candidate.message, contains('예산'));
    expect(candidate.resultingStatus, ForecastStatus.danger);
  });
}
