class CardAccount {
  const CardAccount({
    required this.cardNo,
    required this.cardName,
    required this.organization,
    required this.organizationName,
  });

  final String cardNo;
  final String cardName;
  final String organization;
  final String organizationName;

  factory CardAccount.fromJson(Map<String, dynamic> json) {
    return CardAccount(
      cardNo: (json['cardNo'] as String?) ?? (json['resCardNo'] as String?) ?? '',
      cardName: json['cardName'] as String? ?? '이름 없는 카드',
      organization: json['organization'] as String? ?? '',
      organizationName: json['organizationName'] as String? ?? '',
    );
  }
}
