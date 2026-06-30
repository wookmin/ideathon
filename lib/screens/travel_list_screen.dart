import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/receipt_record.dart';
import '../models/travel.dart';
import '../providers/ledger_provider.dart';
import '../providers/travel_provider.dart';
import '../providers/travel_selection_provider.dart';
import '../utils/record_presenter.dart';
import '../widgets/header_menu_overlay.dart';
import '../widgets/main_bottom_nav.dart';
import 'new_trip_screen.dart';
import 'home_screen.dart';
import 'notification_list_screen.dart';
import 'settings_screen.dart';

class TravelListScreen extends ConsumerStatefulWidget {
  const TravelListScreen({super.key, this.startupMode = false});

  final bool startupMode;

  @override
  ConsumerState<TravelListScreen> createState() => _TravelListScreenState();
}

class _TravelListScreenState extends ConsumerState<TravelListScreen> {
  String _searchQuery = '';
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final travels = ref.watch(travelProvider);
    final records = ref.watch(ledgerProvider);
    final selectedTravel = ref.watch(effectiveTravelProvider);
    final selectedTravelId = ref.watch(selectedTravelIdProvider);
    final filteredTravels = travels.where((travel) {
      if (_searchQuery.trim().isEmpty) {
        return true;
      }
      final query = _searchQuery.trim().toLowerCase();
      return travel.title.toLowerCase().contains(query) ||
          travel.country.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
      bottomNavigationBar: widget.startupMode
          ? null
          : const MainBottomNav(currentIndex: 1),
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
                              _openHome(context);
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
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('필터 기능은 준비 중입니다.')),
                            );
                          },
                          icon: const Icon(
                            Icons.filter_list_rounded,
                            color: Color(0xFF737682),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectedTravelId != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () async {
                          await ref
                              .read(selectedTravelIdProvider.notifier)
                              .clear();
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('자동으로 현재 여행을 다시 선택하도록 변경했어요.'),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('자동 선택으로 돌아가기'),
                      ),
                    ),
                  ),
                Expanded(
                  child: filteredTravels.isEmpty
                      ? const _EmptyTravelState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          itemBuilder: (context, index) {
                            final travel = filteredTravels[index];
                            final summary = _TravelCardSummary.fromTravel(
                              travel: travel,
                              records: records,
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
                                  _openHome(context);
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

void _openHome(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const HomeScreen()),
    (route) => false,
  );
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isSelected ? AppTheme.primary : const Color(0xFFE9EDF5),
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0x221768E6)
                    : const Color(0x0A0F172A),
                blurRadius: isSelected ? 24 : 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: summary.statusBackground,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            summary.statusLabel,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: summary.statusTextColor,
                                  fontSize: 15,
                                ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCE8FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '메인 적용 중',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: AppTheme.primary),
                            ),
                          ),
                        ],
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: Color(0xFF7B8095),
                          ),
                          onSelected: (value) {
                            if (value == 'delete') onDelete();
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '삭제',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                summary.travel.title,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_outlined,
                                    size: 20,
                                    color: Color(0xFF9AA0AE),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      summary.periodLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: const Color(0xFF9AA0AE),
                                            fontSize: 17,
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: summary.accentColor),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '₩${NumberFormat('#,##0').format(summary.amountValue)}',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(color: summary.accentColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text(
                          summary.progressLabel,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: summary.accentColor,
                                fontSize: 18,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          '₩${NumberFormat('#,##0').format(summary.travel.budgetKrw)}',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: const Color(0xFF5B6170),
                                fontSize: 18,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 12,
                        value: summary.progress,
                        backgroundColor: const Color(0xFFE7E8EC),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          summary.progressBarColor,
                        ),
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
    required this.progressLabel,
    required this.accentColor,
    required this.statusBackground,
    required this.statusTextColor,
    required this.progressBarColor,
  });

  final Travel travel;
  final double usedKrw;
  final double progress;
  final String periodLabel;
  final String statusLabel;
  final String amountLabel;
  final double amountValue;
  final String progressLabel;
  final Color accentColor;
  final Color statusBackground;
  final Color statusTextColor;
  final Color progressBarColor;

  factory _TravelCardSummary.fromTravel({
    required Travel travel,
    required List<ReceiptRecord> records,
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
    String progressLabel;
    Color accentColor;
    Color statusBackground;
    Color statusTextColor;
    Color progressBarColor;

    if (today.isBefore(start)) {
      final diff = start.difference(today).inDays;
      statusLabel = 'D-$diff';
      amountLabel = '목표 예산';
      amountValue = travel.budgetKrw;
      progressLabel = '0% 사용됨';
      accentColor = const Color(0xFFADC8FF);
      statusBackground = const Color(0xFFF1F1F2);
      statusTextColor = const Color(0xFFA6A6AB);
      progressBarColor = const Color(0xFFD9DBE1);
    } else if (today.isAfter(end)) {
      statusLabel = '종료됨';
      amountLabel = '총 지출';
      amountValue = usedKrw;
      progressLabel = usedKrw >= travel.budgetKrw
          ? '모두 사용'
          : '${(progress * 100).round()}% 사용됨';
      accentColor = const Color(0xFFFF3030);
      statusBackground = const Color(0xFFF1F1F2);
      statusTextColor = const Color(0xFFA6A6AB);
      progressBarColor = const Color(0xFFFF3030);
    } else {
      statusLabel = '진행 중';
      amountLabel = '남은 예산';
      amountValue = (travel.budgetKrw - usedKrw)
          .clamp(0, double.infinity)
          .toDouble();
      progressLabel = '${(progress * 100).round()}% 사용됨';
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
      progressLabel: progressLabel,
      accentColor: accentColor,
      statusBackground: statusBackground,
      statusTextColor: statusTextColor,
      progressBarColor: progressBarColor,
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
