import 'package:flutter/material.dart';

import '../config/app_colors.dart';

class ShimmerMapLoading extends StatefulWidget {
  const ShimmerMapLoading({super.key});

  @override
  State<ShimmerMapLoading> createState() =>
      _ShimmerMapLoadingState();
}

class _ShimmerMapLoadingState
    extends State<ShimmerMapLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            color: Colors.white.withOpacity(0.18),
            child: Stack(
              children: [
                Positioned(
                  top: 140,
                  left: -120 +
                      (_controller.value * 500),
                  child: Transform.rotate(
                    angle: 0.4,
                    child: Container(
                      width: 180,
                      height: MediaQuery.of(
                        context,
                      ).size.height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withOpacity(
                              0.38,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors
                                  .primary
                                  .withOpacity(0.18),
                              blurRadius: 20,
                              offset:
                                  const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.6,
                              color:
                                  AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'AI 추천 장소를 불러오는 중...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color:
                              AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        '현재 위치와 소비 패턴을 분석하고 있어요',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}