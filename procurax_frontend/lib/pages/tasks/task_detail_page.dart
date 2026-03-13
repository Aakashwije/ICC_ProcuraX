import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:procurax_frontend/models/task_model.dart';
import 'package:procurax_frontend/theme/app_theme.dart';

/// A full-screen detail view for a single Task.
class TaskDetailPage extends StatelessWidget {
  final Task task;

  const TaskDetailPage({super.key, required this.task});

  Color _priorityColor() {
    switch (task.priority) {
      case TaskPriority.critical:
        return AppColors.error;
      case TaskPriority.high:
        return const Color(0xFFF97316);
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.low:
        return AppColors.success;
    }
  }

  String _priorityLabel() {
    switch (task.priority) {
      case TaskPriority.critical:
        return 'Critical';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  Color _statusColor() {
    switch (task.status) {
      case TaskStatus.done:
        return AppColors.success;
      case TaskStatus.inProgress:
        return AppColors.primary;
      case TaskStatus.blocked:
        return AppColors.error;
      case TaskStatus.todo:
        return AppColors.neutral500;
    }
  }

  String _statusLabel() {
    switch (task.status) {
      case TaskStatus.done:
        return 'Done';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.blocked:
        return 'Blocked';
      case TaskStatus.todo:
        return 'To Do';
    }
  }

  IconData _statusIcon() {
    switch (task.status) {
      case TaskStatus.done:
        return Icons.check_circle;
      case TaskStatus.inProgress:
        return Icons.timelapse;
      case TaskStatus.blocked:
        return Icons.block;
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          Tooltip(
            message: 'Edit task',
            child: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.pop(context, 'edit'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status & Priority chips ──
            Row(
              children: [
                _buildChip(
                  icon: _statusIcon(),
                  label: _statusLabel(),
                  color: _statusColor(),
                ),
                AppSpacing.horizontalSm,
                _buildChip(
                  icon: Icons.flag,
                  label: _priorityLabel(),
                  color: _priorityColor(),
                ),
              ],
            ),
            AppSpacing.verticalLg,

            // ── Title ──
            Semantics(
              header: true,
              child: Text(task.title, style: AppTextStyles.h1),
            ),
            AppSpacing.verticalMd,

            // ── Description ──
            if (task.description.isNotEmpty) ...[
              Text('Description', style: AppTextStyles.labelMedium),
              AppSpacing.verticalSm,
              Container(
                width: double.infinity,
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.neutral50,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(task.description, style: AppTextStyles.bodyMedium),
              ),
              AppSpacing.verticalLg,
            ],

            // ── Info rows ──
            _buildInfoRow(
              icon: Icons.person_outline,
              label: 'Assignee',
              value: task.assignee.isNotEmpty ? task.assignee : 'Unassigned',
            ),
            if (task.dueDate != null)
              _buildInfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Due Date',
                value: DateFormat('MMM dd, yyyy').format(task.dueDate!),
                valueColor:
                    task.dueDate!.isBefore(DateTime.now()) &&
                        task.status != TaskStatus.done
                    ? AppColors.error
                    : null,
              ),
            AppSpacing.verticalLg,

            // ── Tags ──
            if (task.tags.isNotEmpty) ...[
              Text('Tags', style: AppTextStyles.labelMedium),
              AppSpacing.verticalSm,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: task.tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.chipRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.neutral500),
          const SizedBox(width: 12),
          Text('$label: ', style: AppTextStyles.labelMedium),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
