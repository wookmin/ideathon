import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../config/theme.dart';
import '../providers/exchange_provider.dart';
import '../providers/ledger_provider.dart';
import '../providers/travel_selection_provider.dart';
import '../services/exchange_service.dart';
import '../models/receipt_record.dart';
import '../utils/budget_alert_presenter.dart';
import '../utils/record_presenter.dart';
import '../widgets/header_menu_overlay.dart';
import 'after_save_screen.dart';
import 'notification_list_screen.dart';
import 'settings_screen.dart';
import 'travel_list_screen.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  static const _categories = ['식비', '교통', '쇼핑', '기타'];

  final _formKey = GlobalKey<FormState>();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _amountController = TextEditingController();
  final _ocrController = TextEditingController();

  String _currency = 'USD';
  String _category = '식비';
  bool _saving = false;
  bool _isMenuOpen = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _countryController.dispose();
    _cityController.dispose();
    _amountController.dispose();
    _ocrController.dispose();
    super.dispose();
  }

  void _prefillFromTravel() {
    if (_prefilled) {
      return;
    }
    final travel = ref.read(effectiveTravelProvider);
    if (travel != null) {
      _countryController.text = _stripFlagEmoji(travel.country);
      _currency = travel.exchangeTargetCurrency;
    }
    _prefilled = true;
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
        memo: _category,
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
      BudgetAlertPresenter.maybeShowAfterRecordSaved(
        context: context,
        travel: selectedTravel,
        recordsBeforeSave: recordsBeforeSave,
        savedRecord: record,
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AfterSaveScreen()),
        (route) => route.isFirst,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _prefillFromTravel();
    final ratesAsync = ref.watch(exchangeRatesProvider);
    final records = ref.watch(ledgerProvider);
    final selectedTravel = ref.watch(effectiveTravelProvider);

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
                  onMenuTap: () {
                    setState(() => _isMenuOpen = !_isMenuOpen);
                  },
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 118),
                      children: [
                        Text(
                          '직접 입력하기',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: 16,
                                color: const Color(0xFF07126C),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '영수증 없이도 지출 정보를 저장할 수 있어요.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF8A90A1)),
                        ),
                        const SizedBox(height: 28),
                        _SectionLabel(label: '여행지'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _ManualInputField(
                                controller: _countryController,
                                hintText: '국가',
                                icon: Icons.place_outlined,
                                maxLength: 50,
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                    ? '국가를 입력해 주세요.'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ManualInputField(
                                controller: _cityController,
                                hintText: '도시',
                                icon: Icons.location_city_outlined,
                                maxLength: 50,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel(label: '결제 금액'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            SizedBox(
                              width: 132,
                              child: _CurrencyField(
                                value: _currency,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _currency = value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ManualInputField(
                                controller: _amountController,
                                hintText: '금액',
                                icon: Icons.payments_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '금액을 입력해 주세요.';
                                  }
                                  return double.tryParse(
                                            value.trim().replaceAll(',', ''),
                                          ) ==
                                          null
                                      ? '숫자 형식으로 입력해 주세요.'
                                      : null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel(label: '결제 카테고리'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categories
                              .map(
                                (item) => ChoiceChip(
                                  label: Text(item),
                                  selected: _category == item,
                                  onSelected: (_) =>
                                      setState(() => _category = item),
                                  selectedColor: const Color(0xFFDCE8FF),
                                  backgroundColor: const Color(0xFFF8F8FA),
                                  labelStyle: TextStyle(
                                    color: _category == item
                                        ? AppTheme.primary
                                        : const Color(0xFF343946),
                                    fontWeight: FontWeight.w700,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFD7DAE3),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel(label: '영수증 원문 메모'),
                        const SizedBox(height: 10),
                        _ManualInputField(
                          controller: _ocrController,
                          hintText: '품목이나 영수증 내용을 적어두면 나중에 검색하기 쉬워요.',
                          icon: Icons.receipt_long_outlined,
                          maxLines: 5,
                          maxLength: 2000,
                        ),
                        const SizedBox(height: 18),
                        _ExchangeStatusCard(ratesAsync: ratesAsync),
                      ],
                    ),
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
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: AppTheme.primary.withValues(alpha: 0.24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _saving ? '저장 중...' : '내역 저장하기',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontSize: 15, color: AppTheme.primary),
    );
  }
}

class _ManualInputField extends StatelessWidget {
  const _ManualInputField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(
        color: Color(0xFF191B28),
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        counterText: '',
        prefixIcon: Icon(icon, color: const Color(0xFF7B8095)),
        fillColor: const Color(0xFFF1EFEF),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: maxLines > 1 ? 18 : 0,
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
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
      ),
    );
  }
}

class _CurrencyField extends StatelessWidget {
  const _CurrencyField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      items: ExchangeService.supportedCurrencies
          .map(
            (code) => DropdownMenuItem(
              value: code,
              child: Text(code, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.public_rounded, color: Color(0xFF7B8095)),
        prefixIconConstraints: const BoxConstraints(minWidth: 38),
        fillColor: const Color(0xFFF1EFEF),
        contentPadding: const EdgeInsets.only(left: 4, right: 8),
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
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
      ),
      style: const TextStyle(
        color: Color(0xFF191B28),
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
    );
  }
}

class _ExchangeStatusCard extends StatelessWidget {
  const _ExchangeStatusCard({required this.ratesAsync});

  final AsyncValue<dynamic> ratesAsync;

  @override
  Widget build(BuildContext context) {
    final message = ratesAsync.when(
      data: (snapshot) =>
          snapshot.fromCache ? '환율은 캐시 데이터를 사용 중입니다.' : '저장 시 원화 금액도 함께 계산됩니다.',
      error: (_, _) => '환율을 불러오지 못했습니다. KRW 외 통화는 환산 금액이 0원으로 저장될 수 있습니다.',
      loading: () => '환율 정보를 불러오는 중입니다...',
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.primary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _stripFlagEmoji(String value) =>
    value.replaceAll(RegExp(r'[^\x00-\x7F가-힣]'), '').trim();

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
