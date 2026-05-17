import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/recommend_category.dart';
import '../models/recommend_place.dart';

class GooglePlacesService {
  static const String _apiKey = 'YOUR_GOOGLE_PLACES_API_KEY';

  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  Future<List<RecommendPlace>> fetchNearbyPlaces({
    required double latitude,
    required double longitude,
    required RecommendCategory category,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl'
      '?location=$latitude,$longitude'
      '&radius=2500'
      '&type=${category.placeType}'
      '&keyword=${category.keyword}'
      '&language=ko'
      '&key=$_apiKey',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Google Places API Error');
    }

    final data = jsonDecode(response.body);

    final List results = data['results'] ?? [];

    final sliced = results.take(5).toList();

    return sliced.map((placeJson) {
      final imageUrl = _buildPhotoUrl(placeJson);

      return RecommendPlace.fromGooglePlace(
        json: placeJson,
        category: category.type,
        imageUrl: imageUrl,
        aiReason: _generateMockAiReason(category.type),
        distanceText: _generateMockDistance(),
        walkTimeText: _generateMockWalkTime(),
      );
    }).toList();
  }

  String _buildPhotoUrl(Map<String, dynamic> placeJson) {
    final photos = placeJson['photos'];

    if (photos == null || photos.isEmpty) {
      return 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=1200&auto=format&fit=crop';
    }

    final photoReference = photos[0]['photo_reference'];

    return 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=1200'
        '&photo_reference=$photoReference'
        '&key=$_apiKey';
  }

  String _generateMockDistance() {
    final values = [
      '210m',
      '350m',
      '480m',
      '620m',
      '1.1km',
    ];

    values.shuffle();

    return values.first;
  }

  String _generateMockWalkTime() {
    final values = [
      '도보 3분',
      '도보 5분',
      '도보 7분',
      '도보 10분',
    ];

    values.shuffle();

    return values.first;
  }

  String _generateMockAiReason(RecommendCategoryType type) {
    switch (type) {
      case RecommendCategoryType.restaurant:
        return '최근 식비 소비 패턴과 현재 남은 예산을 고려했을 때 부담 없이 방문하기 좋은 음식점이에요. 현지 여행객 만족도도 높은 편입니다.';

      case RecommendCategoryType.cafe:
        return '사용자의 카페 방문 성향과 현재 이동 동선을 기반으로 추천했어요. 가볍게 쉬어가기 좋은 분위기의 장소입니다.';

      case RecommendCategoryType.shopping:
        return '현재 여행 소비 흐름 대비 적절한 쇼핑 장소예요. 관광객 만족도가 높고 접근성이 좋은 편입니다.';

      case RecommendCategoryType.attraction:
        return '현재 위치와 여행 패턴을 바탕으로 추천된 명소입니다. 예산 부담 없이 방문 가능한 인기 관광지예요.';
    }
  }
}