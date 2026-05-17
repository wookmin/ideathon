import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/app_colors.dart';
import '../models/recommend_place.dart';
import '../providers/recommendation_provider.dart';
import '../widgets/category_chip_bar.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/recommendation_bottom_card.dart';
import '../widgets/shimmer_map_loading.dart';

class AIRecommendationScreen extends ConsumerStatefulWidget {
  const AIRecommendationScreen({super.key});

  @override
  ConsumerState<AIRecommendationScreen> createState() =>
      _AIRecommendationScreenState();
}

class _AIRecommendationScreenState
    extends ConsumerState<AIRecommendationScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recommendationProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(recommendationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const MainBottomNav(currentIndex: 2),
      body: provider.currentPosition == null
          ? _RecommendationStatusView(
              isLoading: provider.isLoading,
              message: provider.errorMessage,
              onRetry: () {
                ref.read(recommendationProvider).initialize();
              },
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
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
                ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 145,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                ),

                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      children: [
                        CategoryChipBar(
                          selectedCategory: provider.selectedCategory,
                          onSelected: (category) {
                            provider.changeCategory(category);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  right: 20,
                  bottom: provider.selectedPlace != null ? 290 : 30,
                  child: GestureDetector(
                    onTap: () {
                      provider.moveToCurrentLocation();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
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

                if (provider.selectedPlace != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: RecommendationBottomCard(
                        key: ValueKey(provider.selectedPlace!.id),
                        place: provider.selectedPlace!,
                      ),
                    ),
                  ),

                if (provider.isLoading)
                  const Positioned.fill(
                    child: ShimmerMapLoading(),
                  ),

                if (provider.errorMessage != null &&
                    !provider.isLoading)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: provider.selectedPlace != null ? 320 : 30,
                    child: _InlineErrorCard(
                      message: provider.errorMessage!,
                      onRetry: () {
                        ref
                            .read(recommendationProvider)
                            .fetchRecommendations();
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  Set<Marker> _buildMarkers(
    RecommendationProvider provider,
  ) {
    final markers = <Marker>{};

    markers.add(
      Marker(
        markerId: const MarkerId('current'),
        position: provider.currentPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
      ),
    );

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

class _RecommendationStatusView extends StatelessWidget {
  const _RecommendationStatusView({
    required this.isLoading,
    required this.message,
    required this.onRetry,
  });

  final bool isLoading;
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_rounded,
              size: 54,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              message ?? '추천 장소를 불러오지 못했어요.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('재시도'),
            ),
          ],
        ),
      ),
    );
  }
}
