import 'dart:math' as math;

import '../models/receipt_record.dart';
import '../utils/record_presenter.dart';
import 'budget_forecast_service.dart';

enum BudgetAlertSeverity { low, medium, high }

class BudgetAlertDecision {
  const BudgetAlertDecision({
    required this.severity,
    required this.paymentRatio,
    required this.paymentKrw,
    required this.dailyBudgetKrw,
  });

  final BudgetAlertSeverity severity;
  final double paymentRatio;
  final double paymentKrw;
  final double dailyBudgetKrw;
}

class BudgetAlertPolicy {
  const BudgetAlertPolicy();

  static const minimumPaymentAlertKrw = 5000.0;
  static const dailyBudgetPaymentRatio = 0.12;
  static const dangerExceptionRatio = 0.08;

  BudgetAlertDecision? decideForPayment({
    required BudgetForecast before,
    required BudgetForecast after,
    required ReceiptRecord record,
  }) {
    if (before.travel == null) return null;

    final paymentKrw = RecordPresenter.totalWithTip(record);
    if (paymentKrw <= minimumPaymentAlertKrw) return null;

    final dailyBudgetKrw = before.safeDailyBudgetKrw;
    if (dailyBudgetKrw <= 0) return null;

    final paymentRatio = paymentKrw / dailyBudgetKrw;
    final threshold = math.max(
      minimumPaymentAlertKrw,
      dailyBudgetKrw * dailyBudgetPaymentRatio,
    );
    final categoryExcluded = _isTransportOrLodging(record);
    final statusGotWorse =
        _statusRank(after.status) > _statusRank(before.status);
    final becameRisky =
        after.status == ForecastStatus.danger ||
        after.status == ForecastStatus.depleted;

    if (categoryExcluded && !(becameRisky && statusGotWorse)) {
      return null;
    }

    final meaningfulPayment = paymentKrw >= threshold;
    final riskySmallPayment =
        becameRisky && statusGotWorse && paymentRatio >= dangerExceptionRatio;

    if (!meaningfulPayment && !riskySmallPayment) {
      return null;
    }

    return BudgetAlertDecision(
      severity: _severity(after: after, paymentRatio: paymentRatio),
      paymentRatio: paymentRatio,
      paymentKrw: paymentKrw,
      dailyBudgetKrw: dailyBudgetKrw,
    );
  }

  static bool _isTransportOrLodging(ReceiptRecord record) {
    final text =
        '${record.memo} ${record.rawOcrText} ${RecordPresenter.category(record)}'
            .toLowerCase();
    return text.contains('\uad50\ud1b5') ||
        text.contains('\uc219\ubc15') ||
        text.contains('\ud56d\uacf5') ||
        text.contains('hotel') ||
        text.contains('lodging') ||
        text.contains('metro') ||
        text.contains('train') ||
        text.contains('bus') ||
        text.contains('taxi') ||
        text.contains('flight');
  }

  static BudgetAlertSeverity _severity({
    required BudgetForecast after,
    required double paymentRatio,
  }) {
    if (after.status == ForecastStatus.depleted ||
        after.status == ForecastStatus.danger) {
      return BudgetAlertSeverity.high;
    }
    if (after.status == ForecastStatus.caution || paymentRatio >= 0.25) {
      return BudgetAlertSeverity.medium;
    }
    return BudgetAlertSeverity.low;
  }

  static int _statusRank(ForecastStatus status) {
    return switch (status) {
      ForecastStatus.noTravel => 0,
      ForecastStatus.noSpend => 0,
      ForecastStatus.safe => 1,
      ForecastStatus.caution => 2,
      ForecastStatus.danger => 3,
      ForecastStatus.depleted => 4,
    };
  }
}
