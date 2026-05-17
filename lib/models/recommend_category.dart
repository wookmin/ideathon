import 'package:flutter/material.dart';
import '../config/app_colors.dart';

enum RecommendCategoryType {
  restaurant,
  cafe,
  shopping,
  attraction,
}

class RecommendCategory {
  final RecommendCategoryType type;
  final String label;
  final IconData icon;
  final Color color;

  /// Google Places API type
  final String placeType;

  /// 검색 키워드
  final String keyword;

  const RecommendCategory({
    required this.type,
    required this.label,
    required this.icon,
    required this.color,
    required this.placeType,
    required this.keyword,
  });

  static const List<RecommendCategory> categories = [
    RecommendCategory(
      type: RecommendCategoryType.restaurant,
      label: '음식점',
      icon: Icons.restaurant_rounded,
      color: AppColors.restaurant,
      placeType: 'restaurant',
      keyword: 'local restaurant',
    ),
    RecommendCategory(
      type: RecommendCategoryType.cafe,
      label: '카페',
      icon: Icons.local_cafe_rounded,
      color: AppColors.cafe,
      placeType: 'cafe',
      keyword: 'cafe',
    ),
    RecommendCategory(
      type: RecommendCategoryType.shopping,
      label: '쇼핑',
      icon: Icons.shopping_bag_rounded,
      color: AppColors.shopping,
      placeType: 'shopping_mall',
      keyword: 'shopping',
    ),
    RecommendCategory(
      type: RecommendCategoryType.attraction,
      label: '명소',
      icon: Icons.attractions_rounded,
      color: AppColors.attraction,
      placeType: 'tourist_attraction',
      keyword: 'tourist attraction',
    ),
  ];

  static RecommendCategory fromType(RecommendCategoryType type) {
    return categories.firstWhere((e) => e.type == type);
  }
}