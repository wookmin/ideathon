import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/recommend_category.dart';
import '../models/recommend_place.dart';
import '../utils/map_utils.dart';

class GooglePlacesService {
  Future<List<RecommendPlace>> fetchNearbyPlaces({
    required double latitude,
    required double longitude,
    required RecommendCategory category,
  }) async {
    final uri = Uri.parse(
      '${Env.backendBaseUrl}/api/v1/places/nearby'
      '?lat=$latitude'
      '&lng=$longitude'
      '&type=${category.placeType}'
      '&keyword=${Uri.encodeComponent(category.keyword)}',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Backend Places API Error: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final List places = data['places'] ?? [];

    return places.map((placeJson) {
      final placeLat = (placeJson['lat'] ?? 0).toDouble();
      final placeLng = (placeJson['lng'] ?? 0).toDouble();

      final distance = MapUtils.calculateDistance(
        startLat: latitude,
        startLng: longitude,
        endLat: placeLat,
        endLng: placeLng,
      );

      return RecommendPlace.fromBackendPlace(
        json: placeJson,
        category: category.type,
        aiReason: _generateMockAiReason(category.type),
        distanceText: MapUtils.formatDistance(distance),
        walkTimeText: MapUtils.estimateWalkTime(distance),
      );
    }).toList();
  }

  String _generateMockAiReason(RecommendCategoryType type) {
    switch (type) {
      case RecommendCategoryType.restaurant:
        return '현재 남은 예산과 최근 식비 패턴을 고려했을 때 부담 없이 방문하기 좋은 음식점이에요. 가까운 거리와 평점도 함께 반영했어요.';
      case RecommendCategoryType.cafe:
        return '최근 이동 동선과 카페 이용 성향을 바탕으로 추천했어요. 짧게 쉬어가기 좋고 예산 부담이 낮은 장소예요.';
      case RecommendCategoryType.shopping:
        return '현재 여행 예산 사용률을 고려했을 때 무리 없이 둘러볼 수 있는 쇼핑 장소예요. 접근성과 리뷰도 함께 반영했어요.';
      case RecommendCategoryType.attraction:
        return '현재 위치에서 이동 부담이 적고 예산을 크게 쓰지 않아도 방문 가능한 명소예요. 여행 동선과 잘 맞아요.';
    }
  }
}