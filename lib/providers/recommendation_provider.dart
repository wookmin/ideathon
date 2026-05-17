import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/recommend_category.dart';
import '../models/recommend_place.dart';
import '../services/google_places_service.dart';

class RecommendationProvider extends ChangeNotifier {
  final GooglePlacesService _placesService =
      GooglePlacesService();

  GoogleMapController? mapController;

  bool isLoading = true;

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

      notifyListeners();

      await _getCurrentLocation();

      await fetchRecommendations();
    } catch (e) {
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
      }
    } catch (e) {
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
}

/// Riverpod Provider
final recommendationProvider =
    ChangeNotifierProvider<
      RecommendationProvider
    >(
  (ref) => RecommendationProvider(),
);