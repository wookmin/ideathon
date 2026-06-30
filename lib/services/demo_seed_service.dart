import 'package:hive_flutter/hive_flutter.dart';

import '../models/receipt_record.dart';
import '../models/travel.dart';
import '../providers/ledger_provider.dart';
import '../providers/travel_provider.dart';
import '../providers/travel_selection_provider.dart';

class DemoSeedService {
  const DemoSeedService._();

  static const travelId = 'demo_japan_week_trip';
  static const _country = '일본';
  static const _countryCode = '';
  static const _currency = 'JPY';
  static const _jpyPerKrw = 0.11;

  static Future<void> seedJapanTrip() async {
    final travelBox = Hive.box<Travel>(travelBoxName);
    final ledgerBox = Hive.box<ReceiptRecord>(ledgerBoxName);
    final selectionBox = Hive.box<String>(travelSelectionBoxName);

    final today = _dateOnly(DateTime.now());
    final startDate = today.subtract(const Duration(days: 2));
    final endDate = startDate.add(const Duration(days: 6));
    const budgetKrw = 1500000.0;

    await travelBox.put(
      travelId,
      Travel(
        id: travelId,
        title: '일본 미식 여행',
        country: _country,
        startDate: startDate,
        endDate: endDate,
        budgetKrw: budgetKrw,
        exchangeSourceAmount: budgetKrw,
        exchangeSourceCurrency: 'KRW',
        exchangeTargetAmount: budgetKrw * _jpyPerKrw,
        exchangeTargetCurrency: _currency,
        createdAt: today.subtract(const Duration(days: 10)),
      ),
    );

    for (final record in _records(startDate)) {
      await ledgerBox.put(record.id, record);
    }

    await selectionBox.put(selectedTravelIdKey, travelId);
  }

