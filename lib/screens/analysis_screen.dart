import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/receipt_record.dart';
import '../providers/ledger_provider.dart';
import '../providers/travel_selection_provider.dart';
import '../services/budget_forecast_service.dart';
import '../utils/record_presenter.dart';
import '../widgets/header_menu_overlay.dart';
import '../widgets/main_bottom_nav.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'travel_list_screen.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(ledgerProvider);
    final selectedTravel = ref.watch(effectiveTravelProvider);
    final scopedRecords = scopedRecordsForTravel(records, selectedTravel);
    final forecast = const BudgetForecastService().calculate(
      travel: selectedTravel,
      records: scopedRecords,
    );
    final summary = _AnalysisSummary.fromRecords(
      scopedRecords,
      forecast: forecast,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                AppTopHeader(
                  travelTitle:
                      selectedTravel?.title ??
                      RecordPresenter.travelTitle(records),
                  period: selectedTravel != null
                      ? displayPeriodForTravel(selectedTravel)
                      : RecordPresenter.travelDateRange(records),
                  status: selectedTravel != null
                      ? displayStatusForTravel(selectedTravel)
                      : RecordPresenter.statusLabel(records),
                  onBackTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => route.isFirst,
                    );
                  },
                  onMenuTap: () {
                    setState(() => _isMenuOpen = !_isMenuOpen);
                  },
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 96),
                    children: [
                      Text(
                        '여행 소비 내역 분석',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        selectedTravel == null
                            ? '소비 데이터를 자동으로 분석해 여행 중\n지출 흐름을 한눈에 보여드려요'
                            : '${selectedTravel.title} 기준으로 지출 패턴을 분석해\n예산 흐름을 한눈에 보여드려요',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF98A2B3),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _AnalysisGauge(summary: summary),
                      const SizedBox(height: 10),
                      Text(
                        'AI 인사이트',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppTheme.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary.insight,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _CategorySpendCard(summary: summary),
                      const SizedBox(height: 20),
                      _ForecastInsightCard(forecast: forecast),
                    ],
                  ),
                ),
              ],
            ),
            HeaderMenuOverlay(
              isOpen: _isMenuOpen,
              dimTopOffset: AppTopHeader.menuDimTopOffset,
              onDismiss: () => setState(() => _isMenuOpen = false),
              onTravelTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TravelListScreen()),
                );
              },
              onSettingsTap: () {
                setState(() => _isMenuOpen = false);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastInsightCard extends StatelessWidget {
  const _ForecastInsightCard({required this.forecast});

  final BudgetForecast forecast;

  @override
  Widget build(BuildContext context) {
    final won = NumberFormat('#,##0');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '결제 전 절제 기준',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  forecast.travel == null
                      ? '여행 예산을 먼저 설정하면 위험 장소 진입 알림을 만들 수 있어요.'
                      : '오늘 ${won.format(forecast.safeDailyBudgetKrw)}원을 넘기는 결제는 멈칫 알림 대상이에요.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisGauge extends StatelessWidget {
  const _AnalysisGauge({required this.summary});

  final _AnalysisSummary summary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 184,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CategoryGaugePainter(summary: summary),
            ),
          ),
          Positioned(
            left: 28,
            top: 32,
            child: Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x140F172A),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    summary.leading.label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${summary.leading.percent.round()}%',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppTheme.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGaugePainter extends CustomPainter {
  const _CategoryGaugePainter({required this.summary});

  final _AnalysisSummary summary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = math.min(size.width / 2, size.height) - 22;
    const startAngle = math.pi;
    const totalSweep = math.pi;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final basePaint = Paint()
      ..color = const Color(0xFFF0F1F3)
      ..strokeWidth = 38
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, startAngle, totalSweep, false, basePaint);

    var currentAngle = startAngle;
    for (final category in summary.items.where((item) => item.amount > 0)) {
      final sweep = totalSweep * category.ratio;
      final paint = Paint()
        ..color = category.color
        ..strokeWidth = 38
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, currentAngle, sweep, false, paint);
      currentAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryGaugePainter oldDelegate) {
    return oldDelegate.summary != summary;
  }
}

class _CategorySpendCard extends StatelessWidget {
  const _CategorySpendCard({required this.summary});

