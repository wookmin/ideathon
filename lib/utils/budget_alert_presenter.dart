import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/receipt_record.dart';
import '../models/travel.dart';
import '../services/budget_forecast_service.dart';
import 'record_presenter.dart';

class BudgetAlertPresenter {
  BudgetAlertPresenter._();

  static const _forecastService = BudgetForecastService();

  static void maybeShowAfterRecordSaved({
    required BuildContext context,
    required Travel? travel,
    required List<ReceiptRecord> recordsBeforeSave,
    required ReceiptRecord savedRecord,
  }) {
    final before = _forecastService.calculate(
      travel: travel,
      records: recordsBeforeSave,
    );
    final after = _forecastService.calculate(
      travel: travel,
      records: [...recordsBeforeSave, savedRecord],
    );

    if (!_forecastService.shouldAlertAfterSpend(before: before, after: after)) {
      return;
    }

    final message = _afterSpendMessage(after, savedRecord);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  static String _afterSpendMessage(
    BudgetForecast forecast,
    ReceiptRecord record,
  ) {
    final won = NumberFormat('#,##0');
    final spend = won.format(RecordPresenter.totalWithTip(record));
    if (forecast.status == ForecastStatus.depleted) {
      return '방금 $spend원을 써서 여행 예산을 초과했어요. 다음 결제 전 한 번 멈칫해요.';
    }

    final depletionDate = forecast.projectedDepletionDate;
    if (depletionDate != null && forecast.travel != null) {
      final start = BudgetForecastService.dateOnly(forecast.travel!.startDate);
      final tripDay = depletionDate.difference(start).inDays + 1;
      return '방금 소비로 예산 소진 예상일이 $tripDay일차로 당겨졌어요.';
    }

    return '방금 $spend원을 반영했어요. 오늘 안전 소비 가능액은 ${won.format(forecast.safeDailyBudgetKrw)}원입니다.';
  }
}
