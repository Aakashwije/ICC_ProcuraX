import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../utils/constants.dart';

class AlertFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;
  final IconData? icon;

  const AlertFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isSelected ? Colors.white : color),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: color?.withOpacity(0.1),
        selectedColor: color ?? Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
        checkmarkColor: Colors.white,
      ),
    );
  }
}

class AlertTypeFilter extends StatelessWidget {
  final AlertType? selectedType;
  final Function(AlertType?) onTypeSelected;

  const AlertTypeFilter({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          AlertFilterChip(
            label: 'All',
            isSelected: selectedType == null,
            onTap: () => onTypeSelected(null),
          ),
          for (final type in AlertType.values)
            AlertFilterChip(
              label: type.toString().split('.').last.capitalize(),
              isSelected: selectedType == type,
              onTap: () => onTypeSelected(type),
            ),
        ],
      ),
    );
  }
}

class AlertPriorityFilter extends StatelessWidget {
  final AlertPriority? selectedPriority;
  final Function(AlertPriority?) onPrioritySelected;

  const AlertPriorityFilter({
    super.key,
    required this.selectedPriority,
    required this.onPrioritySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          AlertFilterChip(
            label: 'All Priorities',
            isSelected: selectedPriority == null,
            onTap: () => onPrioritySelected(null),
          ),
          for (final priority in AlertPriority.values)
            AlertFilterChip(
              label: priority.toString().split('.').last.capitalize(),
              isSelected: selectedPriority == priority,
              onTap: () => onPrioritySelected(priority),
            ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
