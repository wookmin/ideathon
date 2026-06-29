import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/receipt_record.dart';
import '../providers/ledger_provider.dart';
import '../providers/travel_selection_provider.dart';
import '../services/budget_forecast_service.dart';
import '../utils/budget_pace.dart';
import '../utils/record_presenter.dart';

class BudgetForecastDetailScreen extends ConsumerWidget {
  const BudgetForecastDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(ledgerProvider);
    final selectedTravel = ref.watch(effectiveTravelProvider);
    final scopedRecords = scopedRecordsForTravel(records, selectedTravel);
    final forecast = const BudgetForecastService().calculate(
      travel: selectedTravel,
      records: scopedRecords,
    );

    final travelTitle =
        selectedTravel?.title ?? RecordPresenter.travelTitle(records);
    final period = selectedTravel != null
        ? displayPeriodForTravel(selectedTravel)
        : RecordPresenter.travelDateRange(records);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFE),
        elevation: 0,
        title: const Text('예측보기'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    travelTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(period, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            _ForecastHeroCard(forecast: forecast),
            const SizedBox(height: 28),
            Text('이렇게 예측했어요', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _ForecastBasisCard(forecast: forecast),
            const SizedBox(height: 20),
            _AiInsightsCard(records: scopedRecords),
          ],
        ),
      ),
    );
  }
}

class _ForecastHeroCard extends StatelessWidget {
  const _ForecastHeroCard({required this.forecast});

  final BudgetForecast forecast;

  @override
  Widget build(BuildContext context) {
    final tripDay = sustainableTripDay(forecast);
    final won = NumberFormat('#,##0');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 18, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F6DF3), Color(0xFF3D8CFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33156CE8),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -2,
            top: 0,
            child: SvgPicture.asset(
              'assets/design/icons/airplane.svg',
              width: 104,
              height: 91,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tripDay != null) ...[
                Text(
                  '이 속도라면 남은 예산으로',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(color: Colors.white, height: 1.08),
                    children: [
                      TextSpan(text: '$tripDay일 째'),
                      TextSpan(
                        text: ' 까지 갈 수 있어요',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ] else
                Text(
                  '여행을 추가하고 예산 알림을 시작해요',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              const SizedBox(height: 7),
              Text(
                _captionFor(forecast, tripDay),
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 18),
              Text(
                '하루 권장 소비',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(color: Colors.white, height: 1.08),
                  children: [
                    TextSpan(text: '₩${won.format(forecast.safeDailyBudgetKrw)}'),
                    TextSpan(
                      text: ' 이하',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '남은 ${forecast.remainingDays}일간 유지 시 예산 내 완주 가능',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _captionFor(BudgetForecast forecast, int? tripDay) {
    if (forecast.travel == null || tripDay == null) {
      return '';
    }
    final shortfall = forecast.totalDays - tripDay;
    if (shortfall > 0) {
      return '여행 종료까지 ${forecast.totalDays}일 | $shortfall일 부족';
    }
    return '이 속도면 여행 끝까지 예산이 충분해요';
  }
}

class _ForecastBasisCard extends StatelessWidget {
  const _ForecastBasisCard({required this.forecast});

  final BudgetForecast forecast;

  @override
  Widget build(BuildContext context) {
    final won = NumberFormat('#,##0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: [
          _BasisRow(
            label: '총 여행 예산',
            value: '₩${won.format(forecast.totalBudgetKrw)}',
          ),
          _BasisRow(
            label: '${forecast.elapsedDays}일 간 사용한 예산',
            value: '₩${won.format(forecast.usedKrw)}',
          ),
          _BasisRow(
            label: '하루 평균 소비',
            value: '₩${won.format(forecast.dailyAverageKrw)}',
          ),
          _BasisRow(
            label: '남은 예산',
            value: '₩${won.format(forecast.remainingKrw)}',
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _BasisRow extends StatelessWidget {
  const _BasisRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _AiInsightsCard extends StatelessWidget {
  const _AiInsightsCard({required this.records});

  final List<ReceiptRecord> records;

  @override
  Widget build(BuildContext context) {
    final insights = _buildInsights(records);
    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI 소비 패턴 분석', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          for (var i = 0; i < insights.length; i++) ...[
            _InsightRow(insight: insights[i]),
            if (i != insights.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  List<_Insight> _buildInsights(List<ReceiptRecord> records) {
    if (records.isEmpty) {
      return const [];
    }

    final totals = <String, double>{};
    final counts = <String, int>{};
    var total = 0.0;
    for (final record in records) {
      final category = RecordPresenter.category(record);
      final amount = RecordPresenter.totalWithTip(record);
      totals[category] = (totals[category] ?? 0) + amount;
      counts[category] = (counts[category] ?? 0) + 1;
      total += amount;
    }
    if (total <= 0) {
      return const [];
    }

    final sortedCategories = totals.keys.toList()
      ..sort((a, b) => totals[b]!.compareTo(totals[a]!));
    final topCategory = sortedCategories.first;
    final topPct = (totals[topCategory]! / total * 100).round();

    final insights = <_Insight>[
      _Insight(
        icon: _iconFor(topCategory),
        title: '$topCategory 지출 비중이 높습니다',
        body:
            '전체 지출의 $topPct%가 $topCategory에 집중되어 있어요. 계획적인 소비를 위해 일정 후반으로 미뤄보세요.',
      ),
    ];

    if (counts.containsKey('식비')) {
      final mealAvg = (totals['식비']! / counts['식비']!).round();
      final won = NumberFormat('#,##0');
      insights.add(
        _Insight(
          icon: Icons.restaurant_outlined,
          title: '식비를 조금 줄여보세요',
          body:
              '한 끼 평균 ${won.format(mealAvg)}원을 지출하고 있어요. 현지 시장이나 편의점을 활용하면 예산을 맞출 수 있습니다.',
        ),
      );
    }

    return insights.take(2).toList();
  }

  IconData _iconFor(String category) {
    switch (category) {
      case '쇼핑':
        return Icons.shopping_bag_outlined;
      case '교통':
        return Icons.directions_bus_outlined;
      case '숙박':
        return Icons.hotel_outlined;
      default:
        return Icons.restaurant_outlined;
    }
  }
}

class _Insight {
  const _Insight({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});

  final _Insight insight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(insight.icon, size: 17, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(insight.title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(insight.body, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
