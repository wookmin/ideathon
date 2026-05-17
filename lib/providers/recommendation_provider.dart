import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/recommend_category.dart';
import '../models/recommend_place.dart';
import '../services/google_places_service.dart';
import 'exchange_provider.dart';

class RecommendationProvider extends ChangeNotifier {
  RecommendationProvider(this._placesService);

  final GooglePlacesService _placesService;

  GoogleMapController? mapController;

  bool isLoading = true;
  String? errorMessage;

  LatLng? currentPosition;

  RecommendCategory selectedCategory =
      RecommendCategory.categories.first;

  List<RecommendPlace> places = [];

  RecommendPlace? selectedPlace;

  final Completer<GoogleMapController>
      mapCompleter = Completer();

  /// 초기 진입
  Future<void> initialize() async {
    try {
      isLoading = true;
      errorMessage = null;

      notifyListeners();

      await _getCurrentLocation();

      await fetchRecommendations();
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
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Location service disabled',
      );
    }

    permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw Exception(
        'Location permanently denied',
      );
    }

    final position =
        await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    currentPosition = LatLng(
      position.latitude,
      position.longitude,
    );
  }

  /// 추천 불러오기
  Future<void> fetchRecommendations() async {
    if (currentPosition == null) return;

    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      final result =
          await _placesService.fetchNearbyPlaces(
        latitude: currentPosition!.latitude,
        longitude: currentPosition!.longitude,
        category: selectedCategory,
      );

      places = result;

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
    RecommendCategory category,
  ) async {
    selectedCategory = category;

    selectedPlace = null;

    notifyListeners();

    await fetchRecommendations();
  }

  /// 핀 선택
  Future<void> selectPlace(
    RecommendPlace place,
  ) async {
    selectedPlace = place;

    notifyListeners();

    await moveCamera(place.position);
  }

  /// 카메라 이동
  Future<void> moveCamera(
    LatLng target,
  ) async {
    if (mapController == null) return;

    await mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: target,
          zoom: 16,
        ),
      ),
    );
  }

  /// 현재 위치 이동
  Future<void> moveToCurrentLocation() async {
    if (currentPosition == null) return;

    await moveCamera(currentPosition!);
  }

  /// 맵 생성
  void onMapCreated(
    GoogleMapController controller,
  ) {
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
final recommendationProvider =
    ChangeNotifierProvider<RecommendationProvider>(
  (ref) => RecommendationProvider(
    GooglePlacesService(ref.watch(dioProvider)),
  ),
);
