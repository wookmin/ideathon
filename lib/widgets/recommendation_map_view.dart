import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/recommend_place.dart';
import 'recommendation_map_view_impl.dart'
    if (dart.library.html) 'recommendation_map_view_web.dart'
    as impl;

class RecommendationMapView extends StatelessWidget {
  const RecommendationMapView({
    super.key,
    required this.currentPosition,
    required this.places,
    required this.selectedPlace,
    required this.onMapCreated,
    required this.onPlaceTap,
  });

  final LatLng currentPosition;
  final List<RecommendPlace> places;
  final RecommendPlace? selectedPlace;
  final ValueChanged<GoogleMapController> onMapCreated;
  final ValueChanged<RecommendPlace> onPlaceTap;

  @override
  Widget build(BuildContext context) {
    return impl.buildRecommendationMapView(
      context: context,
      currentPosition: currentPosition,
      places: places,
      selectedPlace: selectedPlace,
      onMapCreated: onMapCreated,
      onPlaceTap: onPlaceTap,
    );
  }
}
