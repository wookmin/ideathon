class CardTransaction {
  const CardTransaction({
    required this.id,
    required this.connectionId,
    required this.organization,
    required this.organizationName,
    required this.approvedAt,
    required this.merchantName,
    required this.amountKrw,
    required this.approvalAmount,
    required this.approvalStatus,
    required this.cardName,
    required this.cardNoMasked,
    this.approvalNo,
    this.originAmount,
    this.originCurrency,
    this.billingAmountKrw,
    this.billingCurrency,
    this.paymentType,
    this.installmentMonths,
  });

  final String id;
  final String connectionId;
  final String organization;
  final String organizationName;
  final DateTime approvedAt;
  final String merchantName;
  final double amountKrw;
  final double approvalAmount;
  final String approvalStatus;
  final String cardName;
  final String cardNoMasked;
  final String? approvalNo;
  final double? originAmount;
  final String? originCurrency;
  final double? billingAmountKrw;
  final String? billingCurrency;
  final String? paymentType;
  final int? installmentMonths;

  factory CardTransaction.fromJson(Map<String, dynamic> json) {
    return CardTransaction(
      id: json['id'] as String? ?? '',
      connectionId: json['connectionId'] as String? ?? '',
      organization: json['organization'] as String? ?? '',
      organizationName: json['organizationName'] as String? ?? '',
      approvedAt: DateTime.tryParse(json['approvedAt'] as String? ?? '') ?? DateTime.now(),
      merchantName: json['merchantName'] as String? ?? '알 수 없는 가맹점',
      amountKrw: _toDouble(json['amountKrw']),
      approvalAmount: _toDouble(json['approvalAmount']),
      approvalStatus: json['approvalStatus'] as String? ?? 'UNKNOWN',
      cardName: json['cardName'] as String? ?? '',
      cardNoMasked: json['cardNoMasked'] as String? ?? '',
      approvalNo: json['approvalNo'] as String?,
      originAmount: _toNullableDouble(json['originAmount']),
      originCurrency: json['originCurrency'] as String?,
      billingAmountKrw: _toNullableDouble(json['billingAmountKrw']),
      billingCurrency: json['billingCurrency'] as String?,
      paymentType: json['paymentType'] as String?,
      installmentMonths: _toNullableInt(json['installmentMonths']),
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? 0;
  }

  static double? _toNullableDouble(Object? value) {
    if (value == null) {
      return null;
    }
    return _toDouble(value);
  }

  static int? _toNullableInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value');
  }
}
