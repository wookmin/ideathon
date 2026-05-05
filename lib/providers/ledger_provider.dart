import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/receipt_record.dart';

const ledgerBoxName = 'receipt_ledger';

final ledgerProvider =
    StateNotifierProvider<LedgerNotifier, List<ReceiptRecord>>((ref) {
      return LedgerNotifier(Hive.box<ReceiptRecord>(ledgerBoxName));
    });

class LedgerNotifier extends StateNotifier<List<ReceiptRecord>> {
  LedgerNotifier(this._box) : super(_sorted(_box.values.toList())) {
    _listenable = _box.listenable();
    _listenable.addListener(_refresh);
  }

  final Box<ReceiptRecord> _box;
  late final ValueListenable<Box<ReceiptRecord>> _listenable;

  static List<ReceiptRecord> _sorted(List<ReceiptRecord> records) {
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  Future<void> add(ReceiptRecord record) async {
    await _box.put(record.id, record);
    _refresh();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    _refresh();
  }

  void _refresh() {
    state = _sorted(_box.values.toList());
  }

  @override
  void dispose() {
    _listenable.removeListener(_refresh);
    super.dispose();
  }
}
