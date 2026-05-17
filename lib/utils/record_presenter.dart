import 'package:intl/intl.dart';

import '../models/receipt_record.dart';

class RecordPresenter {
  const RecordPresenter._();

  static double totalSpend(List<ReceiptRecord> records) {
    return records.fold<double>(
      0,
      (sum, record) => sum + record.krwAmount + record.tipKrw,
    );
  }

  static double monthlySpend(List<ReceiptRecord> records) {
    final now = DateTime.now();
    return records
        .where((record) => record.date.year == now.year && record.date.month == now.month)
        .fold<double>(0, (sum, record) => sum + record.krwAmount + record.tipKrw);
  }

  static double dailyAverage(List<ReceiptRecord> records) {
    if (records.isEmpty) {
      return 0;
    }
    final sorted = [...records]..sort((a, b) => a.date.compareTo(b.date));
    final days = sorted.last.date.difference(sorted.first.date).inDays + 1;
    return totalSpend(records) / (days <= 0 ? 1 : days);
  }

  static String travelTitle(List<ReceiptRecord> records) {
    if (records.isEmpty) {
      return '여행 준비 중';
    }
    final latest = records.first;
    final location = [latest.country, latest.city]
        .where((value) => value.trim().isNotEmpty)
        .join(' ');
    return location.isEmpty ? '최근 여행' : '$location 여행';
  }

  static String travelDateRange(List<ReceiptRecord> records) {
    if (records.isEmpty) {
      return '영수증을 저장하면 여행 기간이 표시됩니다.';
    }
    final sorted = [...records]..sort((a, b) => a.date.compareTo(b.date));
    final formatter = DateFormat('yyyy년 M월 d일', 'ko');
    return '${formatter.format(sorted.first.date)} - ${formatter.format(sorted.last.date)}';
  }

  static String statusLabel(List<ReceiptRecord> records) {
    if (records.isEmpty) {
      return '준비 중';
    }
    final recent = DateTime.now().difference(records.first.date);
    if (recent.inDays <= 7) {
      return '진행 중';
    }
    return '보관 중';
  }

  static String title(ReceiptRecord record) {
    if (record.memo.trim().isNotEmpty) {
      return record.memo.trim();
    }
    final location = [record.city, record.country]
        .where((value) => value.trim().isNotEmpty)
        .join(' ');
    return location.isEmpty ? '저장된 영수증' : location;
  }

  static String category(ReceiptRecord record) {
    final text = '${record.memo} ${record.rawOcrText}'.toLowerCase();
    if (text.contains('hotel') || text.contains('숙박')) {
      return '숙박';
    }
    if (text.contains('metro') || text.contains('교통') || text.contains('항공')) {
      return '교통';
    }
    if (text.contains('shop') || text.contains('쇼핑')) {
      return '쇼핑';
    }
    return '식비';
  }

  static String topCategory(List<ReceiptRecord> records) {
    if (records.isEmpty) {
      return '기록 없음';
    }
    final counts = <String, int>{};
    for (final record in records) {
      final categoryLabel = category(record);
      counts[categoryLabel] = (counts[categoryLabel] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static String amountWithSymbol(String currency, double amount) {
    return '${symbol(currency)}${amount.toStringAsFixed(2)}';
  }

  static double totalWithTip(ReceiptRecord record) {
    return record.krwAmount + record.tipKrw;
  }

  static String locationLabel(ReceiptRecord record) {
    final location = [record.city, record.country]
        .where((value) => value.trim().isNotEmpty)
        .join(' · ');
    return location.isEmpty ? '위치 미상' : location;
  }

  static String flag(String countryCode) {
    if (countryCode.length != 2) {
      return '🌍';
    }
    final upper = countryCode.toUpperCase();
    final first = upper.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = upper.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([first, second]);
  }

  static String symbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'KRW':
        return '₩';
      default:
        return '';
    }
  }

  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    final time = DateFormat('HH:mm').format(date);
    if (diff == 0) {
      return '오늘, $time';
    }
    if (diff == 1) {
      return '어제, $time';
    }
    return DateFormat('M월 d일, HH:mm', 'ko').format(date);
  }

  static double budgetGoal(List<ReceiptRecord> records) {
    final total = totalSpend(records);
    if (total <= 0) {
      return 0;
    }
    return (total * 1.4).clamp(500000, 10000000);
  }

  static String sectionLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) {
      return '오늘';
    }
    if (diff == 1) {
      return '어제';
    }
    return '이전';
  }

  static String shortDate(DateTime date) {
    return DateFormat('M월 d일 · HH:mm', 'ko').format(date);
  }

  static String monthLabel(DateTime date) {
    return DateFormat('yyyy년 M월', 'ko').format(date);
  }
}
