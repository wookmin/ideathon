import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/receipt_record.dart';
import '../providers/ledger_provider.dart';
import '../utils/record_presenter.dart';
import '../widgets/main_bottom_nav.dart';
import 'ledger_detail_screen.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  String _searchQuery = '';
  String _filter = '전체';

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(ledgerProvider);
    final filtered = records.where((record) {
      final querySource =
          '${record.memo} ${record.country} ${record.city} ${record.rawOcrText}'
              .toLowerCase();
      final matchesQuery =
          _searchQuery.isEmpty ||
          querySource.contains(_searchQuery.toLowerCase());
      final category = RecordPresenter.category(record);
      final matchesFilter =
          _filter == '전체' ||
          _filter == category ||
          (_filter == '최근 30일' &&
              record.date.isAfter(
                DateTime.now().subtract(const Duration(days: 30)),
              ));
      return matchesQuery && matchesFilter;
    }).toList();
    final grouped = _groupByDate(filtered);
    final monthTotal = filtered.fold<double>(
      0,
      (sum, record) => sum + RecordPresenter.totalWithTip(record),
    );

    return Scaffold(
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            decoration: const BoxDecoration(
              color: AppTheme.background,
              border: Border(top: BorderSide(color: AppTheme.line)),
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.primaryStrong,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '이번 달 총 지출',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₩${NumberFormat('#,##0').format(monthTotal)}',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${filtered.length}건',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const MainBottomNav(currentIndex: 0),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: AppTheme.screenPadding.copyWith(top: 18, bottom: 12),
          children: [
            const _Header(),
            const SizedBox(height: 18),
            TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(
                hintText: '거래 내역 검색...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final filter in const [
                    '전체',
                    '최근 30일',
                    '식비',
                    '교통',
                    '숙박',
                    '쇼핑',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                        selectedColor: AppTheme.primary,
                        backgroundColor: AppTheme.surface,
                        labelStyle: TextStyle(
                          color: _filter == filter
                              ? Colors.white
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: const BorderSide(color: AppTheme.line),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (filtered.isEmpty)
              _EmptyLedgerState(
                records.isEmpty ? '저장된 영수증이 없습니다.' : '검색 조건과 일치하는 기록이 없습니다.',
              )
            else
              for (final entry in grouped.entries) ...[
                Row(
                  children: [
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Text(
                      RecordPresenter.monthLabel(entry.value.first.date),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...entry.value.map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Dismissible(
                      key: ValueKey(record.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: AppTheme.bad.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.bad,
                        ),
                      ),
                      onDismissed: (_) {
                        ref.read(ledgerProvider.notifier).delete(record.id);
                      },
                      child: _LedgerCard(
                        record: record,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  LedgerDetailScreen(record: record),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Map<String, List<ReceiptRecord>> _groupByDate(List<ReceiptRecord> records) {
    final grouped = <String, List<ReceiptRecord>>{};
    for (final record in records) {
      final key = RecordPresenter.sectionLabel(record.date);
      grouped.putIfAbsent(key, () => []).add(record);
    }
    return grouped;
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: AppTheme.surfaceAlt,
          child: Icon(Icons.receipt_long_rounded, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '거래 기록',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Text(
          '${DateTime.now().year}년 ${DateTime.now().month}월',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}

class _LedgerCard extends StatelessWidget {
  const _LedgerCard({required this.record, required this.onTap});

  final ReceiptRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.line),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
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
                    '${RecordPresenter.locationLabel(record)} • ${RecordPresenter.category(record)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    RecordPresenter.shortDate(record.date),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  RecordPresenter.amountWithSymbol(
                    record.currency,
                    record.originalAmount,
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: AppTheme.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  '₩${NumberFormat('#,##0').format(RecordPresenter.totalWithTip(record))}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                _VerdictPill(verdict: record.verdict),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VerdictPill extends StatelessWidget {
  const _VerdictPill({required this.verdict});

  final String verdict;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (verdict) {
      case 'fair':
        color = AppTheme.ok;
        label = '합리적';
      case 'pricey':
        color = AppTheme.warn;
        label = '주의';
      case 'rip':
        color = AppTheme.bad;
        label = '의심';
      default:
        color = AppTheme.textSecondary;
        label = '보류';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _EmptyLedgerState extends StatelessWidget {
  const _EmptyLedgerState(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.line),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

IconData _categoryIcon(ReceiptRecord record) {
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
