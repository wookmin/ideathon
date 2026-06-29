import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/env.dart';
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

  RecommendPlace copyWith({String? aiReason}) {
    return RecommendPlace(
      id: id,
      name: name,
      category: category,
      position: position,
      rating: rating,
      reviewCount: reviewCount,
      priceLevel: priceLevel,
      distanceText: distanceText,
      walkTimeText: walkTimeText,
      aiReason: aiReason ?? this.aiReason,
      imageUrl: imageUrl,
      description: description,
    );
  }

  factory RecommendPlace.fromGooglePlace({
    required Map<String, dynamic> json,
    required RecommendCategoryType category,
    required String aiReason,
    required String imageUrl,
    required String distanceText,
    required String walkTimeText,
  }) {
    final geometry = json['geometry'] ?? {};
    final location = geometry['location'] ?? {};

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

  factory RecommendPlace.fromBackendPlace({
    required Map<String, dynamic> json,
    required RecommendCategoryType category,
    required String aiReason,
    required String distanceText,
    required String walkTimeText,
  }) {
    final photoUrl = json['photoUrl'];

    return RecommendPlace(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: category,
      position: LatLng(
        (json['lat'] ?? 0).toDouble(),
        (json['lng'] ?? 0).toDouble(),
      ),
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      priceLevel: _convertPriceLevel(json['priceLevel']),
      distanceText: distanceText,
      walkTimeText: walkTimeText,
      aiReason: aiReason,
      imageUrl: photoUrl != null
          ? '${Env.backendBaseUrl}$photoUrl'
          : 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=1200&auto=format&fit=crop',
      description: json['address'] ?? '',
    );
  }

  static String _convertPriceLevel(dynamic level) {
    if (level == null) return '가격이 적당함';

    switch (level) {
      case 1:
        return '가격이 저렴함';
      case 2:
        return '가격이 적당함';
      case 3:
        return '가격이 조금 나감';
      case 4:
        return '가격이 비쌈';
      default:
        return '가격이 적당함';
    }
  }
}
