import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/app_colors.dart';
import '../models/recommend_category.dart';

class MapUtils {
  /// 거리 계산 (m)
  static double calculateDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    const double earthRadius = 6371000;

    final dLat = _toRadians(endLat - startLat);
    final dLng = _toRadians(endLng - startLng);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
            cos(_toRadians(startLat)) *
                cos(_toRadians(endLat)) *
                sin(dLng / 2) *
                sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// 거리 문자열 변환
  static String formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toInt()}m';
    }

    return '${(distance / 1000).toStringAsFixed(1)}km';
  }

  /// 도보 시간 계산
  static String estimateWalkTime(double distance) {
    // 평균 도보속도 4.5km/h
    final minutes = (distance / 75).ceil();

    return '도보 ${minutes}분';
  }

  /// 카테고리 색상
  static Color getCategoryColor(
    RecommendCategoryType type,
  ) {
    switch (type) {
      case RecommendCategoryType.restaurant:
        return AppColors.restaurant;

      case RecommendCategoryType.cafe:
        return AppColors.cafe;

      case RecommendCategoryType.shopping:
        return AppColors.shopping;

      case RecommendCategoryType.attraction:
        return AppColors.attraction;
    }
  }

  /// 카테고리 이모지
  static String getCategoryEmoji(
    RecommendCategoryType type,
  ) {
    switch (type) {
      case RecommendCategoryType.restaurant:
        return '🍜';

      case RecommendCategoryType.cafe:
        return '☕';

      case RecommendCategoryType.shopping:
        return '🛍️';

      case RecommendCategoryType.attraction:
        return '🎡';
    }
  }

  /// 카메라 위치
  static CameraPosition initialCamera(
    LatLng position,
  ) {
    return CameraPosition(
      target: position,
      zoom: 15,
    );
  }
}