import 'dart:math' as math;

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
import '../widgets/header_menu_overlay.dart';
import '../widgets/main_bottom_nav.dart';
import 'budget_forecast_detail_screen.dart';
import 'ledger_detail_screen.dart';
import 'ledger_screen.dart';
import 'manual_entry_screen.dart';
import 'scan_screen.dart';
import 'notification_list_screen.dart';
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
    final forecast = const BudgetForecastService().calculate(
      travel: selectedTravel,
      records: scopedRecords,
    );
    final recent = scopedRecords.take(2).toList();
    final totalKrw = RecordPresenter.totalSpend(scopedRecords);
    final budget =
        selectedTravel?.budgetKrw ?? RecordPresenter.budgetGoal(records);
    final progress = budget <= 0 ? 0.0 : (totalKrw / budget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 12,
        shape: const CircleBorder(),
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add_rounded, size: 34),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
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
                  onNotificationTap: () {
                    setState(() => _isMenuOpen = false);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationListScreen(),
                      ),
                    );
                  },
                  onMenuTap: () {
                    setState(() => _isMenuOpen = !_isMenuOpen);
                  },
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 96),
                    children: [
                      _TripHeroCard(
                        travelTitle:
                            selectedTravel?.title ??
                            RecordPresenter.travelTitle(records),
                        period: selectedTravel != null
                            ? displayPeriodForTravel(selectedTravel)
                            : RecordPresenter.travelDateRange(records),
                        forecast: forecast,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const BudgetForecastDetailScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _BudgetGauge(progress: progress),
                      const SizedBox(height: 12),
                      _BudgetSummaryCards(
                        remainingKrw: math.max(0, budget - totalKrw),
                        safeBudgetKrw: forecast.safeDailyBudgetKrw,
                      ),
                      const SizedBox(height: 30),
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

class _TripHeroCard extends StatelessWidget {
  const _TripHeroCard({
    required this.travelTitle,
    required this.period,
    required this.forecast,
    required this.onTap,
  });

  final String travelTitle;
  final String period;
  final BudgetForecast forecast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dayLabel = _dayLabel;
    final caption = _caption;
    final tripDay = sustainableTripDay(forecast);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.fromLTRB(20, 17, 18, 16),
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
                top: 32,
                child: SvgPicture.asset(
                  'assets/design/icons/airplane.svg',
                  width: 104,
                  height: 91,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          travelTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        period,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: Colors.white, height: 1.08),
                        children: [TextSpan(text: dayLabel)],
                      ),
                    ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '예측보기',
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _dayLabel {
    if (forecast.travel == null) return '여행 준비';
    if (forecast.elapsedDays <= 0) return '출발 전';
    final tripDay = sustainableTripDay(forecast);
    if (tripDay != null) return '$tripDay일째';
    return '${forecast.elapsedDays}일째';
  }

  String get _caption {
    if (forecast.travel == null) {
      return '여행을 추가하고 예산 알림을 시작해요';
    }
    final tripDay = sustainableTripDay(forecast);
    if (tripDay != null) {
      final shortfall = forecast.totalDays - tripDay;
      if (shortfall > 0) {
        return '여행 종료까지 ${forecast.totalDays}일 | $shortfall일 부족';
      }
      return '이 속도면 여행 끝까지 예산이 충분해요';
    }
    if (forecast.remainingDays <= 1) {
      return '여행 마지막 날까지 예산을 확인해요';
    }
    return '여행 종료까지 ${forecast.remainingDays}일이 남았어요';
  }
}

class _BudgetSummaryCards extends StatelessWidget {
  const _BudgetSummaryCards({
    required this.remainingKrw,
    required this.safeBudgetKrw,
  });

  final double remainingKrw;
  final double safeBudgetKrw;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BudgetSummaryCard(
            label: '남은 예산',
            value: _formatWon(remainingKrw),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _BudgetSummaryCard(
            label: '하루 적정',
            value: _formatWon(safeBudgetKrw),
          ),
        ),
      ],
    );
  }

  String _formatWon(double value) {
    return '₩${NumberFormat('#,##0').format(value)}';
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF97A0B4),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 14,
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
      height: 214,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _GaugePainter(progress: progress)),
          ),
          Positioned(
            top: 82,
            child: Column(
              children: [
                Text(
                  '전체 예산 중',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF9AA4B8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(progress * 100).round()}%',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 44,
                    height: 1.0,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '사용했어요',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF9AA4B8),
                  ),
                ),
              ],
            ),
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
    final strokeWidth = size.width * 0.07;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, radius + strokeWidth / 2 + 20);
    const startAngle = math.pi;
    const sweepAngle = math.pi;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = const Color(0xFFF0F2F5)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = strokeWidth
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

class _RecentExpenseTile extends StatelessWidget {
  const _RecentExpenseTile({required this.record, required this.onTap});

  final ReceiptRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(record),
                  color: AppTheme.textPrimary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '- ${RecordPresenter.amountWithSymbol(record.currency, record.originalAmount)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
