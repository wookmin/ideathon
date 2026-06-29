import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../screens/ai_recommendation_screen.dart';
import '../screens/analysis_screen.dart';
import '../screens/home_screen.dart';

class MainBottomNav extends StatelessWidget {
  const MainBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      height: 64 + bottomInset,
      padding: EdgeInsets.fromLTRB(28, 6, 28, bottomInset + 5),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF4F7FC))),
        boxShadow: [
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.bar_chart_rounded,
            label: '분석',
            selected: currentIndex == 0,
            onTap: () => _openTab(context, 0),
          ),
          _NavItem(
            icon: Icons.home_rounded,
            label: '홈',
            selected: currentIndex == 1,
            onTap: () => _openTab(context, 1),
          ),
          _NavItem(
            icon: Icons.auto_awesome_rounded,
            label: '추천',
            selected: currentIndex == 2,
            onTap: () => _openTab(context, 2),
          ),
        ],
      ),
    );
  }

  void _openTab(BuildContext context, int index) {
    if (index == currentIndex) {
      return;
    }

    final route = switch (index) {
      0 => MaterialPageRoute(builder: (_) => const AnalysisScreen()),
      1 => MaterialPageRoute(builder: (_) => const HomeScreen()),
      _ => MaterialPageRoute(builder: (_) => const AIRecommendationScreen()),
    };
    Navigator.of(context).pushAndRemoveUntil(route, (route) => route.isFirst);
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? AppTheme.primary : const Color(0xFFD3DDF5);
    final labelColor = selected ? AppTheme.primary : const Color(0xFFBFD0F4);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: selected ? 25 : 23),
            const SizedBox(height: 3),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: labelColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
