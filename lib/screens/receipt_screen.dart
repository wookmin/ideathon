import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../config/theme.dart';
import '../models/receipt_analysis.dart';
import '../models/receipt_record.dart';
import '../models/tip_rule.dart';
import '../providers/exchange_provider.dart';
import '../providers/ledger_provider.dart';
import '../providers/travel_selection_provider.dart';
import '../services/exchange_service.dart';
import '../services/gemini_service.dart';
import '../utils/budget_alert_presenter.dart';
import '../utils/record_presenter.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/receipt_item_tile.dart';
import '../widgets/service_charge_banner.dart';
import '../widgets/tip_slider_widget.dart';
import '../widgets/verdict_badge.dart';

class ReceiptScreen extends ConsumerStatefulWidget {
  const ReceiptScreen({
    super.key,
    required this.imagePath,
    required this.ocrText,
  });

  final String imagePath;
  final String ocrText;

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  ReceiptAnalysis? _analysis;
  String? _selectedCurrency;
  double _tipPct = 0;
  bool _loading = true;
  String _memo = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dio = ref.read(dioProvider);
    final analysis = await GeminiService(
      dio,
    ).analyzeReceipt(imagePath: widget.imagePath, ocrText: widget.ocrText);

    if (!mounted) {
      return;
    }
    final rule = tipRules[analysis.countryCode] ?? defaultTipRule;
    setState(() {
      _analysis = analysis;
      _selectedCurrency = analysis.currency;
      _tipPct = analysis.tipSuggestedPct > 0
          ? analysis.tipSuggestedPct
          : rule.suggested;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exchangeAsync = ref.watch(exchangeRatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('분석 결과')),
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _analysis == null
          ? const Center(child: Text('분석 결과를 불러오지 못했습니다.'))
          : exchangeAsync.when(
              data: (snapshot) {
                final analysis = _analysis!;
                final currency = _selectedCurrency ?? analysis.currency;
                final currencyOptions = {
                  ...ExchangeService.supportedCurrencies,
                  currency,
                }.toList();
                final rate = snapshot.rateFor(currency);
                final amountKrw = ref
                    .read(exchangeServiceProvider)
                    .maybeWhen(
                      data: (service) => service.convertToKrw(
                        originalAmount: analysis.totalAmount,
                        currency: currency,
                        snapshot: snapshot,
                      ),
                      orElse: () => 0.0,
                    );
                final tipOriginal = analysis.totalAmount * (_tipPct / 100);
                final tipKrw = rate > 0 ? tipOriginal / rate : 0.0;
                final totalWithTipOriginal = analysis.totalAmount + tipOriginal;
                final totalWithTipKrw = amountKrw + tipKrw;
                final perPerson = totalWithTipOriginal / 4;
                final tipCulture = analysis.tipCulture.isNotEmpty
                    ? analysis.tipCulture
                    : (tipRules[analysis.countryCode] ?? defaultTipRule)
                          .culture;

                return ListView(
                  padding: AppTheme.screenPadding.copyWith(top: 12, bottom: 32),
                  children: [
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppTheme.line),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(
                              Icons.receipt_long_rounded,
                              size: 72,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (analysis.isFallback) ...[
                      _FailureBanner(analysis: analysis),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryStrong],
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  analysis.isFallback ? 'AI 분석 생략' : 'AI 분석 완료',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            '${analysis.country} ${analysis.city}'.trim(),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            RecordPresenter.amountWithSymbol(
                              currency,
                              analysis.totalAmount,
                            ),
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₩${NumberFormat('#,##0').format(amountKrw)}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppTheme.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '통화',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: currency,
                                  dropdownColor: AppTheme.surface,
                                  items: currencyOptions
                                      .map(
                                        (code) => DropdownMenuItem(
                                          value: code,
                                          child: Text(code),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value == null) {
                                      return;
                                    }
                                    setState(() => _selectedCurrency = value);
                                  },
                                  decoration: const InputDecoration(
                                    labelText: '통화 수동 변경',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppTheme.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '팁 문화',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                                const SizedBox(height: 10),
                                _CultureChip(label: tipCulture),
                                const SizedBox(height: 12),
                                Text(
                                  analysis.summary,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                          Text(
                            '팁 계산',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              for (final preset in [10.0, 15.0, 20.0])
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: preset == 20 ? 0 : 8,
                                    ),
                                    child: _TipPresetButton(
                                      value: preset,
                                      selected:
                                          _tipPct.round() == preset.round(),
                                      onTap: () =>
                                          setState(() => _tipPct = preset),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TipSliderWidget(
                            value: _tipPct,
                            min: 0,
                            max: 30,
                            onChanged: (value) =>
                                setState(() => _tipPct = value),
                          ),
                          if (analysis.hasServiceCharge) ...[
                            const SizedBox(height: 12),
                            const ServiceChargeBanner(),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryStrong],
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _SummaryMetric(
                                label: '팁 금액',
                                value: RecordPresenter.amountWithSymbol(
                                  currency,
                                  tipOriginal,
                                ),
                              ),
                              const Spacer(),
                              _SummaryMetric(
                                label: 'KRW 팁',
                                value:
                                    '₩${NumberFormat('#,##0').format(tipKrw)}',
                                alignEnd: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              _SummaryMetric(
                                label: '총 결제 금액',
                                value: RecordPresenter.amountWithSymbol(
                                  currency,
                                  totalWithTipOriginal,
                                ),
                                emphasize: true,
                              ),
                              const Spacer(),
                              _SummaryMetric(
                                label: '1인당 금액(4인)',
                                value: RecordPresenter.amountWithSymbol(
                                  currency,
                                  perPerson,
                                ),
                                emphasize: true,
                                alignEnd: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.line),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              analysis.analysis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.primaryStrong),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                          Text(
                            analysis.summary,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            '₩${NumberFormat('#,##0').format(amountKrw)} / 팁 포함 ₩${NumberFormat('#,##0').format(totalWithTipKrw)}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (analysis.savingTips.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: analysis.savingTips
                                  .map((tip) => _SavingTipChip(label: tip))
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 16),
                          TextField(
                            maxLines: 3,
                            onChanged: (value) => _memo = value,
                            decoration: const InputDecoration(
                              labelText: '메모',
                              hintText: '예: 관광지 근처 식당, 현금 결제',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                          Text(
                            '품목 비교',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          if (analysis.items.isEmpty)
                            Text(
                              '세부 품목을 구조화하지 못했습니다. OCR 원문을 확인해 주세요.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                          else
                            ...analysis.items.map(
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
                    ElevatedButton(
                      onPressed: () async {
                        final record = ReceiptRecord(
                          id: const Uuid().v4(),
                          date: DateTime.now(),
                          country: analysis.country,
                          countryCode: analysis.countryCode,
                          city: analysis.city,
                          currency: currency,
                          originalAmount: analysis.totalAmount,
                          krwAmount: amountKrw,
                          exchangeRate: rate,
                          rawOcrText: widget.ocrText,
                          items: analysis.items
                              .map(ReceiptItem.fromAnalysis)
                              .toList(),
                          verdict: analysis.verdict,
                          tipPct: _tipPct,
                          tipKrw: tipKrw,
                          memo: _memo,
                          imagePath: widget.imagePath,
                          analysis: analysis.analysis,
                        );
                        final selectedTravel = ref.read(
                          effectiveTravelProvider,
                        );
                        final recordsBeforeSave = scopedRecordsForTravel(
                          ref.read(ledgerProvider),
                          selectedTravel,
                        );
                        await ref.read(ledgerProvider.notifier).add(record);
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('가계부에 저장했습니다.')),
                        );
                        BudgetAlertPresenter.maybeShowAfterRecordSaved(
                          context: context,
                          travel: selectedTravel,
                          recordsBeforeSave: recordsBeforeSave,
                          savedRecord: record,
                        );
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      child: const Text('가계부에 저장하기'),
                    ),
                    const SizedBox(height: 12),
                    if (!analysis.isFallback)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppTheme.line),
                        ),
                        child: ExpansionTile(
                          title: const Text('바가지 판정 보기 (참고용)'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: VerdictBadge(
                                  verdict: analysis.verdict,
                                  label:
                                      '${analysis.verdictEmoji} ${analysis.verdictLabel}',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppTheme.line),
                      ),
                      child: ExpansionTile(
                        title: const Text('OCR 원문 보기'),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          20,
                        ),
                        children: [
                          Text(
                            widget.ocrText.isEmpty
                                ? '추출된 텍스트가 없습니다.'
                                : widget.ocrText,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              error: (error, _) =>
                  Center(child: Text('환율 정보를 불러오지 못했습니다.\n$error')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
    );
  }
}

class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.analysis});

  final ReceiptAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF5C2BE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy_outlined, color: AppTheme.bad),
              const SizedBox(width: 10),
              Text(
                'AI 실패 원인',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppTheme.bad),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            analysis.failureReason ?? 'AI 분석에 실패했습니다.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.bad),
          ),
          if ((analysis.failureDetail ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              analysis.failureDetail!,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _TipPresetButton extends StatelessWidget {
  const _TipPresetButton({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final double value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        height: 56,
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.line,
          ),
        ),
        child: Center(
          child: Text(
            '${value.toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: selected ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CultureChip extends StatelessWidget {
  const _CultureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      '필수' => AppTheme.bad,
      '불필요' => AppTheme.ok,
      _ => AppTheme.warn,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}

class _SavingTipChip extends StatelessWidget {
  const _SavingTipChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.alignEnd = false,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool alignEnd;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style:
              (emphasize
                      ? Theme.of(context).textTheme.headlineMedium
                      : Theme.of(context).textTheme.titleLarge)
                  ?.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}
