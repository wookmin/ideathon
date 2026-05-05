import 'package:flutter/material.dart';

import '../config/theme.dart';

class VerdictBadge extends StatelessWidget {
  const VerdictBadge({super.key, required this.verdict, this.label});

  final String verdict;
  final String? label;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final IconData icon;
    late final String text;

    switch (verdict) {
      case 'fair':
        color = AppTheme.ok;
        icon = Icons.check_circle_outline;
        text = label ?? '합리적';
      case 'pricey':
        color = AppTheme.warn;
        icon = Icons.warning_amber_rounded;
        text = label ?? '약간 비쌈';
      case 'rip':
        color = AppTheme.bad;
        icon = Icons.report_gmailerrorred;
        text = label ?? '바가지 의심';
      default:
        color = AppTheme.textSecondary;
        icon = Icons.help_outline;
        text = label ?? '분석 보류';
    }

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
