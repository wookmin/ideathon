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
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              _HeroPanel(
                connectionCount: state.connections.length,
                transactionCount: state.transactions.length,
                statusMessage: state.statusMessage,
              ),
              const SizedBox(height: 20),
              _ConnectionForm(
                formKey: _formKey,
                selectedIssuerKey: _selectedIssuerKey,
                issuers: _cardIssuers,
                organizationController: _organizationController,
                organizationNameController: _organizationNameController,
                loginIdController: _loginIdController,
                passwordController: _passwordController,
                birthDateController: _birthDateController,
                isSubmitting: state.isSubmitting,
                onIssuerChanged: (value) =>
                    setState(() => _selectedIssuerKey = value),
                onSubmit: _connect,
              ),
              const SizedBox(height: 20),
              _SyncRangeCard(
                startDate: _startDate,
                endDate: _endDate,
                inquiryType: _inquiryType,
                orderBy: _orderBy,
                showAdvancedOptions: _showAdvancedSyncOptions,
                onPickStartDate: () => _pickDate(isStart: true),
                onPickEndDate: () => _pickDate(isStart: false),
                onInquiryTypeChanged: (value) =>
                    setState(() => _inquiryType = value),
                onOrderByChanged: (value) => setState(() => _orderBy = value),
                onToggleAdvancedOptions: () => setState(
                  () => _showAdvancedSyncOptions = !_showAdvancedSyncOptions,
                ),
              ),
              const SizedBox(height: 24),
              Text('연결된 카드사', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (state.connections.isEmpty)
                const _EmptyCard(
                  title: '아직 연결된 카드사가 없습니다.',
                  description: '카드사를 선택하고 로그인 정보를 입력하면 보유 카드까지 자동으로 불러옵니다.',
                )
              else
                ...state.connections.map(
                  (connection) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ConnectionTile(
                      connection: connection,
                      cards: state.cardsByConnection[connection.id] ?? const [],
                      selectedCardNo: _selectedCardNos[connection.id],
                      isBusy:
                          state.activeConnectionId == connection.id &&
                          (state.isSubmitting || state.isSyncing),
                      onLoadCards: () => _loadCards(connection),
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
              const SizedBox(height: 24),
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
                ...state.transactions
                    .take(20)
                    .map(
                      (transaction) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TransactionTile(transaction: transaction),
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

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.connectionCount,
    required this.transactionCount,
    required this.statusMessage,
  });

  final int connectionCount;
  final int transactionCount;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryStrong],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CODEF 카드 연동',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '앱에서 직접 카드사 비밀키를 다루지 않고, 백엔드를 통해 승인내역을 가져옵니다.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _MetricPill(label: '연결', value: '$connectionCount개'),
              const SizedBox(width: 10),
              _MetricPill(label: '거래', value: '$transactionCount건'),
            ],
          ),
          if (statusMessage != null && statusMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              statusMessage!,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _ConnectionForm extends StatelessWidget {
  const _ConnectionForm({
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.line),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('카드 연결 준비', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '카드사를 고르고 로그인 정보를 입력하면 보유 카드까지 이어서 확인합니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedIssuer.key,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '카드사'),
              items: issuers
                  .map(
                    (issuer) => DropdownMenuItem(
                      value: issuer.key,
                      child: Text(
                        issuer.isCustom ? '다른 카드사 직접 입력' : issuer.name,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onIssuerChanged(value);
                }
              },
            ),
            if (selectedIssuer.isCustom) ...[
              const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            TextFormField(
              controller: loginIdController,
              decoration: const InputDecoration(labelText: '카드사 로그인 ID'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: '카드사 비밀번호'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: birthDateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '생년월일',
                hintText: '예: 19950130',
              ),
              validator: _birthDate,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              child: Text(isSubmitting ? '연결 중...' : '안전하게 연결하기'),
            ),
            const SizedBox(height: 10),
            Text(
              '카드사 ID/PW는 저장하지 않고 연결 요청에만 사용합니다.',
              style: Theme.of(context).textTheme.labelMedium,
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

class _SyncRangeCard extends StatelessWidget {
  const _SyncRangeCard({
    required this.startDate,
    required this.endDate,
    required this.inquiryType,
    required this.orderBy,
    required this.showAdvancedOptions,
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
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final ValueChanged<String> onInquiryTypeChanged;
  final ValueChanged<String> onOrderByChanged;
  final VoidCallback onToggleAdvancedOptions;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy년 M월 d일', 'ko');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('가져오기 설정', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            '기본값은 최근 30일, 최신순입니다.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onPickStartDate,
                  child: Text('시작일 ${formatter.format(startDate)}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onPickEndDate,
                  child: Text('종료일 ${formatter.format(endDate)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onToggleAdvancedOptions,
            icon: Icon(
              showAdvancedOptions
                  ? Icons.expand_less_rounded
                  : Icons.tune_rounded,
            ),
            label: Text(showAdvancedOptions ? '상세 옵션 닫기' : '상세 옵션'),
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
            const SizedBox(height: 12),
          ],
          Text(
            '카드가 1개면 자동 선택하고, 여러 개면 아래에서 선택합니다.',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile({
    required this.connection,
    required this.cards,
    required this.selectedCardNo,
    required this.isBusy,
    required this.onLoadCards,
    required this.onCardSelected,
    required this.onSync,
    required this.onDelete,
  });

  final CardConnection connection;
  final List<CardAccount> cards;
  final String? selectedCardNo;
  final bool isBusy;
  final VoidCallback onLoadCards;
  final ValueChanged<String> onCardSelected;
  final VoidCallback onSync;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
                  connection.organizationName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _StatusChip(label: connection.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'organization: ${connection.organization}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            connection.lastSyncedAt == null
                ? '아직 동기화 기록이 없습니다.'
                : '마지막 동기화 ${RecordPresenter.relativeDate(connection.lastSyncedAt!)}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: isBusy ? null : onLoadCards,
            child: Text(cards.isEmpty ? '보유 카드 조회' : '보유 카드 다시 조회'),
          ),
          if (cards.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedCardNo ?? cards.first.cardNo,
              isExpanded: true,
              decoration: const InputDecoration(labelText: '조회할 카드 선택'),
              items: cards
                  .map(
                    (card) => DropdownMenuItem(
                      value: card.cardNo,
                      child: Text(
                        '${card.cardName} · ${card.cardNo}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: isBusy
                  ? null
                  : (value) {
                      if (value != null) {
                        onCardSelected(value);
                      }
                    },
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isBusy ? null : onSync,
                  child: Text(isBusy ? '처리 중...' : '승인내역 불러오기'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : onDelete,
                  child: const Text('연결 해제'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isActive = label == 'ACTIVE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.ok.withValues(alpha: 0.12)
            : AppTheme.warn.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: isActive ? AppTheme.ok : AppTheme.warn,
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final CardTransaction transaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.credit_card_rounded,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.merchantName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.organizationName} · ${transaction.cardNoMasked}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  RecordPresenter.relativeDate(transaction.approvedAt),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                if (transaction.originCurrency != null &&
                    transaction.originAmount != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.originCurrency} ${transaction.originAmount!.toStringAsFixed(2)}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: AppTheme.primary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₩${NumberFormat('#,##0').format(transaction.amountKrw)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                transaction.cardName.isEmpty
                    ? transaction.approvalStatus
                    : transaction.cardName,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ],
      ),
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
