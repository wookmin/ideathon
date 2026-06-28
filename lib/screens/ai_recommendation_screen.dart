import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_colors.dart';
import '../providers/ledger_provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/travel_selection_provider.dart';
import '../services/budget_forecast_service.dart';
import '../services/demo_location_trigger_source.dart';
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
      ref.read(recommendationProvider).initialize();
    });
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
    const triggerSource = DemoLocationTriggerSource();

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const MainBottomNav(currentIndex: 2),
      body: provider.currentPosition == null
          ? Stack(
              children: [
                _RecommendationStatusView(
                  isLoading: provider.isLoading,
                  message: provider.errorMessage,
                  onRetry: () {
                    ref.read(recommendationProvider).initialize();
                  },
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _DemoTriggerPanel(
                      triggers: triggerSource.triggers,
                      onTrigger: (trigger) => _showDemoAlert(
                        context,
                        triggerSource.candidateFor(
                          trigger: trigger,
                          forecast: forecast,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: RecommendationMapView(
                    currentPosition: provider.currentPosition!,
                    places: provider.places,
                    selectedPlace: provider.selectedPlace,
                    onMapCreated: provider.onMapCreated,
                    onPlaceTap: (place) {
                      provider.selectPlace(place);
                    },
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
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _DemoTriggerPanel(
                            triggers: triggerSource.triggers,
                            onTrigger: (trigger) => _showDemoAlert(
                              context,
                              triggerSource.candidateFor(
                                trigger: trigger,
                                forecast: forecast,
                              ),
                            ),
                          ),
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
                  const Positioned.fill(child: ShimmerMapLoading()),

                if (provider.errorMessage != null && !provider.isLoading)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: provider.selectedPlace != null ? 320 : 30,
                    child: _InlineErrorCard(
                      message: provider.errorMessage!,
                      onRetry: () {
                        ref.read(recommendationProvider).fetchRecommendations();
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  void _showDemoAlert(BuildContext context, AlertCandidate candidate) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DemoAlertSheet(candidate: candidate),
    );
  }
}

class _DemoTriggerPanel extends StatelessWidget {
  const _DemoTriggerPanel({required this.triggers, required this.onTrigger});

  final List<DemoLocationTrigger> triggers;
  final ValueChanged<DemoLocationTrigger> onTrigger;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_searching_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '결제 전 위치 알림 시연',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final trigger in triggers)
                  OutlinedButton(
                    onPressed: () => onTrigger(trigger),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Text(trigger.placeType),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoAlertSheet extends StatelessWidget {
  const _DemoAlertSheet({required this.candidate});

  final AlertCandidate candidate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _statusColor(
                      candidate.resultingStatus,
                    ).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.pause_circle_outline_rounded,
                    color: _statusColor(candidate.resultingStatus),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    candidate.placeName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              candidate.message,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(ForecastStatus status) {
    return switch (status) {
      ForecastStatus.safe || ForecastStatus.noSpend => AppColors.success,
      ForecastStatus.caution => AppColors.warning,
      ForecastStatus.danger || ForecastStatus.depleted => AppColors.danger,
      ForecastStatus.noTravel => AppColors.primary,
    };
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