  static List<ReceiptRecord> _records(DateTime startDate) {
    return [
      _record(
        id: 'demo_japan_day1_suica',
        date: startDate.add(const Duration(hours: 10, minutes: 20)),
        city: '도쿄',
        memo: '나리타 공항 스이카 충전',
        originalAmount: 5000,
        items: [
          ReceiptItem(
            name: 'Suica 충전',
            paid: '¥5,000',
            avg: '교통비',
            status: '적정',
          ),
        ],
        verdict: '공항에서 시내 이동과 첫날 지하철 이동을 위해 미리 충전했어요.',
      ),
      _record(
        id: 'demo_japan_day1_ramen',
        date: startDate.add(const Duration(hours: 13, minutes: 35)),
        city: '우에노',
        memo: '이치란 라멘 점심',
        originalAmount: 1680,
        items: [
          ReceiptItem(name: '라멘', paid: '¥1,180', avg: '¥1,100', status: '보통'),
          ReceiptItem(
            name: '계란 추가',
            paid: '¥250',
            avg: '¥200',
            status: '살짝 높음',
          ),
          ReceiptItem(name: '말차 음료', paid: '¥250', avg: '¥300', status: '좋음'),
        ],
        verdict: '관광지 근처 점심으로는 무난한 지출이에요.',
      ),
      _record(
        id: 'demo_japan_day1_donki',
        date: startDate.add(const Duration(hours: 20, minutes: 15)),
        city: '아키하바라',
        memo: '돈키호테 간식 쇼핑',
        originalAmount: 8420,
        items: [
          ReceiptItem(name: '과자/젤리', paid: '¥3,200', avg: '쇼핑', status: '보통'),
          ReceiptItem(name: '기념품', paid: '¥4,100', avg: '쇼핑', status: '주의'),
          ReceiptItem(name: '음료', paid: '¥1,120', avg: '편의점', status: '보통'),
        ],
        verdict: '첫날 쇼핑 지출이 조금 커서 다음날 소비 속도를 확인하면 좋아요.',
      ),
      _record(
        id: 'demo_japan_day2_tsukiji',
        date: startDate.add(const Duration(days: 1, hours: 9, minutes: 40)),
        city: '츠키지',
        memo: '츠키지 시장 아침 식사',
        originalAmount: 3600,
        items: [
          ReceiptItem(
            name: '카이센동',
            paid: '¥2,800',
            avg: '¥2,500',
            status: '보통',
          ),
          ReceiptItem(name: '계란말이', paid: '¥500', avg: '¥500', status: '좋음'),
          ReceiptItem(name: '녹차', paid: '¥300', avg: '¥300', status: '좋음'),
        ],
        verdict: '시장 식사치고는 적당한 편이에요.',
      ),
      _record(
        id: 'demo_japan_day2_ginza',
        date: startDate.add(const Duration(days: 1, hours: 15, minutes: 5)),
        city: '긴자',
        memo: '긴자 문구점 쇼핑',
        originalAmount: 12600,
        items: [
          ReceiptItem(name: '문구류', paid: '¥6,800', avg: '쇼핑', status: '주의'),
          ReceiptItem(name: '선물용 소품', paid: '¥5,800', avg: '쇼핑', status: '주의'),
        ],
        verdict: '하루 예산의 10%를 넘는 쇼핑이라 알림을 띄우기 좋은 예시예요.',
      ),
      _record(
        id: 'demo_japan_day2_izakaya',
        date: startDate.add(const Duration(days: 1, hours: 21, minutes: 10)),
        city: '신주쿠',
        memo: '이자카야 저녁',
        originalAmount: 9200,
        items: [
          ReceiptItem(
            name: '꼬치 세트',
            paid: '¥3,800',
            avg: '¥3,500',
            status: '보통',
          ),
          ReceiptItem(
            name: '오코노미야키',
            paid: '¥2,100',
            avg: '¥1,800',
            status: '보통',
          ),
          ReceiptItem(name: '음료', paid: '¥3,300', avg: '¥2,500', status: '주의'),
        ],
        verdict: '저녁 지출이 높은 편이라 다음날 점심은 가볍게 가도 좋아요.',
      ),
      _record(
        id: 'demo_japan_day3_cafe',
        date: startDate.add(const Duration(days: 2, hours: 10, minutes: 30)),
        city: '시부야',
        memo: '시부야 카페 브런치',
        originalAmount: 2400,
        items: [
          ReceiptItem(
            name: '샌드위치',
            paid: '¥1,300',
            avg: '¥1,200',
            status: '보통',
          ),
          ReceiptItem(name: '라떼', paid: '¥700', avg: '¥650', status: '보통'),
          ReceiptItem(name: '디저트', paid: '¥400', avg: '¥500', status: '좋음'),
        ],
        verdict: '3일차 오전 지출은 안정적이에요.',
      ),
      _record(
        id: 'demo_japan_day3_shibuya_shop',
        date: startDate.add(const Duration(days: 2, hours: 16, minutes: 45)),
        city: '시부야',
        memo: '시부야 의류 쇼핑',
        originalAmount: 18800,
        items: [
          ReceiptItem(name: '셔츠', paid: '¥8,900', avg: '쇼핑', status: '주의'),
          ReceiptItem(name: '가방', paid: '¥9,900', avg: '쇼핑', status: '높음'),
        ],
        verdict: '오늘 하루 예산에서 큰 결제라 소비 알림 시연에 쓰기 좋아요.',
      ),
    ];
  }

  static ReceiptRecord _record({
    required String id,
    required DateTime date,
    required String city,
    required String memo,
    required double originalAmount,
    required List<ReceiptItem> items,
    required String verdict,
  }) {
    final krwAmount = originalAmount / _jpyPerKrw;
    return ReceiptRecord(
      id: id,
      date: date,
      country: _country,
      countryCode: _countryCode,
      city: city,
      currency: _currency,
      originalAmount: originalAmount,
      krwAmount: krwAmount,
      exchangeRate: _jpyPerKrw,
      rawOcrText: '$memo\n합계 ¥${originalAmount.toStringAsFixed(0)}',
      items: items,
      verdict: verdict,
      tipPct: 0,
      tipKrw: 0,
      memo: memo,
      imagePath: null,
      analysis: verdict,
    );
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
