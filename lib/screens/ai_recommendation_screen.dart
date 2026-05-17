import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../config/app_colors.dart';
import '../models/recommend_place.dart';
import '../providers/recommendation_provider.dart';
import '../widgets/category_chip_bar.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/recommendation_bottom_card.dart';
import '../widgets/shimmer_map_loading.dart';

class AIRecommendationScreen extends StatefulWidget {
  const AIRecommendationScreen({super.key});

  @override
  State<AIRecommendationScreen> createState() =>
      _AIRecommendationScreenState();
}

class _AIRecommendationScreenState
    extends State<AIRecommendationScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<RecommendationProvider>()
          .initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const MainBottomNav(currentIndex: 2),
      body: Consumer<RecommendationProvider>(
        builder: (context, provider, child) {
          if (provider.currentPosition == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Stack(
            children: [
              /// MAP
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: provider.currentPosition!,
                  zoom: 15,
                ),
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: provider.onMapCreated,
                markers: _buildMarkers(provider),
              ),

              /// TOP BLUR
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 18,
                      sigmaY: 18,
                    ),
                    child: Container(
                      height: 145,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ),
              ),

              /// CATEGORY
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.only(top: 14),
                  child: Column(
                    children: [
                      CategoryChipBar(
                        selectedCategory:
                            provider.selectedCategory,
                        onSelected: (category) {
                          provider.changeCategory(
                            category,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              /// CURRENT LOCATION BUTTON
              Positioned(
                right: 20,
                bottom:
                    provider.selectedPlace != null
                        ? 290
                        : 30,
                child: GestureDetector(
                  onTap: () {
                    provider.moveToCurrentLocation();
                  },
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 250),
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),

              /// BOTTOM CARD
              if (provider.selectedPlace != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedSwitcher(
                    duration:
                        const Duration(milliseconds: 280),
                    child: RecommendationBottomCard(
                      key: ValueKey(
                        provider.selectedPlace!.id,
                      ),
                      place: provider.selectedPlace!,
                    ),
                  ),
                ),

              /// SHIMMER LOADING
              if (provider.isLoading)
                const Positioned.fill(
                  child: ShimmerMapLoading(),
                ),
            ],
          );
        },
      ),
    );
  }

  Set<Marker> _buildMarkers(
    RecommendationProvider provider,
  ) {
    final markers = <Marker>{};

    /// CURRENT LOCATION
    markers.add(
      Marker(
        markerId: const MarkerId('current'),
        position: provider.currentPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
      ),
    );

    /// RECOMMEND PLACE
    for (final place in provider.places) {
      markers.add(
        Marker(
          markerId: MarkerId(place.id),
          position: place.position,
          onTap: () {
            provider.selectPlace(place);
          },
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerHue(place),
          ),
        ),
      );
    }

    return markers;
  }

  double _getMarkerHue(
    RecommendPlace place,
  ) {
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
}
