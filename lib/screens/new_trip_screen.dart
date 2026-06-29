import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../config/theme.dart';
import '../models/travel.dart';
import '../providers/travel_provider.dart';
import '../widgets/header_menu_overlay.dart';
import 'settings_screen.dart';

// 나라명(표시용) → 통화 코드
const _countries = [
  ('🇰🇷 대한민국', 'KRW'),
  ('🇺🇸 미국', 'USD'),
  ('🇯🇵 일본', 'JPY'),
  ('🇨🇳 중국', 'CNY'),
  ('🇹🇭 태국', 'THB'),
  ('🇻🇳 베트남', 'VND'),
  ('🇹🇼 대만', 'TWD'),
  ('🇭🇰 홍콩', 'HKD'),
  ('🇸🇬 싱가포르', 'SGD'),
  ('🇬🇧 영국', 'GBP'),
  ('🇦🇺 호주', 'AUD'),
  ('🇫🇷 프랑스', 'EUR'),
  ('🇩🇪 독일', 'EUR'),
  ('🇮🇹 이탈리아', 'EUR'),
  ('🇪🇸 스페인', 'EUR'),
  ('🇵🇹 포르투갈', 'EUR'),
  ('🇳🇱 네덜란드', 'EUR'),
  ('🇧🇪 벨기에', 'EUR'),
  ('🇦🇹 오스트리아', 'EUR'),
  ('🇬🇷 그리스', 'EUR'),
  ('🇫🇮 핀란드', 'EUR'),
  ('🇮🇪 아일랜드', 'EUR'),
  ('🇨🇭 스위스', 'CHF'),
  ('🇳🇿 뉴질랜드', 'NZD'),
  ('🇨🇦 캐나다', 'CAD'),
  ('🇲🇾 말레이시아', 'MYR'),
  ('🇵🇭 필리핀', 'PHP'),
  ('🇮🇩 인도네시아', 'IDR'),
  ('🇮🇳 인도', 'INR'),
  ('🇹🇷 튀르키예', 'TRY'),
  ('🇲🇽 멕시코', 'MXN'),
  ('🇧🇷 브라질', 'BRL'),
];

class NewTripScreen extends ConsumerStatefulWidget {
  const NewTripScreen({super.key});

