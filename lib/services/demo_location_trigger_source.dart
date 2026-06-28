import 'package:intl/intl.dart';

import 'budget_forecast_service.dart';

abstract class LocationTriggerSource {
  List<DemoLocationTrigger> get triggers;

  AlertCandidate candidateFor({
    required DemoLocationTrigger trigger,
    required BudgetForecast forecast,
    DateTime? now,
  });
}

class DemoLocationTrigger {
  const DemoLocationTrigger({
    required this.id,
    required this.placeType,
    required this.placeName,
    required this.dwellTime,
    required this.estimatedSpendKrw,
  });

  final String id;
  final String placeType;
  final String placeName;
  final Duration dwellTime;
  final double estimatedSpendKrw;
}

class AlertCandidate {
  const AlertCandidate({
    required this.id,
    required this.placeType,
    required this.placeName,
    required this.dwellTime,
    required this.estimatedSpendKrw,
    required this.message,
    required this.resultingStatus,
  });

  final String id;
  final String placeType;
  final String placeName;
  final Duration dwellTime;
  final double estimatedSpendKrw;
  final String message;
  final ForecastStatus resultingStatus;
}

class DemoLocationTriggerSource implements LocationTriggerSource {
  const DemoLocationTriggerSource();

  static final _won = NumberFormat('#,##0');
  static const _forecastService = BudgetForecastService();

  @override
  List<DemoLocationTrigger> get triggers => const [
    DemoLocationTrigger(
      id: 'truck-store',
      placeType: '트럭스토어',
      placeName: '도쿄 한정 굿즈 트럭',
      dwellTime: Duration(minutes: 14),
      estimatedSpendKrw: 370000,
    ),
    DemoLocationTrigger(
      id: 'cafe',
      placeType: '카페',
      placeName: '전망 좋은 루프탑 카페',
      dwellTime: Duration(minutes: 18),
      estimatedSpendKrw: 48000,
    ),
    DemoLocationTrigger(
      id: 'restaurant',
      placeType: '음식점',
      placeName: '관광지 앞 인기 식당',
      dwellTime: Duration(minutes: 25),
      estimatedSpendKrw: 126000,
    ),
  ];

  @override
  AlertCandidate candidateFor({
    required DemoLocationTrigger trigger,
    required BudgetForecast forecast,
    DateTime? now,
  }) {
    final after = _forecastService.calculateAfterSpend(
      forecast: forecast,
      additionalSpendKrw: trigger.estimatedSpendKrw,
      now: now,
    );

    return AlertCandidate(
      id: trigger.id,
      placeType: trigger.placeType,
      placeName: trigger.placeName,
      dwellTime: trigger.dwellTime,
      estimatedSpendKrw: trigger.estimatedSpendKrw,
      resultingStatus: after.status,
      message: _message(trigger: trigger, forecastAfterSpend: after),
    );
  }

  String _message({
    required DemoLocationTrigger trigger,
    required BudgetForecast forecastAfterSpend,
  }) {
    final spend = _won.format(trigger.estimatedSpendKrw);
    final depletionDate = forecastAfterSpend.projectedDepletionDate;
    if (forecastAfterSpend.travel == null) {
      return '${trigger.placeName}에서 약 $spend원을 쓸 수 있어요. 여행 예산을 먼저 설정하면 소진일을 예측해 드려요.';
    }
    if (forecastAfterSpend.status == ForecastStatus.depleted) {
      return '${trigger.placeName}에서 약 $spend원을 쓰면 예산을 바로 초과해요. 잠깐 멈칫해 볼까요?';
    }
    if (depletionDate != null) {
      final travelStart = BudgetForecastService.dateOnly(
        forecastAfterSpend.travel!.startDate,
      );
      final tripDay = depletionDate.difference(travelStart).inDays + 1;
      return '${trigger.placeName}에서 약 $spend원을 쓰면 예산이 $tripDay일차에 소진될 수 있어요.';
    }
    return '${trigger.placeName} 예상 소비는 약 $spend원이에요. 오늘 안전 소비 가능액은 ${_won.format(forecastAfterSpend.safeDailyBudgetKrw)}원입니다.';
  }
}
