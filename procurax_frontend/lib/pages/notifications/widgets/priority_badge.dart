import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../utils/constants.dart';

class PriorityBadge extends StatelessWidget {
  final AlertPriority priority;
  final bool showIcon;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.getColorForPriority(priority),
        borderRadius: AppRadius.radiusSM,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon)
            Icon(
              AppIcons.getIconForPriority(priority),
              color: Colors.white,
              size: 12,
            ),
          const SizedBox(width: 4),
          Text(
            priority.toString().split('.').last.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
