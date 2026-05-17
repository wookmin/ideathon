import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/receipt_record.dart';
import '../providers/ledger_provider.dart';
import '../utils/record_presenter.dart';
import '../widgets/main_bottom_nav.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'travel_list_screen.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(ledgerProvider);
    final summary = _AnalysisSummary.fromRecords(records);
    final budget = RecordPresenter.budgetGoal(records);
    final displayCurrency = _displayCurrency(records);
    final originalAmount = _displayOriginalAmount(records, displayCurrency);

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
          children: [
            _AnalysisHeader(
              onBackTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => route.isFirst,
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              '여행 소비 내역 분석',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              '소비 데이터를 자동으로 분석해 여행 중\n지출 흐름을 한눈에 보여드려요',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF98A2B3)),
            ),
            const SizedBox(height: 22),
            _AnalysisGauge(summary: summary),
            const SizedBox(height: 10),
            Text(
              'AI 인사이트',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.primary),
            ),
            const SizedBox(height: 4),
            Text(
              summary.insight,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.primary),
            ),
            const SizedBox(height: 22),
            _CategorySpendCard(summary: summary),
            const SizedBox(height: 20),
            _AnalysisBudgetCard(
              originalAmount: originalAmount,
              currency: displayCurrency,
              originalSymbol: RecordPresenter.symbol(displayCurrency),
              usedKrw: summary.totalKrw,
              remainingKrw: math.max(0, budget - summary.totalKrw),
            ),
          ],
        ),
      ),
    );
  }

  String _displayCurrency(List<ReceiptRecord> records) {
    for (final record in records) {
      if (record.currency != 'KRW') {
        return record.currency;
      }
    }
    return records.isEmpty ? 'EUR' : records.first.currency;
  }

  double _displayOriginalAmount(List<ReceiptRecord> records, String currency) {
    final matching = records.where((record) => record.currency == currency);
    final total = matching.fold<double>(
      0,
      (sum, record) =>
          sum +
          record.originalAmount +
          record.originalAmount * (record.tipPct / 100),
    );
    return total == 0 ? 985.42 : total;
  }
}

class _AnalysisHeader extends StatelessWidget {
  const _AnalysisHeader({required this.onBackTap});

  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBackTap,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: const Color(0xFFC2C7D1),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        ),
        const Spacer(),
        _HeaderMenuButton(),
      ],
    );
  }
}

class _HeaderMenuButton extends StatelessWidget {
  const _HeaderMenuButton();

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_HeaderMenuAction>(
      tooltip: '메뉴',
      offset: const Offset(-8, 46),
      color: Colors.white,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      onSelected: (value) {
        final route = switch (value) {
          _HeaderMenuAction.travel => MaterialPageRoute(
            builder: (_) => const TravelListScreen(),
          ),
          _HeaderMenuAction.settings => MaterialPageRoute(
            builder: (_) => const SettingsScreen(),
          ),
        };
        Navigator.of(context).push(route);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _HeaderMenuAction.travel,
          height: 48,
          child: Text(
            '나의 여행 목록',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.primary),
          ),
        ),
        PopupMenuItem(
          value: _HeaderMenuAction.settings,
          height: 48,
          child: Text(
            '환경 설정',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.primary),
          ),
        ),
      ],
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.menu_rounded, size: 32, color: AppTheme.primary),
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
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFC),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('카테고리별 지출', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 18),
          for (final item in summary.items) ...[
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Text(
                  '${NumberFormat('#,##0').format(item.amount)}원',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 18),
                SizedBox(
                  width: 42,
                  child: Text(
                    '${item.percent.round()}%',
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF98A2B3),
                    ),
                  ),
                ),
              ],
            ),
            if (item != summary.items.last) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _AnalysisBudgetCard extends StatelessWidget {
  const _AnalysisBudgetCard({
    required this.originalAmount,
    required this.currency,
    required this.originalSymbol,
    required this.usedKrw,
    required this.remainingKrw,
  });

  final double originalAmount;
  final String currency;
  final String originalSymbol;
  final double usedKrw;
  final double remainingKrw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryStrong],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -8,
            child: Icon(
              Icons.euro_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '지금까지 사용한 금액',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '$originalSymbol${originalAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontSize: 42, color: Colors.white),
                    ),
                    TextSpan(
                      text: currency,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '≈ ${NumberFormat('#,##0').format(usedKrw)}원 KRW',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              Text(
                '잔여예산 ${NumberFormat('#,##0').format(remainingKrw)}원',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ],
          ),
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

  factory _AnalysisSummary.fromRecords(List<ReceiptRecord> records) {
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
    final dailyAverage = RecordPresenter.dailyAverage(records);
    final leadingSpend = dailyAverage == 0
        ? leading.amount
        : math.max(0, leading.amount - dailyAverage);
    final insight = totalKrw == 0
        ? '아직 분석할 지출 데이터가 없어요. 첫 영수증을 추가해 보세요.'
        : '${leading.label}에서 하루 권장 사용 금액보다 ${NumberFormat('#,##0').format(leadingSpend)}원 사용 중이에요';

    return _AnalysisSummary(items: items, totalKrw: totalKrw, insight: insight);
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

enum _HeaderMenuAction { travel, settings }
