import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'recommend_category.dart';

class RecommendPlace {
  final String id;
  final String name;

  final RecommendCategoryType category;

  final LatLng position;

  final double rating;

  final int reviewCount;

  /// "₩₩", "₩₩₩"
  final String priceLevel;

  /// "420m"
  final String distanceText;

  /// "도보 6분"
  final String walkTimeText;

  /// AI 추천 이유
  final String aiReason;

  /// Google place image
  final String imageUrl;

  /// 상세 설명
  final String description;

  const RecommendPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.position,
    required this.rating,
    required this.reviewCount,
    required this.priceLevel,
    required this.distanceText,
    required this.walkTimeText,
    required this.aiReason,
    required this.imageUrl,
    required this.description,
  });

  factory RecommendPlace.fromGooglePlace({
    required Map<String, dynamic> json,
    required RecommendCategoryType category,
    required String aiReason,
    required String imageUrl,
    required String distanceText,
    required String walkTimeText,
  }) {
    final geometry = json['geometry'];
    final location = geometry['location'];

    return RecommendPlace(
      id: json['place_id'] ?? '',
      name: json['name'] ?? '',
      category: category,
      position: LatLng(
        (location['lat'] ?? 0).toDouble(),
        (location['lng'] ?? 0).toDouble(),
      ),
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['user_ratings_total'] ?? 0,
      priceLevel: _convertPriceLevel(json['price_level']),
      distanceText: distanceText,
      walkTimeText: walkTimeText,
      aiReason: aiReason,
      imageUrl: imageUrl,
      description: json['vicinity'] ?? '',
    );
  }

  static String _convertPriceLevel(dynamic level) {
    if (level == null) return '₩₩';

    switch (level) {
      case 1:
        return '₩';
      case 2:
        return '₩₩';
      case 3:
        return '₩₩₩';
      case 4:
        return '₩₩₩₩';
      default:
        return '₩₩';
    }
  }
}