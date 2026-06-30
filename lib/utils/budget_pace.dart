import '../services/budget_forecast_service.dart';

/// At the current daily spend pace, which day of the trip the budget will
/// last until (capped at the trip's total length). Uses the same
/// [BudgetForecast.projectedDepletionDate] source as the post-spend alert
/// (BudgetAlertPresenter) so both surfaces report the same day.
int? sustainableTripDay(BudgetForecast forecast) {
  final travel = forecast.travel;
  if (travel == null || forecast.dailyAverageKrw <= 0) {
    return null;
  }

  final start = BudgetForecastService.dateOnly(travel.startDate);
  final depletionDate = forecast.projectedDepletionDate;
  if (depletionDate == null) {
    return forecast.totalDays;
  }
  return BudgetForecastService.dateOnly(
        depletionDate,
      ).difference(start).inDays +
      1;
}
