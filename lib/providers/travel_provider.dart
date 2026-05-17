import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/travel.dart';

const travelBoxName = 'travel_plans';

final travelProvider = StateNotifierProvider<TravelNotifier, List<Travel>>((
  ref,
) {
  return TravelNotifier(Hive.box<Travel>(travelBoxName));
});

class TravelNotifier extends StateNotifier<List<Travel>> {
  TravelNotifier(this._box) : super(_sorted(_box.values.toList())) {
    _listenable = _box.listenable();
    _listenable.addListener(_refresh);
  }

  final Box<Travel> _box;
  late final ValueListenable<Box<Travel>> _listenable;

  static List<Travel> _sorted(List<Travel> travels) {
    travels.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return travels;
  }

  Future<void> add(Travel travel) async {
    await _box.put(travel.id, travel);
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
