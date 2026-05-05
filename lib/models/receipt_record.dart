import 'package:hive/hive.dart';

import 'receipt_analysis.dart';

part 'receipt_record.g.dart';

@HiveType(typeId: 1)
class ReceiptItem extends HiveObject {
  ReceiptItem({
    required this.name,
    required this.paid,
    required this.avg,
    required this.status,
  });

  @HiveField(0)
  final String name;
  @HiveField(1)
  final String paid;
  @HiveField(2)
  final String avg;
  @HiveField(3)
  final String status;

  factory ReceiptItem.fromAnalysis(ReceiptAnalysisItem item) {
    return ReceiptItem(
      name: item.name,
      paid: item.paid,
      avg: item.avg,
      status: item.status,
    );
  }
}

@HiveType(typeId: 0)
class ReceiptRecord extends HiveObject {
  ReceiptRecord({
    required this.id,
    required this.date,
    required this.country,
    required this.countryCode,
    required this.city,
    required this.currency,
    required this.originalAmount,
    required this.krwAmount,
    required this.exchangeRate,
    required this.rawOcrText,
    required this.items,
    required this.verdict,
    required this.tipPct,
    required this.tipKrw,
    required this.memo,
    required this.imagePath,
    required this.analysis,
  });

  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  final String country;
  @HiveField(3)
  final String countryCode;
  @HiveField(4)
  final String currency;
  @HiveField(5)
  final double originalAmount;
  @HiveField(6)
  final double krwAmount;
  @HiveField(7)
  final double exchangeRate;
  @HiveField(8)
  final String rawOcrText;
  @HiveField(9)
  final List<ReceiptItem> items;
  @HiveField(10)
  final String verdict;
  @HiveField(11)
  final double tipPct;
  @HiveField(12)
  final double tipKrw;
  @HiveField(13)
  final String memo;
  @HiveField(14)
  final String? imagePath;
  @HiveField(15)
  final String analysis;
  @HiveField(16)
  final String city;
}
