import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../config/theme.dart';
import '../models/receipt_analysis.dart';
import '../models/receipt_record.dart';
import '../providers/exchange_provider.dart';
import '../providers/ledger_provider.dart';
import '../providers/travel_selection_provider.dart';
import '../services/exchange_service.dart';
import '../services/gemini_service.dart';
import '../utils/budget_alert_presenter.dart';
import '../utils/record_presenter.dart';
import '../widgets/app_loading_screen.dart';

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
  final _placeController = TextEditingController();
  final _memoController = TextEditingController();
  final _categories = const ['식비', '교통', '쇼핑', '기타'];

  ReceiptAnalysis? _analysis;
  String _currency = 'USD';
  String _category = '식비';
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  List<_EditableReceiptItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _placeController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final dio = ref.read(dioProvider);
    final analysis = await GeminiService(
      dio,
    ).analyzeReceipt(imagePath: widget.imagePath, ocrText: widget.ocrText);

    if (!mounted) {
      return;
    }

    final inferredCategory = _inferCategory(analysis);
    setState(() {
      _analysis = analysis;
      _currency = analysis.currency;
      _category = inferredCategory;
      _placeController.text = [
        analysis.city,
        analysis.country,
      ].where((value) => value.trim().isNotEmpty).join(' ');
      _items = _initialItems(analysis, inferredCategory);
      _loading = false;
    });
  }

  List<_EditableReceiptItem> _initialItems(
    ReceiptAnalysis analysis,
    String fallbackCategory,
  ) {
    final parsedItems = analysis.items
        .map((item) {
          final amount = _parseAmount(item.paid);
          if (amount <= 0) {
            return null;
          }
          return _EditableReceiptItem(
            name: item.name.trim().isEmpty ? '스캔 항목' : item.name.trim(),
            category: fallbackCategory,
            amount: amount,
          );
        })
        .whereType<_EditableReceiptItem>()
        .toList();

    if (parsedItems.isNotEmpty) {
      return parsedItems;
    }

    return [
      _EditableReceiptItem(
        name: '스캔 항목',
        category: fallbackCategory,
        amount: analysis.totalAmount,
      ),
    ];
  }

  String _inferCategory(ReceiptAnalysis analysis) {
    final text = '${analysis.summary} ${analysis.analysis} ${widget.ocrText}'
        .toLowerCase();
    if (text.contains('metro') ||
        text.contains('taxi') ||
        text.contains('bus') ||
        text.contains('교통')) {
      return '교통';
    }
    if (text.contains('shop') ||
        text.contains('store') ||
        text.contains('쇼핑')) {
      return '쇼핑';
    }
    return '식비';
  }

  double get _totalAmount {
    final sum = _items.fold<double>(0, (total, item) => total + item.amount);
    if (sum > 0) {
      return sum;
    }
    return _analysis?.totalAmount ?? 0;
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (time == null) {
      setState(() => _selectedDate = date);
      return;
    }

    setState(() {
      _selectedDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _addItem() async {
    final item = await _showItemDialog(
      title: '항목 추가',
      initial: _EditableReceiptItem(name: '', category: _category, amount: 0),
    );
    if (item == null) {
      return;
    }
    setState(() => _items = [..._items, item]);
  }

  Future<void> _editItem(int index) async {
    final item = await _showItemDialog(title: '항목 수정', initial: _items[index]);
    if (item == null) {
      return;
    }
    setState(() {
      _items = [..._items]..[index] = item;
    });
  }

  Future<_EditableReceiptItem?> _showItemDialog({
    required String title,
    required _EditableReceiptItem initial,
  }) async {
    final nameController = TextEditingController(text: initial.name);
    final amountController = TextEditingController(
      text: initial.amount == 0 ? '' : initial.amount.toStringAsFixed(2),
    );
    var selectedCategory = initial.category;

    final result = await showDialog<_EditableReceiptItem>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '항목명'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: '금액 ($_currency)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    items: _categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedCategory = value);
                      }
                    },
                    decoration: const InputDecoration(labelText: '카테고리'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final amount = _parseAmount(amountController.text);
                    if (nameController.text.trim().isEmpty || amount <= 0) {
                      return;
                    }
                    Navigator.of(dialogContext).pop(
                      _EditableReceiptItem(
                        name: nameController.text.trim(),
                        category: selectedCategory,
                        amount: amount,
                      ),
                    );
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    amountController.dispose();
    return result;
  }

  Future<void> _save({
    required ExchangeRatesSnapshot snapshot,
    required double rate,
    required double amountKrw,
  }) async {
    final analysis = _analysis;
    if (analysis == null || _saving) {
      return;
    }

    setState(() => _saving = true);
    try {
      final memoParts = [
        if (_category.trim().isNotEmpty) _category.trim(),
        if (_memoController.text.trim().isNotEmpty) _memoController.text.trim(),
      ];

      final record = ReceiptRecord(
        id: const Uuid().v4(),
        date: _selectedDate,
        country: analysis.country,
        countryCode: analysis.countryCode,
        city: _placeController.text.trim().isEmpty
            ? analysis.city
            : _placeController.text.trim(),
        currency: _currency,
        originalAmount: _totalAmount,
        krwAmount: amountKrw,
        exchangeRate: rate,
        rawOcrText: widget.ocrText,
        items: _items
            .map(
              (item) => ReceiptItem(
                name: item.name,
                paid: RecordPresenter.amountWithSymbol(_currency, item.amount),
                avg:
                    '₩${NumberFormat('#,##0').format(_convertToKrw(item.amount, snapshot))}',
                status: item.category,
              ),
            )
            .toList(),
        verdict: analysis.verdict,
        tipPct: 0,
        tipKrw: 0,
        memo: memoParts.join(' · '),
        imagePath: widget.imagePath,
        analysis: analysis.analysis,
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
      ).showSnackBar(const SnackBar(content: Text('내역을 저장했습니다.')));
      BudgetAlertPresenter.maybeShowAfterRecordSaved(
        context: context,
        travel: selectedTravel,
        recordsBeforeSave: recordsBeforeSave,
        savedRecord: record,
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  double _convertToKrw(double amount, ExchangeRatesSnapshot snapshot) {
    return ref
            .read(exchangeServiceProvider)
            .valueOrNull
            ?.convertToKrw(
              originalAmount: amount,
              currency: _currency,
              snapshot: snapshot,
            ) ??
        0;
  }

  @override
  Widget build(BuildContext context) {
    final exchangeAsync = ref.watch(exchangeRatesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      body: _loading
          ? const AppLoadingScreen()
          : _analysis == null
          ? const Center(child: Text('분석 결과를 불러오지 못했습니다.'))
          : exchangeAsync.when(
              data: (snapshot) {
                final currencyOptions = {
                  ...ExchangeService.supportedCurrencies,
                  _currency,
                }.toList();
                final rate = snapshot.rateFor(_currency);
                final amountKrw = _convertToKrw(_totalAmount, snapshot);

                return SafeArea(
                  child: Stack(
                    children: [
                      ListView(
                        padding: const EdgeInsets.fromLTRB(23, 18, 20, 112),
                        children: [
                          _ReceiptHeader(
                            onBackTap: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            '스캔된 항목 (${_items.length})',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: const Color(0xFF333745)),
                          ),
                          const SizedBox(height: 8),
                          _ScannedItemsCard(
                            items: _items,
                            currency: _currency,
                            snapshot: snapshot,
                            convertToKrw: _convertToKrw,
                            onEdit: _editItem,
                            onDelete: (index) {
                              if (_items.length <= 1) {
                                return;
                              }
                              setState(() {
                                _items = [..._items]..removeAt(index);
                              });
                            },
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: TextButton.icon(
                              onPressed: _addItem,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('항목 추가'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _ReceiptFormCard(
                            totalAmount: _totalAmount,
                            amountKrw: amountKrw,
                            currency: _currency,
                            currencyOptions: currencyOptions,
                            category: _category,
                            categories: _categories,
                            date: _selectedDate,
                            placeController: _placeController,
                            memoController: _memoController,
                            onCurrencyChanged: (value) {
                              if (value != null) {
                                setState(() => _currency = value);
                              }
                            },
                            onCategoryChanged: (category) {
                              setState(() => _category = category);
                            },
                            onDateTap: _pickDateTime,
                          ),
                        ],
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _BottomSaveBar(
                          saving: _saving,
                          onSave: () => _save(
                            snapshot: snapshot,
                            rate: rate,
                            amountKrw: amountKrw,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              error: (error, _) =>
                  Center(child: Text('환율 정보를 불러오지 못했습니다.\n$error')),
              loading: () => const AppLoadingScreen(),
            ),
    );
  }
}

class _ReceiptHeader extends StatelessWidget {
  const _ReceiptHeader({required this.onBackTap});

  final VoidCallback onBackTap;

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
            '스캔 내역 확인',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF07126C),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannedItemsCard extends StatelessWidget {
  const _ScannedItemsCard({
    required this.items,
    required this.currency,
    required this.snapshot,
    required this.convertToKrw,
    required this.onEdit,
    required this.onDelete,
  });

  final List<_EditableReceiptItem> items;
  final String currency;
  final ExchangeRatesSnapshot snapshot;
  final double Function(double amount, ExchangeRatesSnapshot snapshot)
  convertToKrw;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _ScannedItemRow(
              item: items[index],
              currency: currency,
              krwAmount: convertToKrw(items[index].amount, snapshot),
              onEdit: () => onEdit(index),
              onDelete: () => onDelete(index),
            ),
            if (index != items.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }
}

class _ScannedItemRow extends StatelessWidget {
  const _ScannedItemRow({
    required this.item,
    required this.currency,
    required this.krwAmount,
    required this.onEdit,
    required this.onDelete,
  });

  final _EditableReceiptItem item;
  final String currency;
  final double krwAmount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 13),
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF272B36),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.category,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF4D5565),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                RecordPresenter.amountWithSymbol(currency, item.amount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF222631),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₩${NumberFormat('#,##0').format(krwAmount)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFC0C2C8),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          const SizedBox(width: 9),
          _SmallIconButton(icon: Icons.edit_rounded, onTap: onEdit),
          const SizedBox(width: 4),
          _SmallIconButton(icon: Icons.delete_outline_rounded, onTap: onDelete),
        ],
      ),
    );
  }
}

class _ReceiptFormCard extends StatelessWidget {
  const _ReceiptFormCard({
    required this.totalAmount,
    required this.amountKrw,
    required this.currency,
    required this.currencyOptions,
    required this.category,
    required this.categories,
    required this.date,
    required this.placeController,
    required this.memoController,
    required this.onCurrencyChanged,
    required this.onCategoryChanged,
    required this.onDateTap,
  });

  final double totalAmount;
  final double amountKrw;
  final String currency;
  final List<String> currencyOptions;
  final String category;
  final List<String> categories;
  final DateTime date;
  final TextEditingController placeController;
  final TextEditingController memoController;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onDateTap;

  @override
  Widget build(BuildContext context) {
    return _WhiteCard(
      padding: const EdgeInsets.fromLTRB(17, 16, 17, 16),
      child: Column(
        children: [
          Text(
            '총 결제 금액',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF4E5668)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currency,
                  items: currencyOptions
                      .map(
                        (code) =>
                            DropdownMenuItem(value: code, child: Text(code)),
                      )
                      .toList(),
                  onChanged: onCurrencyChanged,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF07126C),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                totalAmount.toStringAsFixed(2),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: const Color(0xFF07126C),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '⇄ ≈ ${NumberFormat('#,##0').format(amountKrw)} KRW',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF4B5260)),
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
              children: categories
                  .map(
                    (item) => ChoiceChip(
                      label: Text(item),
                      selected: category == item,
                      onSelected: (_) => onCategoryChanged(item),
                      selectedColor: const Color(0xFFDCE8FF),
                      backgroundColor: const Color(0xFFF8F8FA),
                      labelStyle: TextStyle(
                        color: category == item
                            ? AppTheme.primary
                            : const Color(0xFF343946),
                        fontWeight: FontWeight.w700,
                      ),
                      side: const BorderSide(color: Color(0xFFD7DAE3)),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 25),
          _FormLabel('일시'),
          const SizedBox(height: 9),
          _ReadonlyField(
            icon: Icons.calendar_today_outlined,
            value: DateFormat('MM/dd/yyyy, hh:mm a').format(date),
            onTap: onDateTap,
          ),
          const SizedBox(height: 23),
          _FormLabel('장소'),
          const SizedBox(height: 9),
          _SoftTextField(
            controller: placeController,
            icon: Icons.location_on_outlined,
            hintText: '장소를 입력하세요',
          ),
          const SizedBox(height: 23),
          _FormLabel('메모'),
          const SizedBox(height: 9),
          _SoftTextField(
            controller: memoController,
            hintText: '메모를 입력하세요 (선택)',
            minLines: 2,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

class _BottomSaveBar extends StatelessWidget {
  const _BottomSaveBar({required this.saving, required this.onSave});

  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(23, 16, 20, bottomInset + 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDEFF5))),
      ),
      child: ElevatedButton.icon(
        onPressed: saving ? null : onSave,
        icon: const Icon(Icons.save_outlined, size: 18),
        label: Text(saving ? '저장 중...' : '내역 저장하기'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0B66D8),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
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
  const _ReadonlyField({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Ink(
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
      ),
    );
  }
}

class _SoftTextField extends StatelessWidget {
  const _SoftTextField({
    required this.controller,
    required this.hintText,
    this.icon,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData? icon;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: icon == null
            ? null
            : Icon(icon, size: 22, color: const Color(0xFF7A8190)),
        filled: true,
        fillColor: const Color(0xFFF4F2F3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: AppTheme.primary),
        ),
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 19, color: const Color(0xFF737987)),
      ),
    );
  }
}

class _EditableReceiptItem {
  const _EditableReceiptItem({
    required this.name,
    required this.category,
    required this.amount,
  });

  final String name;
  final String category;
  final double amount;
}

double _parseAmount(String value) {
  final cleaned = value.replaceAll(RegExp(r'[^0-9\.\-]'), '');
  return double.tryParse(cleaned) ?? 0;
}
