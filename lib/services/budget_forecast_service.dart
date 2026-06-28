import 'dart:math' as math;

import '../models/receipt_record.dart';
import '../models/travel.dart';
import '../utils/record_presenter.dart';

enum ForecastStatus { noTravel, noSpend, safe, caution, danger, depleted }

class BudgetForecast {
  const BudgetForecast({
    required this.travel,
    required this.totalBudgetKrw,
    required this.usedKrw,
    required this.remainingKrw,
    required this.totalDays,
    required this.elapsedDays,
    required this.remainingDays,
    required this.dailyAverageKrw,
    required this.safeDailyBudgetKrw,
    required this.projectedDepletionDate,
    required this.status,
  });

  final Travel? travel;
  final double totalBudgetKrw;
  final double usedKrw;
  final double remainingKrw;
  final int totalDays;
  final int elapsedDays;
  final int remainingDays;
  final double dailyAverageKrw;
  final double safeDailyBudgetKrw;
  final DateTime? projectedDepletionDate;
  final ForecastStatus status;

  int? get daysUntilDepletion {
    final date = projectedDepletionDate;
    if (date == null) return null;
    final today = BudgetForecastService.dateOnly(DateTime.now());
    return math.max(
      0,
      BudgetForecastService.dateOnly(date).difference(today).inDays,
    );
  }
}

class BudgetForecastService {
  const BudgetForecastService();

  BudgetForecast calculate({
    required Travel? travel,
    required List<ReceiptRecord> records,
    DateTime? now,
  }) {
    final usedKrw = RecordPresenter.totalSpend(records);
    return _calculateFromUsedKrw(travel: travel, usedKrw: usedKrw, now: now);
  }

  BudgetForecast calculateAfterSpend({
    required BudgetForecast forecast,
    required double additionalSpendKrw,
    DateTime? now,
  }) {
    return _calculateFromUsedKrw(
      travel: forecast.travel,
      usedKrw: forecast.usedKrw + additionalSpendKrw,
      now: now,
    );
  }

  BudgetForecast _calculateFromUsedKrw({
    required Travel? travel,
    required double usedKrw,
    DateTime? now,
  }) {
    final today = dateOnly(now ?? DateTime.now());
    if (travel == null) {
      return BudgetForecast(
        travel: null,
        totalBudgetKrw: 0,
        usedKrw: usedKrw,
        remainingKrw: 0,
        totalDays: 0,
        elapsedDays: 0,
        remainingDays: 0,
        dailyAverageKrw: 0,
        safeDailyBudgetKrw: 0,
        projectedDepletionDate: null,
        status: ForecastStatus.noTravel,
      );
    }

    final start = dateOnly(travel.startDate);
    final end = dateOnly(travel.endDate);
    final totalDays = math.max(1, end.difference(start).inDays + 1);
    final elapsedDays = _elapsedDays(start: start, end: end, today: today);
    final remainingDays = _remainingDays(end: end, today: today);
    final remainingKrw = math.max(0, travel.budgetKrw - usedKrw).toDouble();
    final dailyAverageKrw = elapsedDays <= 0 ? 0.0 : usedKrw / elapsedDays;
    final safeDailyBudgetKrw = remainingKrw / math.max(remainingDays, 1);
    final projectedDepletionDate = _projectedDepletionDate(
      today: today,
      end: end,
      usedKrw: usedKrw,
      remainingKrw: remainingKrw,
      dailyAverageKrw: dailyAverageKrw,
    );

    return BudgetForecast(
      travel: travel,
      totalBudgetKrw: travel.budgetKrw,
      usedKrw: usedKrw,
      remainingKrw: remainingKrw,
      totalDays: totalDays,
      elapsedDays: elapsedDays,
      remainingDays: remainingDays,
      dailyAverageKrw: dailyAverageKrw,
      safeDailyBudgetKrw: safeDailyBudgetKrw,
      projectedDepletionDate: projectedDepletionDate,
      status: _status(
        travel: travel,
        usedKrw: usedKrw,
        remainingKrw: remainingKrw,
        remainingDays: remainingDays,
        dailyAverageKrw: dailyAverageKrw,
        safeDailyBudgetKrw: safeDailyBudgetKrw,
        today: today,
        end: end,
      ),
    );
  }

  bool shouldAlertAfterSpend({
    required BudgetForecast before,
    required BudgetForecast after,
  }) {
    if (after.status == ForecastStatus.depleted ||
        after.status == ForecastStatus.danger) {
      return true;
    }

    final beforeDays = _safeDays(before);
    final afterDays = _safeDays(after);
    return beforeDays - afterDays >= 1;
  }

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static int _elapsedDays({
    required DateTime start,
    required DateTime end,
    required DateTime today,
  }) {
    if (today.isBefore(start)) return 0;
    final cappedToday = today.isAfter(end) ? end : today;
    return math.max(1, cappedToday.difference(start).inDays + 1);
  }

  static int _remainingDays({required DateTime end, required DateTime today}) {
    if (today.isAfter(end)) return 0;
    return math.max(1, end.difference(today).inDays + 1);
  }

  static DateTime? _projectedDepletionDate({
    required DateTime today,
    required DateTime end,
    required double usedKrw,
    required double remainingKrw,
    required double dailyAverageKrw,
  }) {
    if (usedKrw <= 0 || dailyAverageKrw <= 0) return null;
    if (remainingKrw <= 0) return today;

    final days = (remainingKrw / dailyAverageKrw).ceil();
    final projected = today.add(Duration(days: days));
    return projected.isAfter(end) ? null : projected;
  }

  static ForecastStatus _status({
    required Travel travel,
    required double usedKrw,
    required double remainingKrw,
    required int remainingDays,
    required double dailyAverageKrw,
    required double safeDailyBudgetKrw,
    required DateTime today,
    required DateTime end,
  }) {
    if (usedKrw <= 0) return ForecastStatus.noSpend;
    if (remainingKrw <= 0) return ForecastStatus.depleted;
    if (today.isAfter(end)) return ForecastStatus.safe;
    if (dailyAverageKrw <= 0) return ForecastStatus.noSpend;
    if (dailyAverageKrw > safeDailyBudgetKrw * 1.35) {
      return ForecastStatus.danger;
    }
    if (dailyAverageKrw > safeDailyBudgetKrw ||
        remainingKrw < safeDailyBudgetKrw * math.max(remainingDays - 1, 1)) {
      return ForecastStatus.caution;
    }
    return ForecastStatus.safe;
  }

  static int _safeDays(BudgetForecast forecast) {
    if (forecast.remainingKrw <= 0) return 0;
    if (forecast.dailyAverageKrw <= 0) return forecast.remainingDays;
    return (forecast.remainingKrw / forecast.dailyAverageKrw).floor();
  }
}
