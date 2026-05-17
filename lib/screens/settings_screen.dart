import 'package:flutter/material.dart';

import '../config/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('환경 설정'), backgroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: const [
          _SettingTile(
            icon: Icons.notifications_none_rounded,
            title: '알림 설정',
            subtitle: '새 지출 추가와 여행 리마인더 알림을 준비 중이에요.',
          ),
          SizedBox(height: 12),
          _SettingTile(
            icon: Icons.currency_exchange_rounded,
            title: '기본 통화 표시',
            subtitle: '현재는 KRW 기준으로 보여주며, 이후 통화 선택 기능이 추가될 예정이에요.',
          ),
          SizedBox(height: 12),
          _SettingTile(
            icon: Icons.info_outline_rounded,
            title: '앱 정보',
            subtitle: 'OneShot travel expense prototype v0.1.0',
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
