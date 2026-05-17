import 'package:flutter/material.dart';

import '../config/theme.dart';

class HeaderMenuToggleButton extends StatelessWidget {
  const HeaderMenuToggleButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.menu_rounded, size: 32, color: AppTheme.primary),
      ),
    );
  }
}

class HeaderMenuOverlay extends StatelessWidget {
  const HeaderMenuOverlay({
    super.key,
    required this.isOpen,
    required this.dimTopOffset,
    required this.onDismiss,
    required this.onTravelTap,
    required this.onSettingsTap,
  });

  final bool isOpen;
  final double dimTopOffset;
  final VoidCallback onDismiss;
  final VoidCallback onTravelTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    if (!isOpen) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            top: dimTopOffset,
            child: GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.42)),
            ),
          ),
          Positioned(
            top: 6,
            right: 0,
            child: Material(
              color: Colors.white,
              elevation: 16,
              child: SizedBox(
                width: 206,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MenuAction(label: '나의 여행 목록', onTap: onTravelTap),
                    const Divider(height: 1, color: Color(0xFFE7EAF2)),
                    _MenuAction(label: '환경 설정', onTap: onSettingsTap),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuAction extends StatelessWidget {
  const _MenuAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppTheme.primary),
        ),
      ),
    );
  }
}
