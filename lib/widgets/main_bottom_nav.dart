import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../screens/analysis_screen.dart';
import '../screens/home_screen.dart';

class MainBottomNav extends StatelessWidget {
  const MainBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 74,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF1F4FA))),
          boxShadow: [
            BoxShadow(
              color: Color(0x080F172A),
              blurRadius: 18,
              offset: Offset(0, -6),
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
      ),
    );
  }

  void _openTab(BuildContext context, int index) {
    if (index == currentIndex) {
      return;
    }

    if (index == 2) {
      return;
    }

    final route = switch (index) {
      0 => MaterialPageRoute(builder: (_) => const AnalysisScreen()),
      1 => MaterialPageRoute(builder: (_) => const HomeScreen()),
      _ => null,
    };
    if (route != null) {
      Navigator.of(context).pushAndRemoveUntil(route, (route) => route.isFirst);
    }
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
    final color = selected ? AppTheme.primary : const Color(0xFFC6D5FA);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: 86,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: selected ? 28 : 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