  final _AnalysisSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('카테고리별 지출', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          for (final item in summary.items) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF667085),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${NumberFormat('#,##0').format(item.amount)}원',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: item.ratio.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFEAF0FA),
                valueColor: AlwaysStoppedAnimation<Color>(item.color),
              ),
            ),
            if (item != summary.items.last) const SizedBox(height: 17),
          ],
        ],
      ),
    );
  }
}

class _AnalysisSummary {
  const _AnalysisSummary({
    required this.items,
    required this.totalKrw,
    required this.insight,
  });

  final List<_CategoryAmount> items;
  final double totalKrw;
  final String insight;

  _CategoryAmount get leading => items.first;

  factory _AnalysisSummary.fromRecords(
    List<ReceiptRecord> records, {
    required BudgetForecast forecast,
  }) {
    final totals = <String, double>{'식비': 0, '교통비': 0, '쇼핑': 0, '숙박': 0};
    for (final record in records) {
      final amount = RecordPresenter.totalWithTip(record);
      final rawCategory = RecordPresenter.category(record);
      final label = switch (rawCategory) {
        '교통' => '교통비',
        _ => rawCategory,
      };
      totals[label] = (totals[label] ?? 0) + amount;
    }

    final totalKrw = totals.values.fold<double>(0, (sum, value) => sum + value);
    final items = [
      _CategoryAmount(
        label: '식비',
        color: const Color(0xFF1768E6),
        amount: totals['식비'] ?? 0,
        ratio: totalKrw == 0 ? 0 : (totals['식비'] ?? 0) / totalKrw,
      ),
      _CategoryAmount(
        label: '교통비',
        color: const Color(0xFF63A4FF),
        amount: totals['교통비'] ?? 0,
        ratio: totalKrw == 0 ? 0 : (totals['교통비'] ?? 0) / totalKrw,
      ),
      _CategoryAmount(
        label: '쇼핑',
        color: const Color(0xFFB7D4FF),
        amount: totals['쇼핑'] ?? 0,
        ratio: totalKrw == 0 ? 0 : (totals['쇼핑'] ?? 0) / totalKrw,
      ),
      _CategoryAmount(
        label: '숙박',
        color: const Color(0xFFD9E8FF),
        amount: totals['숙박'] ?? 0,
        ratio: totalKrw == 0 ? 0 : (totals['숙박'] ?? 0) / totalKrw,
      ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));

    final leading = items.first;
    final insight = _forecastInsight(forecast, totalKrw, leading.label);

    return _AnalysisSummary(items: items, totalKrw: totalKrw, insight: insight);
  }

  static String _forecastInsight(
    BudgetForecast forecast,
    double totalKrw,
    String leadingLabel,
  ) {
    final won = NumberFormat('#,##0');
    if (forecast.status == ForecastStatus.noTravel) {
      return '여행 예산을 설정하면 남은 일수 기준으로 소진 시점을 예측해요';
    }
    if (totalKrw == 0 || forecast.status == ForecastStatus.noSpend) {
      return '아직 분석할 지출 데이터가 없어요. 첫 영수증을 추가해 보세요.';
    }
    if (forecast.status == ForecastStatus.depleted) {
      return '예산을 이미 초과했어요. 다음 결제 전 절제 알림을 강하게 띄울게요.';
    }

    final depletionDate = forecast.projectedDepletionDate;
    if (depletionDate != null && forecast.travel != null) {
      final start = BudgetForecastService.dateOnly(forecast.travel!.startDate);
      final tripDay = depletionDate.difference(start).inDays + 1;
      return '현재 속도면 $tripDay일차에 예산이 소진돼요. 오늘 안전 소비 가능액은 ${won.format(forecast.safeDailyBudgetKrw)}원입니다.';
    }

    return '$leadingLabel 지출이 가장 커요. 오늘 안전 소비 가능액은 ${won.format(forecast.safeDailyBudgetKrw)}원입니다.';
  }
}

class _CategoryAmount {
  const _CategoryAmount({
    required this.label,
    required this.color,
    required this.amount,
    required this.ratio,
  });

  final String label;
  final Color color;
  final double amount;
  final double ratio;

  double get percent => ratio * 100;
}
