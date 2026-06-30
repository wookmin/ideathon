import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/card_account.dart';
import '../models/card_connection.dart';
import '../models/card_transaction.dart';
import '../providers/financial_provider.dart';
import '../utils/record_presenter.dart';

class _CardIssuer {
  const _CardIssuer({
    required this.name,
    required this.organization,
    this.isCustom = false,
  });

  final String name;
  final String organization;
  final bool isCustom;

  String get key => isCustom ? 'custom' : organization;

  String get shortLabel => isCustom ? '직접' : name.replaceAll('카드', '');
}

const _cardIssuers = [
  _CardIssuer(name: 'KB국민카드', organization: '0301'),
  _CardIssuer(name: '현대카드', organization: '0302'),
  _CardIssuer(name: '삼성카드', organization: '0303'),
  _CardIssuer(name: 'NH농협카드', organization: '0304'),
  _CardIssuer(name: 'BC카드', organization: '0305'),
  _CardIssuer(name: '신한카드', organization: '0306'),
  _CardIssuer(name: '한국씨티카드', organization: '0307'),
  _CardIssuer(name: '우리카드', organization: '0309'),
  _CardIssuer(name: '롯데카드', organization: '0311'),
  _CardIssuer(name: '하나카드', organization: '0313'),
  _CardIssuer(name: '전북카드', organization: '0315'),
  _CardIssuer(name: '광주카드', organization: '0316'),
  _CardIssuer(name: 'Sh수협카드', organization: '0320'),
  _CardIssuer(name: '제주카드', organization: '0321'),
  _CardIssuer(name: '직접 입력', organization: '', isCustom: true),
];

const List<Color> _issuerPalette = [
  Color(0xFF1F2533),
  Color(0xFF1565D8),
  Color(0xFF0EA5A4),
  Color(0xFF7C5CFC),
  Color(0xFFE8527B),
  Color(0xFF2E9E6C),
  Color(0xFFC2410C),
];

Color _colorForOrganization(String organization) {
  if (organization.isEmpty) {
    return AppTheme.textSecondary;
  }
  final hash = organization.codeUnits.fold<int>(0, (acc, c) => acc + c);
  return _issuerPalette[hash % _issuerPalette.length];
}

class CardSyncScreen extends ConsumerStatefulWidget {
  const CardSyncScreen({super.key});

  @override
  ConsumerState<CardSyncScreen> createState() => _CardSyncScreenState();
}

class _CardSyncScreenState extends ConsumerState<CardSyncScreen> {
  final _formKey = GlobalKey<FormState>();
  final _organizationController = TextEditingController();
  final _organizationNameController = TextEditingController();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthDateController = TextEditingController();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedIssuerKey = _cardIssuers.first.key;
  String _inquiryType = '0';
  String _orderBy = '0';
  bool _showAdvancedSyncOptions = false;
  final Map<String, String> _selectedCardNos = {};

  @override
  void dispose() {
    _organizationController.dispose();
    _organizationNameController.dispose();
    _loginIdController.dispose();
    _passwordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final selectedIssuer = _selectedIssuer;
      final organization = selectedIssuer.isCustom
          ? _organizationController.text.trim()
          : selectedIssuer.organization;
      final organizationName = selectedIssuer.isCustom
          ? _organizationNameController.text.trim()
          : selectedIssuer.name;
      final connection = await ref
          .read(cardSyncProvider.notifier)
          .createConnection(
            organization: organization,
            organizationName: organizationName,
            loginType: '1',
            loginId: _loginIdController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) {
        return;
      }
      _passwordController.clear();
      Navigator.of(context).maybePop();
      final cards = await _loadCards(connection, showSnackBar: false);
      if (!mounted) {
        return;
      }
      final message = cards.isEmpty
          ? '카드사 연결을 저장했습니다. 조회 가능한 카드가 없습니다.'
          : '카드사 연결 후 ${cards.length}개의 카드를 불러왔습니다.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _sync(CardConnection connection) async {
    final birthDate = _birthDateController.text.trim();
    if (!RegExp(r'^\d{8}$').hasMatch(birthDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생년월일을 YYYYMMDD 형식으로 입력해 주세요.')),
      );
      return;
    }
    final selectedCardNo = _selectedCardNos[connection.id];
    if (selectedCardNo == null || selectedCardNo.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 보유 카드를 조회하고 조회할 카드를 선택해 주세요.')),
      );
      return;
    }

