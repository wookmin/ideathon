import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card_connection.dart';
import '../models/card_transaction.dart';
import '../services/financial_api_service.dart';
import 'exchange_provider.dart';

final financialApiServiceProvider = FutureProvider<FinancialApiService>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return FinancialApiService(ref.watch(dioProvider), prefs);
});

class CardSyncState {
  const CardSyncState({
    required this.connections,
    required this.transactions,
    this.isSubmitting = false,
    this.isSyncing = false,
    this.activeConnectionId,
    this.statusMessage,
  });

  final List<CardConnection> connections;
  final List<CardTransaction> transactions;
  final bool isSubmitting;
  final bool isSyncing;
  final String? activeConnectionId;
  final String? statusMessage;

  CardSyncState copyWith({
    List<CardConnection>? connections,
    List<CardTransaction>? transactions,
    bool? isSubmitting,
    bool? isSyncing,
    String? activeConnectionId,
    String? statusMessage,
    bool clearStatusMessage = false,
  }) {
    return CardSyncState(
      connections: connections ?? this.connections,
      transactions: transactions ?? this.transactions,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSyncing: isSyncing ?? this.isSyncing,
      activeConnectionId: activeConnectionId ?? this.activeConnectionId,
      statusMessage: clearStatusMessage ? null : (statusMessage ?? this.statusMessage),
    );
  }
}

final cardSyncProvider =
    AsyncNotifierProvider<CardSyncNotifier, CardSyncState>(CardSyncNotifier.new);

class CardSyncNotifier extends AsyncNotifier<CardSyncState> {
  @override
  Future<CardSyncState> build() async {
    final service = await ref.watch(financialApiServiceProvider.future);
    final connections = await service.listConnections();
    final transactions = await service.listTransactions();
    return CardSyncState(
      connections: connections,
      transactions: transactions,
    );
  }

  Future<void> refresh() async {
    final current = state.valueOrNull ??
        const CardSyncState(connections: [], transactions: []);
    state = const AsyncLoading<CardSyncState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final service = await ref.read(financialApiServiceProvider.future);
      final connections = await service.listConnections();
      final transactions = await service.listTransactions();
      return current.copyWith(
        connections: connections,
        transactions: transactions,
        isSubmitting: false,
        isSyncing: false,
        activeConnectionId: null,
      );
    });
  }

  Future<void> createConnection({
    required String organization,
    required String organizationName,
    required String loginType,
    required String loginId,
    required String password,
  }) async {
    final current = _requireState();
    state = AsyncData(
      current.copyWith(
        isSubmitting: true,
        clearStatusMessage: true,
      ),
    );

    try {
      final service = await ref.read(financialApiServiceProvider.future);
      await service.createConnection(
        organization: organization,
        organizationName: organizationName,
        loginType: loginType,
        loginId: loginId,
        password: password,
      );
      await refresh();
      final refreshed = _requireState();
      state = AsyncData(
        refreshed.copyWith(
          statusMessage: '카드사 연결을 완료했습니다.',
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isSubmitting: false,
          activeConnectionId: null,
        ),
      );
      rethrow;
    }
  }

  Future<void> syncConnection({
    required String connectionId,
    required String startDate,
    required String endDate,
    String? cardNo,
  }) async {
    final current = _requireState();
    state = AsyncData(
      current.copyWith(
        isSyncing: true,
        activeConnectionId: connectionId,
        clearStatusMessage: true,
      ),
    );

    try {
      final service = await ref.read(financialApiServiceProvider.future);
      final syncedTransactions = await service.syncConnection(
        connectionId: connectionId,
        startDate: startDate,
        endDate: endDate,
        cardNo: cardNo,
      );
      final connections = await service.listConnections();
      final transactions = await service.listTransactions();
      state = AsyncData(
        CardSyncState(
          connections: connections,
          transactions: transactions,
          statusMessage: '동기화 완료: ${syncedTransactions.length}건을 불러왔습니다.',
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isSyncing: false,
          activeConnectionId: null,
        ),
      );
      rethrow;
    }
  }

  Future<void> deleteConnection(String connectionId) async {
    final current = _requireState();
    state = AsyncData(
      current.copyWith(
        isSubmitting: true,
        activeConnectionId: connectionId,
        clearStatusMessage: true,
      ),
    );

    try {
      final service = await ref.read(financialApiServiceProvider.future);
      await service.deleteConnection(connectionId);
      final connections = await service.listConnections();
      final transactions = await service.listTransactions();
      state = AsyncData(
        CardSyncState(
          connections: connections,
          transactions: transactions,
          statusMessage: '카드 연결을 해제했습니다.',
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isSubmitting: false,
          activeConnectionId: null,
        ),
      );
      rethrow;
    }
  }

  CardSyncState _requireState() {
    return state.valueOrNull ?? const CardSyncState(connections: [], transactions: []);
  }
}
