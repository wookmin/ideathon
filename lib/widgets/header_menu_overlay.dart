import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../config/theme.dart';

class AppTopHeader extends StatelessWidget {
  const AppTopHeader({
    super.key,
    required this.travelTitle,
    required this.period,
    required this.status,
    required this.onMenuTap,
    this.onNotificationTap,
    this.onBackTap,
  });

  static const double menuDimTopOffset = 94;

  final String travelTitle;
  final String period;
  final String status;
  final VoidCallback onMenuTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onBackTap;

  @override
  Widget build(BuildContext context) {
    final hasBackButton = onBackTap != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(hasBackButton ? 4 : 26, 14, 26, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasBackButton) ...[
                IconButton(
                  onPressed: onBackTap,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: const Color(0xFFC2C7D1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              SvgPicture.asset(
                'assets/design/icons/headerLogo.svg',
                height: 18,
                semanticsLabel: '멈칫',
              ),
              const Spacer(),
              if (onNotificationTap != null) ...[
                HeaderNotificationButton(onTap: onNotificationTap!),
                const SizedBox(width: 8),
              ],
              HeaderMenuToggleButton(onTap: onMenuTap),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.only(left: hasBackButton ? 22 : 0),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    travelTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    period,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF7C879B),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _HeaderStatusChip(status: status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStatusChip extends StatelessWidget {
  const _HeaderStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppTheme.primary),
      ),
    );
  }
}

class HeaderNotificationButton extends StatelessWidget {
  const HeaderNotificationButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(
          Icons.notifications_none_rounded,
          size: 28,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}

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