  @override
  ConsumerState<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends ConsumerState<NewTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _budgetController = TextEditingController();
  final _formatter = DateFormat('yyyy.MM.dd');

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  String? _selectedCountry;
  String _targetCurrency = 'USD';
  bool _saving = false;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _budgetController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
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
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickCountry() async {
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CountryPickerSheet(),
    );
    if (result == null) return;
    setState(() {
      _selectedCountry = result.$1;
      _targetCurrency = result.$2;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountry == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('여행지를 선택해 주세요.')));
      return;
    }

    final budgetKrw = _parseNumber(_budgetController.text);
    if (budgetKrw == null) return;

    setState(() => _saving = true);
    try {
      final travel = Travel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        country: _selectedCountry!,
        startDate: _startDate,
        endDate: _endDate,
        budgetKrw: budgetKrw,
        exchangeSourceAmount: null,
        exchangeSourceCurrency: 'KRW',
        exchangeTargetAmount: null,
        exchangeTargetCurrency: _targetCurrency,
        createdAt: DateTime.now(),
      );
      await ref.read(travelProvider.notifier).add(travel);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('새 여행을 저장했습니다.')));
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double? _parseNumber(String raw) {
    final cleaned = raw.trim().replaceAll(',', '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    final budgetKrw = _parseNumber(_budgetController.text) ?? 0;
    final travelDays = _endDate.difference(_startDate).inDays + 1;
    final dailyBudget = travelDays <= 0 ? 0 : budgetKrw / travelDays;
    final currencyFormatter = NumberFormat('#,##0');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFE),
      body: SafeArea(
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 118),
                children: [
                  _NewTripHeader(
                    onMenuTap: () => setState(() => _isMenuOpen = !_isMenuOpen),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 38, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '새 여행 추가',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: 16,
                                color: const Color(0xFF07126C),
                              ),
                        ),
                        const SizedBox(height: 34),
                        _SectionLabel(label: '여행 이름'),
                        const SizedBox(height: 10),
                        _InputField(
                          controller: _titleController,
                          hintText: '파리 감성 여행',
                          icon: Icons.edit_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? '여행 이름을 입력해 주세요.'
                              : null,
                        ),
                        const SizedBox(height: 26),
                        _SectionLabel(label: '여행지'),
                        const SizedBox(height: 10),
                        _CountryField(
                          selected: _selectedCountry,
                          currency: _selectedCountry != null
                              ? _targetCurrency
                              : null,
                          onTap: _pickCountry,
                        ),
                        const SizedBox(height: 26),
                        _SectionLabel(label: '여행 일정'),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: _DateField(
                                value: _formatter.format(_startDate),
                                onTap: () => _pickDate(isStart: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '-',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: const Color(0xFF8D919E)),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: _DateField(
                                value: _formatter.format(_endDate),
                                onTap: () => _pickDate(isStart: false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 34),
                        _SectionLabel(label: '예산 정하기'),
                        const SizedBox(height: 10),
                        _BudgetInputCard(
                          controller: _budgetController,
                          totalLabel: '₩${currencyFormatter.format(budgetKrw)}',
                          dailyLabel:
                              '하루 예산 ₩${currencyFormatter.format(dailyBudget)}',
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return '총예산을 입력해 주세요.';
                            }
                            return _parseNumber(v) == null
                                ? '숫자 형식으로 입력해 주세요.'
                                : null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                    _saving ? '저장 중...' : '저장하기',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            HeaderMenuOverlay(
              isOpen: _isMenuOpen,
              dimTopOffset: 68,
              onDismiss: () => setState(() => _isMenuOpen = false),
              onTravelTap: () {
                setState(() => _isMenuOpen = false);
                Navigator.of(context).maybePop();
              },
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

class _NewTripHeader extends StatelessWidget {
  const _NewTripHeader({required this.onMenuTap});

  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.fromLTRB(20, 0, 28, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/design/icons/headerLogo.svg', width: 40),
          const Spacer(),
          HeaderMenuToggleButton(onTap: onMenuTap),
        ],
      ),
    );
  }
}

class _BudgetInputCard extends StatelessWidget {
  const _BudgetInputCard({
    required this.controller,
    required this.totalLabel,
    required this.dailyLabel,
    required this.validator,
  });

  final TextEditingController controller;
  final String totalLabel;
  final String dailyLabel;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '총 예산',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: totalLabel,
              hintStyle: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
              prefixText: controller.text.trim().isEmpty ? null : '₩',
              prefixStyle: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0x66FFFFFF)),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0x66FFFFFF)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              errorStyle: const TextStyle(color: Colors.white),
              contentPadding: EdgeInsets.zero,
              filled: false,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            dailyLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryField extends StatelessWidget {
  const _CountryField({
    required this.selected,
    required this.currency,
    required this.onTap,
  });

  final String? selected;
  final String? currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF1EFEF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.place_outlined, color: Color(0xFF7B8095)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selected ?? '국가를 선택하세요',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: selected != null
                      ? const Color(0xFF1A1A2E)
                      : const Color(0xFF7B8095),
                ),
              ),
            ),
            if (currency != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currency!,
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF7B8095)),
          ],
        ),
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  List<(String, String)> _filtered = _countries;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? _countries
            : _countries.where((c) => c.$1.toLowerCase().contains(q)).toList();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '나라 검색',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF7F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final (name, currency) = _filtered[i];
                  return ListTile(
                    title: Text(name),
                    trailing: Text(
                      currency,
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop((name, currency)),
                  );
                },
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

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: const Color(0xFF7B8095)),
        fillColor: const Color(0xFFF1EFEF),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1EFEF),
          borderRadius: BorderRadius.circular(10),
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
