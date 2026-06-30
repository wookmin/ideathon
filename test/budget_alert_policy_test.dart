import 'package:flutter_test/flutter_test.dart';
import 'package:tripreceipt/models/receipt_record.dart';
import 'package:tripreceipt/models/travel.dart';
import 'package:tripreceipt/services/budget_alert_policy.dart';
import 'package:tripreceipt/services/budget_forecast_service.dart';

void main() {
  const forecastService = BudgetForecastService();
  const policy = BudgetAlertPolicy();

  Travel travel({
    double budgetKrw = 800000,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Travel(
      id: 'trip-1',
      title: 'Tokyo trip',
      country: 'Japan',
      startDate: startDate ?? DateTime(2026, 6, 1),
      endDate: endDate ?? DateTime(2026, 6, 8),
      budgetKrw: budgetKrw,
      exchangeSourceAmount: null,
      exchangeSourceCurrency: 'KRW',
      exchangeTargetAmount: null,
      exchangeTargetCurrency: 'JPY',
      createdAt: DateTime(2026, 5, 1),
    );
  }

  ReceiptRecord record({
    required double amount,
    String memo = 'food',
    String rawOcrText = '',
  }) {
    return ReceiptRecord(
      id: 'record-$amount-$memo',
      date: DateTime(2026, 6, 1),
      country: 'Japan',
      countryCode: 'JP',
      city: 'Tokyo',
      currency: 'KRW',
      originalAmount: amount,
      krwAmount: amount,
      exchangeRate: 1,
      rawOcrText: rawOcrText,
      items: const [],
      verdict: 'unknown',
      tipPct: 0,
      tipKrw: 0,
      memo: memo,
      imagePath: null,
      analysis: '',
    );
  }

  BudgetForecast before({List<ReceiptRecord> records = const []}) {
    return forecastService.calculate(
      travel: travel(),
      records: records,
      now: DateTime(2026, 6, 1),
    );
  }

  test('ignores payments at or below 5000 won', () {
    final beforeForecast = before();
    final payment = record(amount: 5000);
    final afterForecast = forecastService.calculateAfterSpend(
      forecast: beforeForecast,
      additionalSpendKrw: payment.krwAmount,
      now: DateTime(2026, 6, 1),
    );

    expect(
      policy.decideForPayment(
        before: beforeForecast,
        after: afterForecast,
        record: payment,
      ),
      isNull,
    );
  });

  test('alerts when payment is at least 12 percent of daily budget', () {
    final beforeForecast = before();
    final payment = record(amount: 12000);
    final afterForecast = forecastService.calculateAfterSpend(
      forecast: beforeForecast,
      additionalSpendKrw: payment.krwAmount,
      now: DateTime(2026, 6, 1),
    );

    final decision = policy.decideForPayment(
      before: beforeForecast,
      after: afterForecast,
      record: payment,
    );

    expect(decision, isNotNull);
    expect(decision!.severity, BudgetAlertSeverity.low);
  });

  test('ignores transport and lodging unless they make budget risky', () {
    final beforeForecast = before();
    final transport = record(amount: 60000, memo: '\uad50\ud1b5');
    final afterForecast = forecastService.calculateAfterSpend(
      forecast: beforeForecast,
      additionalSpendKrw: transport.krwAmount,
      now: DateTime(2026, 6, 1),
    );

    expect(
      policy.decideForPayment(
        before: beforeForecast,
        after: afterForecast,
        record: transport,
      ),
      isNull,
    );
  });

  test('allows transport and lodging alert when status becomes danger', () {
    final beforeForecast = before();
    final hotel = record(amount: 120000, memo: '\uc219\ubc15 hotel');
    final afterForecast = forecastService.calculateAfterSpend(
      forecast: beforeForecast,
      additionalSpendKrw: hotel.krwAmount,
      now: DateTime(2026, 6, 1),
    );

    final decision = policy.decideForPayment(
      before: beforeForecast,
      after: afterForecast,
      record: hotel,
    );

    expect(decision, isNotNull);
    expect(decision!.severity, BudgetAlertSeverity.high);
  });
}
