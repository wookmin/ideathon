import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/recommend_category.dart';
import '../models/recommend_place.dart';
import '../models/receipt_record.dart';
import '../services/budget_forecast_service.dart';
import '../services/google_places_service.dart';
import '../services/recommendation_ranker_service.dart';
import '../utils/location_service.dart' as loc;
import 'exchange_provider.dart';

class RecommendationProvider extends ChangeNotifier {
  RecommendationProvider(this._placesService, this._rankerService);

  static const _fallbackPosition = LatLng(37.5665, 126.9780);
  static const _locationTimeout = Duration(seconds: 8);
  static const _recommendationTimeout = Duration(seconds: 12);

  final GooglePlacesService _placesService;
  final RecommendationRankerService _rankerService;

  GoogleMapController? mapController;

  bool isLoading = true;
  String? errorMessage;

  LatLng? currentPosition;

  RecommendCategory selectedCategory = RecommendCategory.categories.first;

  List<RecommendPlace> places = [];

  RecommendPlace? selectedPlace;

  final Completer<GoogleMapController> mapCompleter = Completer();

  /// 초기 진입
  Future<void> initialize({
    BudgetForecast? forecast,
    List<ReceiptRecord> records = const [],
  }) async {
    try {
      isLoading = true;
      errorMessage = null;

      notifyListeners();

      await _getCurrentLocation();

      await fetchRecommendations(forecast: forecast, records: records);
    } catch (e) {
      errorMessage = _friendlyMessage(e);
      debugPrint(e.toString());
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }

  /// 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    try {
      final (lat, lng) = await loc.getCurrentLatLng().timeout(_locationTimeout);
      currentPosition = LatLng(lat, lng);
    } on TimeoutException {
      currentPosition = _fallbackPosition;
      errorMessage = '현재 위치 확인이 오래 걸려 서울 시청 기준으로 지도를 먼저 열었어요.';
    }
  }

  /// 추천 불러오기
  Future<void> fetchRecommendations({
    BudgetForecast? forecast,
    List<ReceiptRecord> records = const [],
  }) async {
    if (currentPosition == null) return;

    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      final result = await _placesService
          .fetchNearbyPlaces(
            latitude: currentPosition!.latitude,
            longitude: currentPosition!.longitude,
            category: selectedCategory,
          )
          .timeout(_recommendationTimeout);

      if (forecast != null) {
        places = _rankerService
            .rank(
              places: result,
              category: selectedCategory,
              forecast: forecast,
              records: records,
            )
            .map((ranked) => ranked.place.copyWith(aiReason: ranked.aiReason))
            .toList();
      } else {
        places = result;
      }

      if (places.isNotEmpty) {
        selectedPlace = places.first;
      } else {
        selectedPlace = null;
      }
    } catch (e) {
      errorMessage = _friendlyMessage(e);
      places = [];
      selectedPlace = null;
      debugPrint(e.toString());
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }

  /// 카테고리 변경
  Future<void> changeCategory(
    RecommendCategory category, {
    BudgetForecast? forecast,
    List<ReceiptRecord> records = const [],
  }) async {
    selectedCategory = category;

    selectedPlace = null;

    notifyListeners();

    await fetchRecommendations(forecast: forecast, records: records);
  }

  /// 핀 선택
  Future<void> selectPlace(RecommendPlace place) async {
    selectedPlace = place;

    notifyListeners();

    await moveCamera(place.position);
  }

  void clearSelectedPlace() {
    selectedPlace = null;
    notifyListeners();
  }

  /// 카메라 이동
  Future<void> moveCamera(LatLng target) async {
    if (mapController == null) return;

    await mapController!.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 16)),
    );
  }

  /// 현재 위치 이동
  Future<void> moveToCurrentLocation() async {
    if (currentPosition == null) return;

    await moveCamera(currentPosition!);
  }

  /// 맵 생성
  void onMapCreated(GoogleMapController controller) {
    mapController = controller;

    if (!mapCompleter.isCompleted) {
      mapCompleter.complete(controller);
    }
  }

  String _friendlyMessage(Object error) {
    final message = error.toString();

    if (message.contains('Location service disabled')) {
      return '위치 서비스가 꺼져 있어 추천 장소를 불러올 수 없어요.';
    }
    if (message.contains('Location permanently denied')) {
      return '위치 권한이 차단되어 있어요. 설정에서 권한을 다시 허용해 주세요.';
    }
    if (message.contains('denied')) {
      return '위치 권한이 필요해요. 권한을 허용한 뒤 다시 시도해 주세요.';
    }
    return '추천 장소를 불러오지 못했어요. 잠시 후 다시 시도해 주세요.';
  }
}

/// Riverpod Provider
final recommendationProvider = ChangeNotifierProvider<RecommendationProvider>(
  (ref) => RecommendationProvider(
    GooglePlacesService(ref.watch(dioProvider)),
    const RecommendationRankerService(),
  ),
);
