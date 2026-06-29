import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_colors.dart';
import '../models/receipt_record.dart';
import '../providers/ledger_provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/travel_selection_provider.dart';
import '../services/budget_forecast_service.dart';
import '../widgets/category_chip_bar.dart';
import '../widgets/main_bottom_nav.dart';
import '../widgets/recommendation_map_view.dart';
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
      ref
          .read(recommendationProvider)
          .initialize(forecast: _forecast(), records: _scopedRecords());
    });
  }

  List<ReceiptRecord> _scopedRecords() {
    final records = ref.read(ledgerProvider);
    final selectedTravel = ref.read(effectiveTravelProvider);
    return scopedRecordsForTravel(records, selectedTravel);
  }

  BudgetForecast _forecast() {
    final selectedTravel = ref.read(effectiveTravelProvider);
    final records = _scopedRecords();
    return const BudgetForecastService().calculate(
      travel: selectedTravel,
      records: records,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(recommendationProvider);
    final records = ref.watch(ledgerProvider);
    final selectedTravel = ref.watch(effectiveTravelProvider);
    final scopedRecords = scopedRecordsForTravel(records, selectedTravel);
    final forecast = const BudgetForecastService().calculate(
      travel: selectedTravel,
      records: scopedRecords,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const MainBottomNav(currentIndex: 2),
      body: provider.currentPosition == null
          ? _RecommendationStatusView(
              isLoading: provider.isLoading,
              message: provider.errorMessage,
              onRetry: () {
                ref
                    .read(recommendationProvider)
                    .initialize(forecast: forecast, records: scopedRecords);
              },
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                const bottomCardHeight = 220.0;
                const bottomCardGap = 14.0;
                final hasSelectedPlace = provider.selectedPlace != null;
                final cardTop =
                    constraints.maxHeight - bottomCardHeight - bottomCardGap;
                final currentLocationBottom = hasSelectedPlace
                    ? bottomCardHeight + 28
                    : 22.0;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: RecommendationMapView(
                        currentPosition: provider.currentPosition!,
                        places: provider.places,
                        selectedPlace: provider.selectedPlace,
                        onMapCreated: provider.onMapCreated,
                        onPlaceTap: provider.selectPlace,
                      ),
                    ),

                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.black.withValues(alpha: 0.04),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SafeArea(
                      bottom: false,
                      child: SizedBox(
                        height: 54,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.chevron_left_rounded),
                            iconSize: 34,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: MediaQuery.of(context).padding.top + 52,
                      left: 0,
                      right: 0,
                      child: CategoryChipBar(
                        selectedCategory: provider.selectedCategory,
                        onSelected: (category) {
                          provider.changeCategory(
                            category,
                            forecast: forecast,
                            records: scopedRecords,
                          );
                        },
                      ),
                    ),

                    Positioned(
                      right: 22,
                      bottom: currentLocationBottom,
                      child: GestureDetector(
                        onTap: provider.moveToCurrentLocation,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                      ),
                    ),

                    if (hasSelectedPlace)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: cardTop,
                        height: bottomCardHeight + bottomCardGap,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          child: RecommendationBottomCard(
                            key: ValueKey(provider.selectedPlace!.id),
                            place: provider.selectedPlace!,
                            onClose: provider.clearSelectedPlace,
                          ),
                        ),
                      ),

                    if (provider.isLoading)
                      const Positioned.fill(child: ShimmerMapLoading()),

                    if (provider.errorMessage != null && !provider.isLoading)
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: hasSelectedPlace ? bottomCardHeight + 44 : 30,
                        child: _InlineErrorCard(
                          message: provider.errorMessage!,
                          onRetry: () {
                            ref
                                .read(recommendationProvider)
                                .fetchRecommendations(
                                  forecast: forecast,
                                  records: scopedRecords,
                                );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
    );
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
      return const Center(child: CircularProgressIndicator());
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
            ElevatedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({required this.message, required this.onRetry});

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
            const Icon(Icons.info_outline_rounded, color: AppColors.primary),
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
            TextButton(onPressed: onRetry, child: const Text('재시도')),
          ],
        ),
      ),
    );
  }
}
