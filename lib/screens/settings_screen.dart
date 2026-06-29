import 'package:flutter/material.dart';

import '../config/theme.dart';
import 'card_sync_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('환경 설정'), backgroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          _SettingTile(
            icon: Icons.credit_card_rounded,
            title: '카드 연동',
            subtitle: '카드사 연결과 승인내역 동기화를 관리해요.',
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CardSyncScreen()));
            },
          ),
          const SizedBox(height: 12),
          const _SettingTile(
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
            subtitle: 'mumchit travel expense prototype v0.1.0',
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFD),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
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
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFB8C0CD),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
