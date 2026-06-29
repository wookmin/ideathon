import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/app_colors.dart';

class ShimmerMapLoading extends StatefulWidget {
  const ShimmerMapLoading({super.key});

  @override
  State<ShimmerMapLoading> createState() => _ShimmerMapLoadingState();
}

class _ShimmerMapLoadingState extends State<ShimmerMapLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          color: Colors.white.withValues(alpha: 0.62),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 0.85 + (_pulseController.value * 0.3);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/design/icons/Rectangle 100.svg',
                          width: 96,
                          height: 96,
                        ),
                        SvgPicture.asset(
                          'assets/design/icons/Union.svg',
                          width: 42,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  '추천 장소를 불러오는 중...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  '현재 위치와 소비 패턴을 분석하고 있어요',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
