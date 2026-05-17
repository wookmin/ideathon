import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/receipt_record.dart';
import '../models/travel.dart';
import 'travel_provider.dart';

const travelSelectionBoxName = 'travel_selection';
const selectedTravelIdKey = 'selected_travel_id';

final selectedTravelIdProvider =
    StateNotifierProvider<SelectedTravelNotifier, String?>((ref) {
      return SelectedTravelNotifier(Hive.box<String>(travelSelectionBoxName));
    });

final effectiveTravelProvider = Provider<Travel?>((ref) {
  final travels = ref.watch(travelProvider);
  final selectedTripId = ref.watch(selectedTravelIdProvider);

  if (selectedTripId != null) {
    for (final travel in travels) {
      if (travel.id == selectedTripId) {
        return travel;
      }
    }
  }

  final today = _dateOnly(DateTime.now());
  final activeTravels = travels.where((travel) {
    final start = _dateOnly(travel.startDate);
    final end = _dateOnly(travel.endDate);
    return !today.isBefore(start) && !today.isAfter(end);
  }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return activeTravels.isEmpty ? null : activeTravels.first;
});

class SelectedTravelNotifier extends StateNotifier<String?> {
  SelectedTravelNotifier(this._box) : super(_box.get(selectedTravelIdKey));

  final Box<String> _box;

  Future<void> select(String tripId) async {
    await _box.put(selectedTravelIdKey, tripId);
    state = tripId;
  }

  Future<void> clear() async {
    await _box.delete(selectedTravelIdKey);
    state = null;
  }
}

List<ReceiptRecord> scopedRecordsForTravel(
  List<ReceiptRecord> records,
  Travel? travel,
) {
  if (travel == null) {
    return records;
  }

  final start = _dateOnly(travel.startDate);
  final endExclusive = _dateOnly(travel.endDate).add(const Duration(days: 1));
  final country = travel.country.trim().toLowerCase();

  return records.where((record) {
    final recordCountry = record.country.trim().toLowerCase();
    return recordCountry == country &&
        !record.date.isBefore(start) &&
        record.date.isBefore(endExclusive);
  }).toList()..sort((a, b) => b.date.compareTo(a.date));
}

String displayStatusForTravel(Travel travel) {
  final today = _dateOnly(DateTime.now());
  final start = _dateOnly(travel.startDate);
  final end = _dateOnly(travel.endDate);

  if (today.isBefore(start)) {
    return 'D-${start.difference(today).inDays}';
  }
  if (today.isAfter(end)) {
    return '종료됨';
  }
  return '진행 중';
}

String displayPeriodForTravel(Travel travel) {
  return '${travel.startDate.year}.${travel.startDate.month.toString().padLeft(2, '0')}.${travel.startDate.day.toString().padLeft(2, '0')} - '
      '${travel.endDate.year}.${travel.endDate.month.toString().padLeft(2, '0')}.${travel.endDate.day.toString().padLeft(2, '0')}';
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
