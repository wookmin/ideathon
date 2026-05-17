import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/receipt_record.dart';
import '../providers/ledger_provider.dart';
import '../utils/record_presenter.dart';

class TravelListScreen extends ConsumerWidget {
  const TravelListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(ledgerProvider);
    final groups = _groupTrips(records);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('나의 여행 목록'),
        backgroundColor: Colors.white,
      ),
      body: groups.isEmpty
          ? const _EmptyTravelState()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              itemBuilder: (context, index) {
                final trip = groups[index];
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        trip.period,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _TripMetric(
                            label: '기록 수',
                            value: '${trip.records.length}건',
                          ),
                          const SizedBox(width: 10),
                          _TripMetric(
                            label: '누적 지출',
                            value:
                                '₩${NumberFormat('#,##0').format(trip.totalKrw)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemCount: groups.length,
            ),
    );
  }

  List<_TripGroup> _groupTrips(List<ReceiptRecord> records) {
    final grouped = <String, List<ReceiptRecord>>{};
    for (final record in records) {
      final location = record.country.trim().isNotEmpty
          ? record.country.trim()
          : '기타 여행';
      grouped.putIfAbsent(location, () => []).add(record);
    }

    return grouped.entries.map((entry) {
      final sorted = [...entry.value]..sort((a, b) => a.date.compareTo(b.date));
      final period =
          '${DateFormat('yyyy년 M월 d일', 'ko').format(sorted.first.date)} - ${DateFormat('yyyy년 M월 d일', 'ko').format(sorted.last.date)}';
      final city = sorted.first.city.trim();
      final title = city.isEmpty ? '${entry.key} 여행' : '$city, ${entry.key}';
      final totalKrw = sorted.fold<double>(
        0,
        (sum, record) => sum + RecordPresenter.totalWithTip(record),
      );
      return _TripGroup(
        title: title,
        period: period,
        totalKrw: totalKrw,
        records: sorted.reversed.toList(),
      );
    }).toList()..sort(
      (a, b) => b.records.first.date.compareTo(a.records.first.date),
    );
  }
}

class _TripMetric extends StatelessWidget {
  const _TripMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
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

class _TripGroup {
  const _TripGroup({
    required this.title,
    required this.period,
    required this.totalKrw,
    required this.records,
  });

  final String title;
  final String period;
  final double totalKrw;
  final List<ReceiptRecord> records;
}
