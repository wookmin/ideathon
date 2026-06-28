import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../providers/exchange_provider.dart';
import '../providers/ledger_provider.dart';
import '../providers/travel_selection_provider.dart';
import '../services/exchange_service.dart';
import '../models/receipt_record.dart';
import '../utils/budget_alert_presenter.dart';
import '../widgets/main_bottom_nav.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  final _ocrController = TextEditingController();

  String _currency = 'USD';
  bool _saving = false;

  @override
  void dispose() {
    _countryController.dispose();
    _cityController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    _ocrController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(
      _amountController.text.trim().replaceAll(',', ''),
    );
    if (amount == null) {
      return;
    }

    final exchangeSnapshot = ref.read(exchangeRatesProvider).valueOrNull;
    if (_currency != 'KRW' && exchangeSnapshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('환율 정보를 불러오는 중입니다. 잠시 후 다시 시도해 주세요.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final rate = _currency == 'KRW'
          ? 1.0
          : (exchangeSnapshot?.rateFor(_currency) ?? 0);
      final krwAmount = _currency == 'KRW'
          ? amount
          : ref
                    .read(exchangeServiceProvider)
                    .valueOrNull
                    ?.convertToKrw(
                      originalAmount: amount,
                      currency: _currency,
                      snapshot: exchangeSnapshot!,
                    ) ??
                0;

      final record = ReceiptRecord(
        id: const Uuid().v4(),
        date: DateTime.now(),
        country: _countryController.text.trim(),
        countryCode: _inferCountryCode(
          currency: _currency,
          country: _countryController.text.trim(),
        ),
        city: _cityController.text.trim(),
        currency: _currency,
        originalAmount: amount,
        krwAmount: krwAmount,
        exchangeRate: rate,
        rawOcrText: _ocrController.text.trim(),
        items: const [],
        verdict: 'unknown',
        tipPct: 0,
        tipKrw: 0,
        memo: _memoController.text.trim(),
        imagePath: null,
        analysis: '직접 입력으로 저장한 내역입니다.',
      );

      final selectedTravel = ref.read(effectiveTravelProvider);
      final recordsBeforeSave = scopedRecordsForTravel(
        ref.read(ledgerProvider),
        selectedTravel,
      );
      await ref.read(ledgerProvider.notifier).add(record);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('직접 입력 내역을 저장했습니다.')));
      BudgetAlertPresenter.maybeShowAfterRecordSaved(
        context: context,
        travel: selectedTravel,
        recordsBeforeSave: recordsBeforeSave,
        savedRecord: record,
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratesAsync = ref.watch(exchangeRatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('직접 입력')),
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Text(
              '영수증 사진 없이도 금액과 여행 정보를 직접 기록할 수 있습니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _countryController,
              decoration: const InputDecoration(labelText: '국가'),
              maxLength: 50,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? '국가를 입력해 주세요.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: '도시'),
              maxLength: 50,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              items: ExchangeService.supportedCurrencies
                  .map(
                    (code) => DropdownMenuItem(value: code, child: Text(code)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _currency = value);
                }
              },
              decoration: const InputDecoration(labelText: '통화'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: '금액'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '금액을 입력해 주세요.';
                }
                return double.tryParse(value.trim().replaceAll(',', '')) == null
                    ? '숫자 형식으로 입력해 주세요.'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _memoController,
              decoration: const InputDecoration(labelText: '메모'),
              maxLength: 200,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ocrController,
              maxLines: 5,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: '영수증 원문 메모',
                hintText: '품목이나 영수증 내용을 텍스트로 적어두면 나중에 검색하기 쉽습니다.',
              ),
            ),
            const SizedBox(height: 16),
            ratesAsync.when(
              data: (snapshot) => Text(
                snapshot.fromCache
                    ? '환율은 캐시 데이터를 사용 중입니다.'
                    : '환율을 불러왔습니다. 저장 시 KRW 금액도 함께 계산됩니다.',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              error: (_, _) => Text(
                '환율을 불러오지 못했습니다. KRW 외 통화는 환산 금액이 0원으로 저장될 수 있습니다.',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              loading: () => Text(
                '환율 정보를 불러오는 중입니다...',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? '저장 중...' : '직접 입력 저장하기'),
            ),
          ],
        ),
      ),
    );
  }
}

String _inferCountryCode({required String currency, required String country}) {
  final normalizedCountry = country.trim().toLowerCase();
  if (normalizedCountry.contains('한국') || normalizedCountry.contains('korea')) {
    return 'KR';
  }
  if (normalizedCountry.contains('일본') || normalizedCountry.contains('japan')) {
    return 'JP';
  }
  if (normalizedCountry.contains('미국') ||
      normalizedCountry.contains('united states')) {
    return 'US';
  }
  return switch (currency) {
    'KRW' => 'KR',
    'JPY' => 'JP',
    'USD' => 'US',
    'EUR' => 'EU',
    'THB' => 'TH',
    'VND' => 'VN',
    'CNY' => 'CN',
    'TWD' => 'TW',
    'HKD' => 'HK',
    'SGD' => 'SG',
    'GBP' => 'GB',
    'AUD' => 'AU',
    _ => '',
  };
}
