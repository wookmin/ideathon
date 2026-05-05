import 'package:flutter/material.dart';

import '../config/theme.dart';

class ReceiptItemTile extends StatelessWidget {
  const ReceiptItemTile({
    super.key,
    required this.name,
    required this.paid,
    required this.avg,
    required this.status,
  });

  final String name;
  final String paid;
  final String avg;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'warn' => AppTheme.warn,
      'bad' => AppTheme.bad,
      _ => AppTheme.ok,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.bodyLarge),
                if (avg.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '평균가 $avg',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(paid, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
