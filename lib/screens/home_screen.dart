import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../providers/ledger_provider.dart';
import '../utils/record_presenter.dart';
import '../widgets/main_bottom_nav.dart';
import 'ledger_detail_screen.dart';
import 'ledger_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(ledgerProvider);
    final recent = records.take(3).toList();
    final total = RecordPresenter.totalSpend(records);
    final monthSpend = RecordPresenter.monthlySpend(records);
    final average = RecordPresenter.dailyAverage(records);
    final budget = RecordPresenter.budgetGoal(records);
    final progress = total == 0 ? 0.0 : (total / budget).clamp(0, 1).toDouble();

    return Scaffold(
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
      body: SafeArea(
        child: ListView(
          padding: AppTheme.screenPadding.copyWith(top: 18, bottom: 20),
          children: [
            const _Header(),
            const SizedBox(height: 18),
            _HeroCard(
              title: RecordPresenter.travelTitle(records),
              subtitle: RecordPresenter.travelDateRange(records),
              status: RecordPresenter.statusLabel(records),
              total: total,
              monthSpend: monthSpend,
              progress: progress,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: '이번 달 지출',
                    value: '₩${NumberFormat('#,##0').format(monthSpend)}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: '일평균 지출',
                    value: '₩${NumberFormat('#,##0').format(average)}',
                    emphasized: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: '최다 카테고리',
                    value: RecordPresenter.topCategory(records),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: '저장 건수',
                    value: '${records.length}건',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('최근 지출 내역', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LedgerScreen()),
                    );
                  },
                  child: const Text('전체보기'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              _EmptyState(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ScanScreen()),
                  );
                },
              )
            else
              ...recent.map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _RecentExpenseCard(
                    record: record,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LedgerDetailScreen(record: record),
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 18),
            _ScanCta(
              recordCount: records.length,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ScanScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFFDCEBFF),
          child: Icon(Icons.flight_takeoff_rounded, color: AppTheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('여행 지출 대시보드', style: Theme.of(context).textTheme.labelMedium),
              Text('TripReceipt', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.primary,
          ),
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.total,
    required this.monthSpend,
    required this.progress,
  });

  final String title;
  final String subtitle;
  final String status;
  final double total;
  final double monthSpend;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryStrong],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '₩${NumberFormat('#,##0').format(total)}',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '이번 달 지출 ₩${NumberFormat('#,##0').format(monthSpend)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                '예산 진행률',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 26,
            decoration: BoxDecoration(
              color: emphasized ? AppTheme.primaryStrong : AppTheme.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentExpenseCard extends StatelessWidget {
  const _RecentExpenseCard({
    required this.record,
    required this.onTap,
  });

  final dynamic record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppTheme.line),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(_categoryIcon(record), color: AppTheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${RecordPresenter.flag(record.countryCode)} ${RecordPresenter.title(record)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${RecordPresenter.category(record)} · ${RecordPresenter.relativeDate(record.date)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₩${NumberFormat('#,##0').format(RecordPresenter.totalWithTip(record))}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  RecordPresenter.amountWithSymbol(record.currency, record.originalAmount),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_rounded, size: 48, color: AppTheme.primary),
          const SizedBox(height: 12),
          Text('저장된 영수증이 없습니다.', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '첫 영수증을 스캔하면 대시보드가 실제 데이터로 채워집니다.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onTap, child: const Text('영수증 스캔하기')),
        ],
      ),
    );
  }
}

class _ScanCta extends StatelessWidget {
  const _ScanCta({
    required this.recordCount,
    required this.onTap,
  });

  final int recordCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF93C5FD), Color(0xFF2563EB)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 22,
              top: 22,
              right: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '새 영수증 스캔',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '촬영 또는 갤러리에서 불러와 OCR과 AI 분석을 바로 시작합니다.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.86),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 22,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  recordCount == 0 ? '첫 분석 시작하기' : '$recordCount건 저장됨',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const Positioned(
              right: 18,
              bottom: 18,
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(Icons.camera_alt_rounded, color: AppTheme.primaryStrong),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _categoryIcon(dynamic record) {
  switch (RecordPresenter.category(record)) {
    case '교통':
      return Icons.train_rounded;
    case '숙박':
      return Icons.bed_outlined;
    case '쇼핑':
      return Icons.shopping_bag_outlined;
    default:
      return Icons.restaurant_outlined;
  }
}
