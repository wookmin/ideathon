import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/receipt_record.dart';
import '../models/travel.dart';
import '../providers/ledger_provider.dart';
import '../providers/travel_selection_provider.dart';
import '../utils/record_presenter.dart';
import '../widgets/header_menu_overlay.dart';
import '../widgets/main_bottom_nav.dart';
import 'ledger_detail_screen.dart';
import 'ledger_screen.dart';
import 'manual_entry_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';
import 'travel_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(ledgerProvider);
    final selectedTravel = ref.watch(effectiveTravelProvider);
    final scopedRecords = scopedRecordsForTravel(records, selectedTravel);
    final recent = scopedRecords.take(2).toList();
    final totalKrw = RecordPresenter.totalSpend(scopedRecords);
    final budget =
        selectedTravel?.budgetKrw ?? RecordPresenter.budgetGoal(records);
    final progress = budget <= 0 ? 0.0 : (totalKrw / budget).clamp(0.0, 0.999);
    final latest = scopedRecords.isEmpty ? null : scopedRecords.first;
    final displayCurrency = _displayCurrency(scopedRecords, selectedTravel);
    final originalAmount = _displayOriginalAmount(
      scopedRecords,
      displayCurrency,
    );
    final originalSymbol = RecordPresenter.symbol(displayCurrency);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add_rounded, size: 34),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                  child: _HomeHeader(
                    title: 'OneShot',
                    travelTitle:
                        selectedTravel?.title ??
                        RecordPresenter.travelTitle(records),
                    period: selectedTravel != null
                        ? displayPeriodForTravel(selectedTravel)
                        : RecordPresenter.travelDateRange(records),
                    status: selectedTravel != null
                        ? displayStatusForTravel(selectedTravel)
                        : RecordPresenter.statusLabel(records),
                    onMenuTap: () {
                      setState(() => _isMenuOpen = !_isMenuOpen);
                    },
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
                    children: [
                      _BudgetGauge(progress: progress),
                      const SizedBox(height: 22),
                      _BudgetCard(
                        originalAmount: originalAmount,
                        originalSymbol: originalSymbol,
                        currency: displayCurrency,
                        usedKrw: totalKrw,
                        remainingKrw: math.max(0, budget - totalKrw),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Text(
                            '최근 지출 내역',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LedgerScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('전체보기'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (recent.isEmpty)
                        _EmptyRecentCard(onTap: () => _showAddSheet(context))
                      else
                        ...recent.map(
                          (record) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _RecentExpenseTile(
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
                      const SizedBox(height: 24),
                      if (selectedTravel != null)
                        _SelectedTravelSummaryCard(
                          travelTitle: selectedTravel.title,
                        )
                      else if (latest != null)
                        _TravelSummaryCard(record: latest)
                      else
                        const _TravelPlaceholderCard(),
                    ],
                  ),
                ),
              ],
            ),
            HeaderMenuOverlay(
              isOpen: _isMenuOpen,
              dimTopOffset: 94,
              onDismiss: () => setState(() => _isMenuOpen = false),
              onTravelTap: () {
                setState(() => _isMenuOpen = false);
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

  String _displayCurrency(List<ReceiptRecord> records, Travel? selectedTravel) {
    for (final record in records) {
      if (record.currency != 'KRW') {
        return record.currency;
      }
    }
    if (selectedTravel != null &&
        selectedTravel.exchangeTargetCurrency.isNotEmpty) {
      return selectedTravel.exchangeTargetCurrency;
    }
    return records.isEmpty ? 'KRW' : records.first.currency;
  }

  double _displayOriginalAmount(List<ReceiptRecord> records, String currency) {
    final matching = records
        .where((record) => record.currency == currency)
        .toList();
    if (matching.isEmpty) {
      return 0;
    }
    return matching.fold<double>(
      0,
      (sum, record) => sum + record.originalAmount + _tipInOriginal(record),
    );
  }

  double _tipInOriginal(ReceiptRecord record) {
    if (record.tipPct <= 0) {
      return 0;
    }
    return record.originalAmount * (record.tipPct / 100);
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return _AddExpenseSheet(
          onScanTap: () {
            Navigator.of(bottomSheetContext).pop();
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ScanScreen()));
          },
          onManualTap: () {
            Navigator.of(bottomSheetContext).pop();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ManualEntryScreen()),
            );
          },
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.title,
    required this.travelTitle,
    required this.period,
    required this.status,
    required this.onMenuTap,
  });

  final String title;
  final String travelTitle;
  final String period;
  final String status;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 31,
                color: AppTheme.primary,
              ),
            ),
            const Spacer(),
            HeaderMenuToggleButton(onTap: onMenuTap),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Flexible(
              child: Text(
                travelTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppTheme.primary),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                period,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF7C879B),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _StatusChip(status: status),
          ],
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDCE8FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: AppTheme.primary),
      ),
    );
  }
}

