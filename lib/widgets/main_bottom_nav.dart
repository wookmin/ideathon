import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../screens/home_screen.dart';
import '../screens/ledger_screen.dart';
import '../screens/scan_screen.dart';

class MainBottomNav extends StatelessWidget {
  const MainBottomNav({
    super.key,
    required this.currentIndex,
  });

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      height: 78,
      backgroundColor: AppTheme.surface,
      indicatorColor: AppTheme.surfaceAlt,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (index) {
        if (index == currentIndex) {
          return;
        }
        final route = switch (index) {
          0 => MaterialPageRoute(builder: (_) => const HomeScreen()),
          1 => MaterialPageRoute(builder: (_) => const ScanScreen()),
          _ => MaterialPageRoute(builder: (_) => const LedgerScreen()),
        };
        Navigator.of(context).pushReplacement(route);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: '홈',
        ),
        NavigationDestination(
          icon: Icon(Icons.camera_alt_outlined),
          selectedIcon: Icon(Icons.camera_alt_rounded),
          label: '스캔',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: '기록',
        ),
      ],
    );
  }
}
