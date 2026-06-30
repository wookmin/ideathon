import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/receipt_record.dart';
import '../models/travel.dart';
import '../services/budget_alert_policy.dart';
import '../services/budget_forecast_service.dart';
import '../services/notification_history_service.dart';
import 'record_presenter.dart';

class BudgetAlertPresenter {
  BudgetAlertPresenter._();

  static const _forecastService = BudgetForecastService();
  static const _alertPolicy = BudgetAlertPolicy();

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
    final decision = _alertPolicy.decideForPayment(
      before: before,
      after: after,
      record: savedRecord,
    );

    if (decision == null) return;

    final message = _afterSpendMessage(
      forecast: after,
      record: savedRecord,
      decision: decision,
    );
    unawaited(NotificationHistoryService.add(title: '예산 알림', message: message));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  static String _afterSpendMessage({
    required BudgetForecast forecast,
    required ReceiptRecord record,
    required BudgetAlertDecision decision,
  }) {
    final won = NumberFormat('#,##0');
    final spend = won.format(RecordPresenter.totalWithTip(record));
    final ratio = (decision.paymentRatio * 100).round();

    if (forecast.status == ForecastStatus.depleted) {
      return '방금 $spend원을 사용했어요. 예산을 넘긴 상태라, 다음 결제 전 남은 일정을 한번 확인해볼까요?';
    }

    final depletionDate = forecast.projectedDepletionDate;
    if (depletionDate != null && forecast.travel != null) {
      final start = BudgetForecastService.dateOnly(forecast.travel!.startDate);
      final tripDay = depletionDate.difference(start).inDays + 1;
      return '방금 결제는 오늘 안전 소비 가능액의 약 $ratio%예요. 지금 속도면 여행 $tripDay일차쯤 예산이 부족할 수 있어요.';
    }

    return switch (decision.severity) {
      BudgetAlertSeverity.high =>
        '방금 결제는 오늘 안전 소비 가능액의 약 $ratio%예요. 계속 써도 괜찮지만, 남은 일정 기준은 조금 빡빡해졌어요.',
      BudgetAlertSeverity.medium =>
        '방금 $spend원을 사용했어요. 오늘 안전 소비 가능액의 약 $ratio%예요. 남은 하루 기준은 ${won.format(forecast.safeDailyBudgetKrw)}원입니다.',
      BudgetAlertSeverity.low =>
        '방금 $spend원을 사용했어요. 남은 일정 기준 하루 ${won.format(forecast.safeDailyBudgetKrw)}원 안에서 쓰면 괜찮아요.',
    };
  }
}