class _BudgetGauge extends StatelessWidget {
  const _BudgetGauge({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 176,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _GaugePainter(progress: progress)),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '전체 예산 중',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF8D96A8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 38,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '사용했어요',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF8D96A8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = math.min(size.width / 2, size.height) - 14;
    const startAngle = math.pi;
    const sweepAngle = math.pi;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = const Color(0xFFF0F1F3)
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, backgroundPaint);
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.originalAmount,
    required this.originalSymbol,
    required this.currency,
    required this.usedKrw,
    required this.remainingKrw,
  });

  final double originalAmount;
  final String originalSymbol;
  final String currency;
  final double usedKrw;
  final double remainingKrw;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
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
            top: -6,
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
              const SizedBox(height: 34),
              Row(
                children: [
                  Text(
                    '잔여예산',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    '${NumberFormat('#,##0').format(remainingKrw)}원',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentExpenseTile extends StatelessWidget {
  const _RecentExpenseTile({required this.record, required this.onTap});

  final ReceiptRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFCFCFD),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FB),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(_categoryIcon(record), color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '- ${RecordPresenter.amountWithSymbol(record.currency, record.originalAmount)}',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: AppTheme.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${RecordPresenter.title(record)} (${RecordPresenter.locationLabel(record)}) | ${RecordPresenter.category(record)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFB0B8C8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRecentCard extends StatelessWidget {
  const _EmptyRecentCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFD),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            color: AppTheme.primary,
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            '아직 저장된 지출이 없어요',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '영수증 스캔이나 직접 입력으로 첫 지출을 추가해 주세요.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(minimumSize: const Size(180, 50)),
            child: const Text('상세 내역 추가'),
          ),
        ],
      ),
    );
  }
}

class _TravelSummaryCard extends StatelessWidget {
  const _TravelSummaryCard({required this.record});

  final ReceiptRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE8FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                RecordPresenter.flag(record.countryCode),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '최근 여행 메모',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  RecordPresenter.title(record),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  RecordPresenter.shortDate(record.date),
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

class _SelectedTravelSummaryCard extends StatelessWidget {
  const _SelectedTravelSummaryCard({required this.travelTitle});

  final String travelTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE8FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Icon(
                Icons.luggage_rounded,
                color: AppTheme.primary,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '선택된 여행',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF99A1B3),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  travelTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '메인 적용 중',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}

class _TravelPlaceholderCard extends StatelessWidget {
  const _TravelPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE8FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.travel_explore_rounded,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('여행 준비 중', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '첫 영수증을 추가하면 여행 요약이 여기에 표시됩니다.',
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

class _AddExpenseSheet extends StatelessWidget {
  const _AddExpenseSheet({required this.onScanTap, required this.onManualTap});

  final VoidCallback onScanTap;
  final VoidCallback onManualTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 284),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Spacer(),
                Text(
                  '상세 내역 추가',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: const Color(0xFFB7BEC9),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ActionCard(
                    backgroundColor: AppTheme.primary,
                    iconBackground: Colors.white.withValues(alpha: 0.14),
                    icon: Icons.photo_camera_outlined,
                    label: '영수증 스캔',
                    labelColor: Colors.white,
                    onTap: onScanTap,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _ActionCard(
                    backgroundColor: const Color(0xFFF2F3F5),
                    iconBackground: const Color(0xFFE7EBF3),
                    icon: Icons.edit_outlined,
                    label: '직접 입력',
                    labelColor: AppTheme.primary,
                    onTap: onManualTap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.backgroundColor,
    required this.iconBackground,
    required this.icon,
    required this.label,
    required this.labelColor,
    required this.onTap,
  });

  final Color backgroundColor;
  final Color iconBackground;
  final IconData icon;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        height: 164,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: labelColor, size: 30),
            ),
            const SizedBox(height: 18),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: labelColor),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _categoryIcon(ReceiptRecord record) {
  switch (RecordPresenter.category(record)) {
    case '교통':
      return Icons.luggage_rounded;
    case '숙박':
      return Icons.hotel_rounded;
    case '쇼핑':
      return Icons.shopping_bag_outlined;
    default:
      return Icons.restaurant_rounded;
  }
}
