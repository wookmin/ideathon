import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/receipt_record.dart';
import '../utils/record_presenter.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/receipt_item_tile.dart';

class LedgerDetailScreen extends StatelessWidget {
  const LedgerDetailScreen({
    super.key,
    required this.record,
  });

  final ReceiptRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('지출 상세 내역')),
      bottomNavigationBar: const MainBottomNav(currentIndex: 2),
      body: ListView(
        padding: AppTheme.screenPadding.copyWith(top: 8, bottom: 32),
        children: [
          Text('스캔된 영수증', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 12),
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.line),
            ),
            child: record.imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.file(File(record.imagePath!), fit: BoxFit.cover),
                  )
                : const Center(
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: 88,
                      color: AppTheme.primary,
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryStrong],
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${RecordPresenter.flag(record.countryCode)} ${RecordPresenter.locationLabel(record)}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  '₩${NumberFormat('#,##0').format(record.krwAmount + record.tipKrw)}',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  '${RecordPresenter.amountWithSymbol(record.currency, record.originalAmount)} · 팁 ${record.tipPct.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  label: '현지 금액',
                  value: RecordPresenter.amountWithSymbol(record.currency, record.originalAmount),
                  subtitle: record.currency,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  label: '적용 환율',
                  value: record.exchangeRate.toStringAsFixed(2),
                  subtitle: 'KRW 기준 역산',
                  highlighted: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  label: '날짜',
                  value: DateFormat('yyyy년 M월 d일', 'ko').format(record.date),
                  subtitle: DateFormat('HH:mm').format(record.date),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  label: '카테고리',
                  value: RecordPresenter.category(record),
                  subtitle: record.country,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.storefront_outlined, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('가맹점/메모', style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 4),
                      Text(
                        RecordPresenter.title(record),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('분석 요약', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Text(record.analysis, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 18),
                Text('품목 비교', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (record.items.isEmpty)
                  Text('세부 품목이 구조화되지 않았습니다.', style: Theme.of(context).textTheme.bodyMedium)
                else
                  ...record.items.map(
                    (item) => ReceiptItemTile(
                      name: item.name,
                      paid: item.paid,
                      avg: item.avg,
                      status: item.status,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.line),
            ),
            child: ExpansionTile(
              title: const Text('OCR 원문 보기'),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                Text(
                  record.rawOcrText,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
    required this.subtitle,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final String subtitle;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlighted ? AppTheme.primary : AppTheme.line,
          width: highlighted ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
