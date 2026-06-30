import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/receipt_record.dart';
import '../models/travel.dart';
import '../providers/exchange_provider.dart';
import '../providers/ledger_provider.dart';
import '../providers/travel_provider.dart';
import '../providers/travel_selection_provider.dart';
import '../utils/record_presenter.dart';
import '../widgets/header_menu_overlay.dart';
import 'new_trip_screen.dart';
import 'notification_list_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class TravelListScreen extends ConsumerStatefulWidget {
  const TravelListScreen({super.key, this.startupMode = false});

  final bool startupMode;

  @override
  ConsumerState<TravelListScreen> createState() => _TravelListScreenState();
}

class _TravelListScreenState extends ConsumerState<TravelListScreen> {
  String _searchQuery = '';
  _TravelFilter _filter = _TravelFilter.all;
  bool _isMenuOpen = false;

  void _openHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _showFilterSheet() async {
    final selected = await showModalBottomSheet<_TravelFilter>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A0F172A),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('여행 필터', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                for (final filter in _TravelFilter.values)
                  _FilterOptionTile(
                    filter: filter,
                    selected: _filter == filter,
                    onTap: () => Navigator.of(context).pop(filter),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) {
      setState(() => _filter = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final travels = ref.watch(travelProvider);
    final records = ref.watch(ledgerProvider);
    final exchangeRates = ref.watch(exchangeRatesProvider).valueOrNull;
    final selectedTravel = ref.watch(effectiveTravelProvider);
    final selectedTravelId = ref.watch(selectedTravelIdProvider);
    final today = _TravelCardSummary._dateOnly(DateTime.now());
    final filteredTravels =
        travels.where((travel) {
          final query = _searchQuery.trim().toLowerCase();
          final matchesQuery =
              query.isEmpty ||
              travel.title.toLowerCase().contains(query) ||
              travel.country.toLowerCase().contains(query);
          return matchesQuery && _filter.matches(travel);
        }).toList()..sort((a, b) {
          final distanceCompare = _distanceFromTravel(
            today,
            a,
          ).compareTo(_distanceFromTravel(today, b));
          if (distanceCompare != 0) {
            return distanceCompare;
          }
          final startCompare = a.startDate.compareTo(b.startDate);
          if (startCompare != 0) {
            return startCompare;
          }
          return b.createdAt.compareTo(a.createdAt);
        });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
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
                  onBackTap: () => Navigator.of(context).maybePop(),
                  onNotificationTap: () {
                    setState(() => _isMenuOpen = false);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationListScreen(),
                      ),
                    );
                  },
                  onMenuTap: () => setState(() => _isMenuOpen = !_isMenuOpen),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 38, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '나의 여행 목록',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: 16,
                                color: const Color(0xFF07126C),
                              ),
                        ),
                      ),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final createdTravelId = await Navigator.of(context)
                                .push<String>(
                                  MaterialPageRoute(
                                    builder: (_) => const NewTripScreen(),
                                  ),
                                );
                            if (!context.mounted) return;
                            if (widget.startupMode && createdTravelId != null) {
                              _openHome();
                            }
                          },
                          icon: const Icon(Icons.add_rounded, size: 24),
                          label: const Text('새 여행 추가'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: TextField(
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                            decoration: InputDecoration(
                              hintText: '여행지 검색...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              fillColor: const Color(0xFFF1EFEF),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1EFEF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          onPressed: _showFilterSheet,
                          icon: Icon(
                            Icons.filter_list_rounded,
                            color: _filter == _TravelFilter.all
                                ? Color(0xFF737682)
                                : AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredTravels.isEmpty
                      ? const _EmptyTravelState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
                          itemBuilder: (context, index) {
                            final travel = filteredTravels[index];
                            final summary = _TravelCardSummary.fromTravel(
                              travel: travel,
                              records: records,
                              localRate: exchangeRates?.rateFor(
                                travel.exchangeTargetCurrency,
                              ),
                            );
                            return _TravelCard(
                              summary: summary,
                              isSelected: selectedTravelId == travel.id,
                              onTap: () async {
                                await ref
                                    .read(selectedTravelIdProvider.notifier)
                                    .select(travel.id);
                                if (!context.mounted) return;
                                if (widget.startupMode) {
                                  _openHome();
                                  return;
                                }
                                Navigator.of(context).pop();
                              },
                              onDelete: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('여행 삭제'),
                                    content: Text(
                                      '\'${travel.title}\'을(를) 삭제할까요?\n이 작업은 되돌릴 수 없어요.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('취소'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        child: const Text('삭제'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true || !context.mounted) {
                                  return;
                                }
                                await ref
                                    .read(travelProvider.notifier)
                                    .delete(travel.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '\'${travel.title}\'을(를) 삭제했어요.',
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 18),
                          itemCount: filteredTravels.length,
                        ),
                ),
              ],
            ),
            HeaderMenuOverlay(
              isOpen: _isMenuOpen,
              dimTopOffset: AppTopHeader.menuDimTopOffset,
              onDismiss: () => setState(() => _isMenuOpen = false),
              onTravelTap: () => setState(() => _isMenuOpen = false),
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

int _distanceFromTravel(DateTime today, Travel travel) {
  final start = _TravelCardSummary._dateOnly(travel.startDate);
  final end = _TravelCardSummary._dateOnly(travel.endDate);

  if (!today.isBefore(start) && !today.isAfter(end)) {
    return 0;
  }
  if (today.isBefore(start)) {
    return start.difference(today).inDays;
  }
  return today.difference(end).inDays;
}

class _TravelCard extends StatelessWidget {
  const _TravelCard({
    required this.summary,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  final _TravelCardSummary summary;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final opacity = summary.isUpcoming || summary.isCompleted ? 0.48 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Container(
        height: 275,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D1A237E),
              blurRadius: 9.1,
              offset: Offset(4, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(height: 4, color: summary.progressBarColor),
            ),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _StatusPill(summary: summary),
                          const Spacer(),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: Color(0xFF747988),
                              size: 22,
                            ),
                            padding: EdgeInsets.zero,
                            onSelected: (value) {
                              if (value == 'delete') onDelete();
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  '삭제',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 27),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  summary.travel.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontSize: 16,
                                        color: const Color(0xFF252A35),
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 14,
                                      color: Color(0xFF9DA1AA),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        summary.periodLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: const Color(0xFF9DA1AA),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                summary.amountLabel,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(color: summary.accentColor),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₩${NumberFormat('#,##0').format(summary.amountValue)}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: summary.accentColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              if (summary.amountExchangeLabel != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  summary.amountExchangeLabel!,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: summary.accentColor.withValues(
                                          alpha: 0.72,
                                        ),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            summary.progressLabel,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: summary.progressTextColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                summary.budgetLabel,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: const Color(0xFF343946)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₩${NumberFormat('#,##0').format(summary.travel.budgetKrw)}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: const Color(0xFF50545F),
                                      fontSize: 16,
                                    ),
                              ),
                              if (summary.budgetExchangeLabel != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  summary.budgetExchangeLabel!,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: const Color(0xFF9DA1AA),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: summary.progress,
                          backgroundColor: const Color(0xFFE6E6E8),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            summary.progressBarColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TravelFilter {
  all('전체'),
  ongoing('진행 중'),
  upcoming('예정'),
  completed('종료');

  const _TravelFilter(this.label);

  final String label;

  bool matches(Travel travel) {
    final today = _TravelCardSummary._dateOnly(DateTime.now());
    final start = _TravelCardSummary._dateOnly(travel.startDate);
    final end = _TravelCardSummary._dateOnly(travel.endDate);

    return switch (this) {
      _TravelFilter.all => true,
      _TravelFilter.ongoing => !today.isBefore(start) && !today.isAfter(end),
      _TravelFilter.upcoming => today.isBefore(start),
      _TravelFilter.completed => today.isAfter(end),
    };
  }
}

class _FilterOptionTile extends StatelessWidget {
  const _FilterOptionTile({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final _TravelFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                filter.label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: selected ? AppTheme.primary : AppTheme.textPrimary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.summary});

  final _TravelCardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: summary.statusBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        summary.statusLabel,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: summary.statusTextColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyTravelState extends StatelessWidget {
  const _EmptyTravelState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.luggage_outlined,
              size: 54,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              '아직 여행 기록이 없어요',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '영수증을 저장하면 국가별 여행 목록이 여기에 정리됩니다.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TravelCardSummary {
  const _TravelCardSummary({
    required this.travel,
    required this.usedKrw,
    required this.progress,
    required this.periodLabel,
    required this.statusLabel,
    required this.amountLabel,
    required this.amountValue,
    required this.amountExchangeLabel,
    required this.budgetLabel,
    required this.budgetExchangeLabel,
    required this.progressLabel,
    required this.progressTextColor,
    required this.accentColor,
    required this.statusBackground,
    required this.statusTextColor,
    required this.progressBarColor,
    required this.isUpcoming,
    required this.isCompleted,
  });

  final Travel travel;
  final double usedKrw;
  final double progress;
  final String periodLabel;
  final String statusLabel;
  final String amountLabel;
  final double amountValue;
  final String? amountExchangeLabel;
  final String budgetLabel;
  final String? budgetExchangeLabel;
  final String progressLabel;
  final Color progressTextColor;
  final Color accentColor;
  final Color statusBackground;
  final Color statusTextColor;
  final Color progressBarColor;
  final bool isUpcoming;
  final bool isCompleted;

  factory _TravelCardSummary.fromTravel({
    required Travel travel,
    required List<ReceiptRecord> records,
    double? localRate,
  }) {
    final usedKrw = scopedRecordsForTravel(records, travel).fold<double>(
      0,
      (sum, record) => sum + RecordPresenter.totalWithTip(record),
    );

    final progress = travel.budgetKrw <= 0
        ? 0.0
        : (usedKrw / travel.budgetKrw).clamp(0.0, 1.0);
    final today = _dateOnly(DateTime.now());
    final start = _dateOnly(travel.startDate);
    final end = _dateOnly(travel.endDate);

    String statusLabel;
    String amountLabel;
    double amountValue;
    String budgetLabel;
    String progressLabel;
    Color progressTextColor;
    Color accentColor;
    Color statusBackground;
    Color statusTextColor;
    Color progressBarColor;

    if (today.isBefore(start)) {
      final diff = start.difference(today).inDays;
      statusLabel = 'D-$diff';
      amountLabel = '목표 예산';
      amountValue = travel.budgetKrw;
      budgetLabel = '';
      progressLabel = '0% 사용됨';
      progressTextColor = const Color(0xFF6FA5FF);
      accentColor = const Color(0xFFADC8FF);
      statusBackground = const Color(0xFFF1F1F2);
      statusTextColor = const Color(0xFFA6A6AB);
      progressBarColor = const Color(0xFFD9DBE1);
    } else if (today.isAfter(end)) {
      final overBudget = usedKrw >= travel.budgetKrw;
      statusLabel = '종료됨';
      amountLabel = '총 지출';
      amountValue = usedKrw;
      budgetLabel = '';
      progressLabel = overBudget ? '모두 사용' : '${(progress * 100).round()}% 사용됨';
      progressTextColor = overBudget
          ? const Color(0xFFFF3030)
          : const Color(0xFF9AA0AE);
      accentColor = overBudget
          ? const Color(0xFFFF3030)
          : const Color(0xFF9AA0AE);
      statusBackground = const Color(0xFFF1F1F2);
      statusTextColor = const Color(0xFFA6A6AB);
      progressBarColor = overBudget
          ? const Color(0xFFFF3030)
          : const Color(0xFF9AA0AE);
    } else {
      final dayNumber = today.difference(start).inDays + 1;
      statusLabel = '$dayNumber일 차';
      amountLabel = '남은 예산';
      amountValue = (travel.budgetKrw - usedKrw)
          .clamp(0, double.infinity)
          .toDouble();
      budgetLabel = '전체 예산';
      progressLabel = '${(progress * 100).round()}% 사용됨';
      progressTextColor = AppTheme.primary;
      accentColor = AppTheme.primary;
      statusBackground = const Color(0xFFDCE8FF);
      statusTextColor = AppTheme.primary;
      progressBarColor = AppTheme.primary;
    }

    return _TravelCardSummary(
      travel: travel,
      usedKrw: usedKrw,
      progress: progress,
      periodLabel:
          '${DateFormat('yyyy.MM.dd').format(travel.startDate)} - ${DateFormat('yyyy.MM.dd').format(travel.endDate)}',
      statusLabel: statusLabel,
      amountLabel: amountLabel,
      amountValue: amountValue,
      amountExchangeLabel: _exchangeLabel(
        currency: travel.exchangeTargetCurrency,
        krwAmount: amountValue,
        localRate: localRate,
      ),
      budgetLabel: budgetLabel,
      budgetExchangeLabel: _exchangeLabel(
        currency: travel.exchangeTargetCurrency,
        krwAmount: travel.budgetKrw,
        localRate: localRate,
      ),
      progressLabel: progressLabel,
      progressTextColor: progressTextColor,
      accentColor: accentColor,
      statusBackground: statusBackground,
      statusTextColor: statusTextColor,
      progressBarColor: progressBarColor,
      isUpcoming: today.isBefore(start),
      isCompleted: today.isAfter(end),
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String? _exchangeLabel({
    required String currency,
    required double krwAmount,
    required double? localRate,
  }) {
    final normalizedCurrency = currency.toUpperCase();
    if (normalizedCurrency == 'KRW' || localRate == null || localRate <= 0) {
      return null;
    }

    final localAmount = krwAmount * localRate;
    final symbol = RecordPresenter.symbol(normalizedCurrency);
    final formatter = _usesDecimal(normalizedCurrency)
        ? NumberFormat('#,##0.00')
        : NumberFormat('#,##0');

    if (symbol.isNotEmpty) {
      return '$symbol${formatter.format(localAmount)}';
    }
    return '$normalizedCurrency ${formatter.format(localAmount)}';
  }

  static bool _usesDecimal(String currency) {
    return switch (currency) {
      'USD' || 'EUR' || 'GBP' || 'AUD' || 'SGD' || 'HKD' => true,
      _ => false,
    };
  }
}
