import 'package:flutter/material.dart';

import '../config/theme.dart';

class ServiceChargeBanner extends StatelessWidget {
  const ServiceChargeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warn.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warn.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.warn),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '서비스 요금이 이미 포함되어 있습니다. 추가 팁은 선택 사항입니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.warn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