    try {
      await ref
          .read(cardSyncProvider.notifier)
          .syncConnection(
            connectionId: connection.id,
            startDate: _compactDate(_startDate),
            endDate: _compactDate(_endDate),
            birthDate: birthDate,
            inquiryType: _inquiryType,
            orderBy: _orderBy,
            cardNo: selectedCardNo,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('승인내역 동기화를 완료했습니다.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<List<CardAccount>> _loadCards(
    CardConnection connection, {
    bool showSnackBar = true,
    bool forceRefresh = false,
  }) async {
    final birthDate = _birthDateController.text.trim();
    if (!RegExp(r'^\d{8}$').hasMatch(birthDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생년월일을 YYYYMMDD 형식으로 입력해 주세요.')),
      );
      return const [];
    }

    try {
      final cards = await ref
          .read(cardSyncProvider.notifier)
          .loadCards(
            connectionId: connection.id,
            birthDate: birthDate,
            inquiryType: _inquiryType,
            forceRefresh: forceRefresh,
          );
      if (!mounted) {
        return cards;
      }
      if (cards.isEmpty) {
        if (showSnackBar) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('조회 가능한 카드 목록이 없습니다.')));
        }
        return cards;
      }
      setState(() {
        _selectedCardNos.putIfAbsent(connection.id, () => cards.first.cardNo);
      });
      if (showSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${cards.length}개의 카드를 불러왔습니다.')),
        );
      }
      return cards;
    } catch (error) {
      if (!mounted) {
        return const [];
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
      return const [];
    }
  }

  Future<void> _delete(CardConnection connection) async {
    try {
      await ref.read(cardSyncProvider.notifier).deleteConnection(connection.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('카드 연결을 해제했습니다.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  void _applyQuickRange(int days) {
    setState(() {
      _endDate = DateTime.now();
      _startDate = DateTime.now().subtract(Duration(days: days));
    });
  }

  void _openConnectSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.5,
            maxChildSize: 0.96,
            expand: false,
            builder: (context, scrollController) {
              return StatefulBuilder(
                builder: (context, setSheetState) {
                  return Consumer(
                    builder: (context, ref, _) {
                      final isSubmitting = ref.watch(
                        cardSyncProvider.select(
                          (value) => value.valueOrNull?.isSubmitting ?? false,
                        ),
                      );
                      return _ConnectSheet(
                        scrollController: scrollController,
                        formKey: _formKey,
                        selectedIssuerKey: _selectedIssuerKey,
                        issuers: _cardIssuers,
                        organizationController: _organizationController,
                        organizationNameController:
                            _organizationNameController,
                        loginIdController: _loginIdController,
                        passwordController: _passwordController,
                        birthDateController: _birthDateController,
                        isSubmitting: isSubmitting,
                        onIssuerChanged: (value) {
                          setState(() => _selectedIssuerKey = value);
                          setSheetState(() {});
                        },
                        onSubmit: _connect,
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(cardSyncProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('카드 불러오기'),
        actions: [
          IconButton(
            onPressed: () => ref.read(cardSyncProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: syncState.when(
        data: (state) => RefreshIndicator(
          onRefresh: () => ref.read(cardSyncProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              _SummaryHeader(
                connectionCount: state.connections.length,
                transactionCount: state.transactions.length,
                statusMessage: state.statusMessage,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '연결된 카드사',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _openConnectSheet,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('연결하기'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (state.connections.isEmpty)
                _EmptyConnectCard(onTap: _openConnectSheet)
              else
                ...state.connections.map(
                  (connection) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ConnectionCard(
                      connection: connection,
                      cards: state.cardsByConnection[connection.id] ?? const [],
                      selectedCardNo: _selectedCardNos[connection.id],
                      isBusy:
                          state.activeConnectionId == connection.id &&
                          (state.isSubmitting || state.isSyncing),
                      startDate: _startDate,
                      endDate: _endDate,
                      onLoadCards: () =>
                          _loadCards(connection, forceRefresh: true),
                      onCardSelected: (value) {
                        setState(() {
                          _selectedCardNos[connection.id] = value;
                        });
                      },
                      onSync: () => _sync(connection),
                      onDelete: () => _delete(connection),
                    ),
                  ),
                ),
              if (state.connections.isNotEmpty) ...[
                const SizedBox(height: 20),
                _RangeSelector(
                  startDate: _startDate,
                  endDate: _endDate,
                  inquiryType: _inquiryType,
                  orderBy: _orderBy,
                  showAdvancedOptions: _showAdvancedSyncOptions,
                  onQuickRange: _applyQuickRange,
                  onPickStartDate: () => _pickDate(isStart: true),
                  onPickEndDate: () => _pickDate(isStart: false),
                  onInquiryTypeChanged: (value) =>
                      setState(() => _inquiryType = value),
                  onOrderByChanged: (value) => setState(() => _orderBy = value),
                  onToggleAdvancedOptions: () => setState(
                    () => _showAdvancedSyncOptions = !_showAdvancedSyncOptions,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Text(
                '최근 불러온 승인내역',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (state.transactions.isEmpty)
                const _EmptyCard(
                  title: '불러온 거래내역이 없습니다.',
                  description: '카드 연결 후 최근 30일 승인내역 동기화를 실행해 보세요.',
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.line),
                  ),
                  child: Column(
                    children: state.transactions
                        .take(20)
                        .toList()
                        .asMap()
                        .entries
                        .map(
                          (entry) => _TransactionTile(
                            transaction: entry.value,
                            showDivider: entry.key != 0,
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(cardSyncProvider),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _compactDate(DateTime date) => DateFormat('yyyyMMdd').format(date);

  _CardIssuer get _selectedIssuer {
    return _cardIssuers.firstWhere(
      (issuer) => issuer.key == _selectedIssuerKey,
      orElse: () => _cardIssuers.first,
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.connectionCount,
    required this.transactionCount,
    required this.statusMessage,
  });

  final int connectionCount;
  final int transactionCount;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _StatBlock(label: '연결된 카드사', value: '$connectionCount'),
            ),
            Container(width: 1, height: 36, color: AppTheme.line),
            const SizedBox(width: 20),
            Expanded(
              child: _StatBlock(label: '불러온 거래', value: '$transactionCount'),
            ),
          ],
        ),
        if (statusMessage != null && statusMessage!.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusMessage!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.primaryStrong,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 28,
          ),
        ),
      ],
    );
  }
}

class _EmptyConnectCard extends StatelessWidget {
  const _EmptyConnectCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.25),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_card_rounded,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '카드사를 연결해 보세요',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '로그인 정보만 입력하면 보유 카드까지 자동으로 불러옵니다.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}

class _ConnectSheet extends StatelessWidget {
  const _ConnectSheet({
    required this.scrollController,
    required this.formKey,
    required this.selectedIssuerKey,
    required this.issuers,
    required this.organizationController,
    required this.organizationNameController,
    required this.loginIdController,
    required this.passwordController,
    required this.birthDateController,
    required this.isSubmitting,
    required this.onIssuerChanged,
    required this.onSubmit,
  });

  final ScrollController scrollController;
  final GlobalKey<FormState> formKey;
  final String selectedIssuerKey;
  final List<_CardIssuer> issuers;
  final TextEditingController organizationController;
  final TextEditingController organizationNameController;
  final TextEditingController loginIdController;
  final TextEditingController passwordController;
  final TextEditingController birthDateController;
  final bool isSubmitting;
  final ValueChanged<String> onIssuerChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final selectedIssuer = issuers.firstWhere(
      (issuer) => issuer.key == selectedIssuerKey,
      orElse: () => issuers.first,
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: formKey,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('카드사 연결', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              '카드사 ID/PW는 저장하지 않고 연결 요청에만 사용합니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.6,
              children: issuers.map((issuer) {
                final isSelected = issuer.key == selectedIssuerKey;
                final color = _colorForOrganization(issuer.organization);
                return GestureDetector(
                  onTap: () => onIssuerChanged(issuer.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected ? color : AppTheme.line,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (issuer.isCustom)
                          Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: isSelected ? Colors.white : color,
                          )
                        else
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            issuer.isCustom ? '직접 입력' : issuer.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (selectedIssuer.isCustom) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: organizationController,
                decoration: const InputDecoration(
                  labelText: '카드사 코드',
                  hintText: 'CODEF organization 코드',
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: organizationNameController,
                decoration: const InputDecoration(
                  labelText: '카드사 이름',
                  hintText: '예: 신한카드',
                ),
                validator: _required,
              ),
            ],
            const SizedBox(height: 20),
            Text('로그인 정보', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: loginIdController,
              decoration: const InputDecoration(
                labelText: '카드사 로그인 ID',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '카드사 비밀번호',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: birthDateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '생년월일',
                hintText: '예: 19950130',
                prefixIcon: Icon(Icons.cake_outlined),
              ),
              validator: _birthDate,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              child: Text(isSubmitting ? '연결 중...' : '안전하게 연결하기'),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '필수 입력값입니다.';
    }
    return null;
  }

  String? _birthDate(String? value) {
    final trimmed = value?.trim() ?? '';
    if (!RegExp(r'^\d{8}$').hasMatch(trimmed)) {
      return 'YYYYMMDD 형식으로 입력해 주세요.';
    }
    return null;
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.startDate,
    required this.endDate,
    required this.inquiryType,
    required this.orderBy,
    required this.showAdvancedOptions,
    required this.onQuickRange,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onInquiryTypeChanged,
    required this.onOrderByChanged,
    required this.onToggleAdvancedOptions,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String inquiryType;
  final String orderBy;
  final bool showAdvancedOptions;
  final ValueChanged<int> onQuickRange;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final ValueChanged<String> onInquiryTypeChanged;
  final ValueChanged<String> onOrderByChanged;
  final VoidCallback onToggleAdvancedOptions;

  static const _quickRanges = [7, 30, 90];

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('M.d', 'ko');
    final currentSpan = endDate.difference(startDate).inDays;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '가져오기 기간',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              GestureDetector(
                onTap: onPickStartDate,
                child: Text(
                  '${formatter.format(startDate)} ~ ${formatter.format(endDate)}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._quickRanges.map((days) {
                final isActive = currentSpan == days;
                return ChoiceChip(
                  label: Text('최근 $days일'),
                  selected: isActive,
                  onSelected: (_) => onQuickRange(days),
                  selectedColor: AppTheme.primary,
                  backgroundColor: AppTheme.surfaceAlt,
                  labelStyle: TextStyle(
                    color: isActive ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
              ActionChip(
                label: const Text('직접 설정'),
                onPressed: onPickEndDate,
                backgroundColor: AppTheme.surfaceAlt,
                labelStyle: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: onToggleAdvancedOptions,
            icon: Icon(
              showAdvancedOptions
                  ? Icons.expand_less_rounded
                  : Icons.tune_rounded,
              size: 18,
            ),
            label: Text(showAdvancedOptions ? '상세 옵션 닫기' : '상세 옵션'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 36),
              alignment: Alignment.centerLeft,
            ),
          ),
          if (showAdvancedOptions) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: inquiryType,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '조회 유형'),
              items: const [
                DropdownMenuItem(value: '0', child: Text('기본 조회')),
                DropdownMenuItem(value: '1', child: Text('확장 조회')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onInquiryTypeChanged(value);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: orderBy,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '정렬 기준'),
              items: const [
                DropdownMenuItem(value: '0', child: Text('최신순')),
                DropdownMenuItem(value: '1', child: Text('과거순')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onOrderByChanged(value);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.connection,
    required this.cards,
    required this.selectedCardNo,
    required this.isBusy,
    required this.startDate,
    required this.endDate,
    required this.onLoadCards,
    required this.onCardSelected,
    required this.onSync,
    required this.onDelete,
  });

  final CardConnection connection;
  final List<CardAccount> cards;
  final String? selectedCardNo;
  final bool isBusy;
  final DateTime startDate;
  final DateTime endDate;
  final VoidCallback onLoadCards;
  final ValueChanged<String> onCardSelected;
  final VoidCallback onSync;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _colorForOrganization(connection.organization);
    final isActive = connection.status == 'ACTIVE';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.credit_card_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connection.organizationName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        connection.lastSyncedAt == null
                            ? '아직 동기화 기록이 없습니다'
                            : '마지막 동기화 ${RecordPresenter.relativeDate(connection.lastSyncedAt!)}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.ok.withValues(alpha: 0.12)
                        : AppTheme.warn.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isActive ? '연결됨' : connection.status,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isActive ? AppTheme.ok : AppTheme.warn,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('연결 해제'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cards.isEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : onLoadCards,
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text('보유 카드 조회'),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Text(
                        '조회할 카드',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: isBusy ? null : onLoadCards,
                        child: Text(
                          '다시 조회',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cards.map((card) {
                      final isSelected = (selectedCardNo ?? cards.first.cardNo) ==
                          card.cardNo;
                      return GestureDetector(
                        onTap: isBusy ? null : () => onCardSelected(card.cardNo),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? color : AppTheme.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${card.cardName} · ${card.cardNo}',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isBusy ? null : onSync,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                      ),
                      child: Text(isBusy ? '처리 중...' : '승인내역 불러오기'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.showDivider});

  final CardTransaction transaction;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final color = _colorForOrganization(transaction.organizationName);

    return Column(
      children: [
        if (showDivider) Divider(height: 1, color: AppTheme.line, indent: 16, endIndent: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.merchantName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${transaction.organizationName} · ${transaction.cardNoMasked} · ${RecordPresenter.relativeDate(transaction.approvedAt)}',
                      style: Theme.of(context).textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '₩${NumberFormat('#,##0').format(transaction.amountKrw)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
