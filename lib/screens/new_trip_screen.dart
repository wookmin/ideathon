import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../config/theme.dart';
import '../models/travel.dart';
import '../providers/travel_provider.dart';
import '../services/exchange_service.dart';

class NewTripScreen extends ConsumerStatefulWidget {
  const NewTripScreen({super.key});

  @override
  ConsumerState<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends ConsumerState<NewTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _countryController = TextEditingController();
  final _exchangeSourceAmountController = TextEditingController();
  final _exchangeTargetAmountController = TextEditingController();
  final _budgetController = TextEditingController();
  final _formatter = DateFormat('yyyy.MM.dd');

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  String _sourceCurrency = 'KRW';
  String _targetCurrency = 'EUR';
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _countryController.dispose();
    _exchangeSourceAmountController.dispose();
    _exchangeTargetAmountController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final budgetKrw = _parseNumber(_budgetController.text);
    if (budgetKrw == null) {
      return;
    }

    setState(() => _saving = true);
    try {
      final travel = Travel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        country: _countryController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        budgetKrw: budgetKrw,
        exchangeSourceAmount: _parseNumber(
          _exchangeSourceAmountController.text,
        ),
        exchangeSourceCurrency: _sourceCurrency,
        exchangeTargetAmount: _parseNumber(
          _exchangeTargetAmountController.text,
        ),
        exchangeTargetCurrency: _targetCurrency,
        createdAt: DateTime.now(),
      );
      await ref.read(travelProvider.notifier).add(travel);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('새 여행을 저장했습니다.')));
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  double? _parseNumber(String raw) {
    final cleaned = raw.trim().replaceAll(',', '');
    if (cleaned.isEmpty) {
      return null;
    }
    return double.tryParse(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(
          '새 여행 추가',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 22,
            color: const Color(0xFF0A1C7A),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            _SectionLabel(label: '여행 이름'),
            const SizedBox(height: 12),
            _InputField(
              controller: _titleController,
              hintText: '파리 감성 여행',
              icon: Icons.edit_outlined,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? '여행 이름을 입력해 주세요.'
                  : null,
            ),
            const SizedBox(height: 26),
            _SectionLabel(label: '여행지'),
            const SizedBox(height: 12),
            _InputField(
              controller: _countryController,
              hintText: '국가를 선택하세요',
              icon: Icons.place_outlined,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? '여행지를 입력해 주세요.'
                  : null,
            ),
            const SizedBox(height: 26),
            _SectionLabel(label: '여행 일정'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: _DateField(
                    value: _formatter.format(_startDate),
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 8),
                Text('-', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(width: 8),
                Flexible(
                  child: _DateField(
                    value: _formatter.format(_endDate),
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _SectionLabel(label: '총예산'),
            const SizedBox(height: 12),
            _InputField(
              controller: _budgetController,
              hintText: '총예산을 입력하세요 (KRW)',
              icon: Icons.account_balance_wallet_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '총예산을 입력해 주세요.';
                }
                return _parseNumber(value) == null ? '숫자 형식으로 입력해 주세요.' : null;
              },
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(_saving ? '저장 중...' : '저장하기'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(72),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
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
      ).textTheme.titleMedium?.copyWith(color: AppTheme.primary),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: const Color(0xFF7B8095)),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7FA),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, color: Color(0xFF7B8095)),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ],
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
      items: ExchangeService.supportedCurrencies
          .map(
            (code) => DropdownMenuItem<String>(value: code, child: Text(code)),
          )
          .toList(),
      onChanged: onChanged,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}
