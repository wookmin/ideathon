import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'local_notification_service.dart';

const notificationHistoryBoxName = 'notification_history';

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AppNotificationItem.fromJson(Map<String, Object?> json) {
    return AppNotificationItem(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '알림',
      message: (json['message'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

class NotificationHistoryService {
  const NotificationHistoryService._();

  static Box<String> get _box => Hive.box<String>(notificationHistoryBoxName);

  static List<AppNotificationItem> all() {
    final items = <AppNotificationItem>[];
    for (final raw in _box.values) {
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        items.add(AppNotificationItem.fromJson(json));
      } catch (_) {}
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  static Future<void> add({
    required String title,
    required String message,
    DateTime? createdAt,
  }) async {
    final now = createdAt ?? DateTime.now();
    final item = AppNotificationItem(
      id: '${now.microsecondsSinceEpoch}',
      title: title,
      message: message,
      createdAt: now,
    );
    await _box.add(jsonEncode(item.toJson()));
    await LocalNotificationService.show(
      id: now.millisecondsSinceEpoch.remainder(1 << 31),
      title: title,
      message: message,
    );
  }

  static Future<void> addSampleNotifications() async {
    final now = DateTime.now();
    final samples = [
      (
        title: '위치 알림',
        message:
            '백화점에 10분 이상 머무는 중이에요. 여기서 써도 괜찮지만, 지금 쓰면 남은 3일은 하루 42,000원 기준이에요.',
        createdAt: now.subtract(const Duration(minutes: 3)),
      ),
      (
        title: '결제 알림',
        message:
            '방금 18,000원을 사용했어요. 오늘 안전 소비 가능액의 약 18%예요. 남은 하루 기준은 82,000원입니다.',
        createdAt: now.subtract(const Duration(minutes: 18)),
      ),
      (
        title: '예산 알림',
        message: '지금 속도면 여행 6일차쯤 예산이 부족할 수 있어요. 잠깐 남은 예산을 확인해볼까요?',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 7)),
      ),
    ];

    for (final sample in samples.reversed) {
      await add(
        title: sample.title,
        message: sample.message,
        createdAt: sample.createdAt,
      );
    }
  }
}
