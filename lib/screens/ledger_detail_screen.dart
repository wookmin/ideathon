import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/receipt_record.dart';
import '../providers/ledger_provider.dart';
import '../utils/record_presenter.dart';

class LedgerDetailScreen extends ConsumerWidget {
  const LedgerDetailScreen({super.key, required this.record});

  final ReceiptRecord record;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('내역 삭제'),
        content: const Text('이 지출 내역을 삭제하시겠습니까?\n삭제하면 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.bad),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(ledgerProvider.notifier).delete(record.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('내역을 삭제했습니다.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final krwAmount = record.krwAmount + record.tipKrw;
    final category = RecordPresenter.category(record);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(23, 18, 20, 32),
          children: [
            _DetailHeader(
              onBackTap: () => Navigator.of(context).pop(),
              onDeleteTap: () => _confirmDelete(context, ref),
            ),
            const SizedBox(height: 28),
            Text(
              '저장된 항목 (${record.items.length})',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF333745)),
            ),
            const SizedBox(height: 8),
            if (record.items.isEmpty)
              _WhiteCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '세부 품목이 구조화되지 않았습니다.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              _WhiteCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < record.items.length; i++) ...[
                      _SavedItemRow(item: record.items[i]),
                      if (i != record.items.length - 1)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 24),
            _WhiteCard(
              padding: const EdgeInsets.fromLTRB(17, 16, 17, 16),
              child: Column(
                children: [
                  Text(
                    '총 결제 금액',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF4E5668),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        record.currency,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: const Color(0xFF07126C),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        record.originalAmount.toStringAsFixed(2),
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: const Color(0xFF07126C),
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '⇄ ≈ ${NumberFormat('#,##0').format(krwAmount)} KRW',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF4B5260),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                  _FormLabel('카테고리'),
                  const SizedBox(height: 9),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(category),
                          selected: true,
                          onSelected: null,
                          selectedColor: const Color(0xFFDCE8FF),
                          backgroundColor: const Color(0xFFF8F8FA),
                          labelStyle: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                          side: const BorderSide(color: Color(0xFFD7DAE3)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  _FormLabel('일시'),
                  const SizedBox(height: 9),
                  _ReadonlyField(
                    icon: Icons.calendar_today_outlined,
                    value: DateFormat('MM/dd/yyyy, hh:mm a').format(
                      record.date,
                    ),
                  ),
                  const SizedBox(height: 23),
                  _FormLabel('장소'),
                  const SizedBox(height: 9),
                  _ReadonlyField(
                    icon: Icons.location_on_outlined,
                    value: RecordPresenter.locationLabel(record),
                  ),
                  const SizedBox(height: 23),
                  _FormLabel('메모'),
                  const SizedBox(height: 9),
                  _ReadonlyField(
                    icon: Icons.notes_outlined,
                    value: record.memo.trim().isEmpty
                        ? '메모가 없습니다'
                        : record.memo,
                  ),
                  const SizedBox(height: 23),
                  _FormLabel('적용 환율'),
                  const SizedBox(height: 9),
                  _ReadonlyField(
                    icon: Icons.currency_exchange_outlined,
                    value: record.exchangeRate > 0
                        ? '1 ${record.currency} ≈ ₩${NumberFormat('#,##0.##').format(1 / record.exchangeRate)}'
                        : '정보 없음',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onBackTap, required this.onDeleteTap});

  final VoidCallback onBackTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBackTap,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppTheme.textPrimary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            ),
          ),
          Text(
            '지출 상세 내역',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF07126C),
              fontWeight: FontWeight.w900,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: onDeleteTap,
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppTheme.bad,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedItemRow extends StatelessWidget {
  const _SavedItemRow({required this.item});

  final ReceiptItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF272B36)),
                ),
                const SizedBox(height: 5),
                Text(
                  item.status,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF4D5565)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.paid,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF222631),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.avg,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFC0C2C8),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE4E7EE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: const Color(0xFF4B5260),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F2F3),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF7A8190)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
