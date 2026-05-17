import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/receipt_record.dart';
import '../models/travel.dart';
import '../providers/ledger_provider.dart';
import '../providers/travel_provider.dart';
import '../utils/record_presenter.dart';
import 'new_trip_screen.dart';

class TravelListScreen extends ConsumerStatefulWidget {
  const TravelListScreen({super.key});

  @override
  ConsumerState<TravelListScreen> createState() => _TravelListScreenState();
}

class _TravelListScreenState extends ConsumerState<TravelListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final travels = ref.watch(travelProvider);
    final records = ref.watch(ledgerProvider);
    final filteredTravels = travels.where((travel) {
      if (_searchQuery.trim().isEmpty) {
        return true;
      }
      final query = _searchQuery.trim().toLowerCase();
      return travel.title.toLowerCase().contains(query) ||
          travel.country.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('나의 여행 목록'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '나의 여행 목록',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: 24,
                            color: const Color(0xFF0A1C7A),
                          ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NewTripScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 28),
                    label: const Text('새 여행 추가'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 76),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: const InputDecoration(
                        hintText: '여행지 검색...',
                        prefixIcon: Icon(Icons.search_rounded),
                        fillColor: Color(0xFFF7F7FA),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7FA),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('필터 기능은 준비 중입니다.')),
                        );
                      },
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: Color(0xFF7B8095),
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
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      itemBuilder: (context, index) {
                        final travel = filteredTravels[index];
                        final summary = _TravelCardSummary.fromTravel(
                          travel: travel,
                          records: records,
                        );
                        return _TravelCard(summary: summary);
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 18),
                      itemCount: filteredTravels.length,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TravelCard extends StatelessWidget {
  const _TravelCard({required this.summary});

  final _TravelCardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: summary.accentColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
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
                    const Spacer(),
                    const Icon(
                      Icons.more_vert_rounded,
                      color: Color(0xFF7B8095),
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
                            style: Theme.of(context).textTheme.headlineMedium,
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
                                  style: Theme.of(context).textTheme.titleMedium
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
                          ?.copyWith(color: summary.accentColor, fontSize: 18),
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
    final usedKrw = records
        .where((record) {
          final sameCountry =
              record.country.trim().toLowerCase() ==
              travel.country.trim().toLowerCase();
          final inRange =
              !record.date.isBefore(_dateOnly(travel.startDate)) &&
              !record.date.isAfter(
                _dateOnly(travel.endDate).add(const Duration(days: 1)),
              );
          return sameCountry && inRange;
        })
        .fold<double>(
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
