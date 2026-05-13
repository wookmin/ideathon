class CardConnection {
  const CardConnection({
    required this.id,
    required this.organization,
    required this.organizationName,
    required this.loginType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lastSyncedAt,
  });

  final String id;
  final String organization;
  final String organizationName;
  final String loginType;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastSyncedAt;

  factory CardConnection.fromJson(Map<String, dynamic> json) {
    return CardConnection(
      id: json['id'] as String? ?? '',
      organization: json['organization'] as String? ?? '',
      organizationName: json['organizationName'] as String? ?? '',
      loginType: json['loginType'] as String? ?? '1',
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      lastSyncedAt: DateTime.tryParse(json['lastSyncedAt'] as String? ?? ''),
    );
  }
}
