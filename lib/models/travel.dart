import 'package:hive/hive.dart';

part 'travel.g.dart';

@HiveType(typeId: 2)
class Travel extends HiveObject {
  Travel({
    required this.id,
    required this.title,
    required this.country,
    required this.startDate,
    required this.endDate,
    required this.budgetKrw,
    required this.exchangeSourceAmount,
    required this.exchangeSourceCurrency,
    required this.exchangeTargetAmount,
    required this.exchangeTargetCurrency,
    required this.createdAt,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String country;

  @HiveField(3)
  final DateTime startDate;

  @HiveField(4)
  final DateTime endDate;

  @HiveField(5)
  final double budgetKrw;

  @HiveField(6)
  final double? exchangeSourceAmount;

  @HiveField(7)
  final String exchangeSourceCurrency;

  @HiveField(8)
  final double? exchangeTargetAmount;

  @HiveField(9)
  final String exchangeTargetCurrency;

  @HiveField(10)
  final DateTime createdAt;
}
