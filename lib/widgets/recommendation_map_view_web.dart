import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/recommend_place.dart';

Widget buildRecommendationMapView({
  required BuildContext context,
  required LatLng currentPosition,
  required List<RecommendPlace> places,
  required RecommendPlace? selectedPlace,
  required ValueChanged<GoogleMapController> onMapCreated,
  required ValueChanged<RecommendPlace> onPlaceTap,
}) {
  final markers = <Marker>{
    Marker(
      markerId: const MarkerId('current'),
      position: currentPosition,
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      ),
    ),
    ...places.map(
      (place) => Marker(
        markerId: MarkerId(place.id),
        position: place.position,
        onTap: () => onPlaceTap(place),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getMarkerHue(place),
        ),
      ),
    ),
  };

  return GoogleMap(
    initialCameraPosition: CameraPosition(
      target: selectedPlace?.position ?? currentPosition,
      zoom: 15,
    ),
    myLocationEnabled: false,
    myLocationButtonEnabled: false,
    zoomControlsEnabled: false,
    compassEnabled: false,
    mapToolbarEnabled: false,
    onMapCreated: onMapCreated,
    markers: markers,
  );
}

double _getMarkerHue(RecommendPlace place) {
  switch (place.category.name) {
    case 'restaurant':
      return BitmapDescriptor.hueOrange;
    case 'cafe':
      return BitmapDescriptor.hueViolet;
    case 'shopping':
      return BitmapDescriptor.hueCyan;
    case 'attraction':
      return BitmapDescriptor.hueGreen;
    default:
      return BitmapDescriptor.hueAzure;
  }
}
