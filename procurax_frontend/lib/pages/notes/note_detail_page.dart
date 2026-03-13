import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:procurax_frontend/models/note_model.dart';
import 'package:procurax_frontend/theme/app_theme.dart';

/// A full-screen detail view for a single Note.
class NoteDetailPage extends StatelessWidget {
  final Note note;

  const NoteDetailPage({super.key, required this.note});

  Color _tagColor() {
    switch (note.tag.toLowerCase()) {
      case 'issue':
        return AppColors.error;
      case 'update':
        return AppColors.info;
      case 'reminder':
        return AppColors.warning;
      case 'site visit':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  IconData _tagIcon() {
    switch (note.tag.toLowerCase()) {
      case 'issue':
        return Icons.warning_amber_rounded;
      case 'update':
        return Icons.update;
      case 'reminder':
        return Icons.alarm;
      case 'site visit':
        return Icons.location_on_outlined;
      default:
        return Icons.label_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagColor = _tagColor();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Note Details'),
        actions: [
          Tooltip(
            message: 'Edit note',
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
            // ── Tag chip ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.1),
                borderRadius: AppRadius.chipRadius,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_tagIcon(), size: 16, color: tagColor),
                  const SizedBox(width: 6),
                  Text(
                    note.tag,
                    style: AppTextStyles.labelSmall.copyWith(color: tagColor),
                  ),
                ],
              ),
            ),
            AppSpacing.verticalLg,

            // ── Title ──
            Semantics(
              header: true,
              child: Text(note.title, style: AppTextStyles.h1),
            ),
            AppSpacing.verticalSm,

            // ── Metadata ──
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.neutral500,
                ),
                const SizedBox(width: 6),
                Text(
                  'Created ${DateFormat('MMM dd, yyyy').format(note.createdAt)}',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: AppColors.neutral500,
                ),
                const SizedBox(width: 6),
                Text(
                  'Edited ${DateFormat('MMM dd, yyyy').format(note.lastEdited)}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),

            if (note.hasAttachment) ...[
              AppSpacing.verticalSm,
              Row(
                children: [
                  Icon(
                    Icons.attach_file,
                    size: 14,
                    color: AppColors.neutral500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Has attachment',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],

            AppSpacing.verticalLg,
            const Divider(),
            AppSpacing.verticalLg,

            // ── Content ──
            Text('Content', style: AppTextStyles.labelMedium),
            AppSpacing.verticalSm,
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 200),
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: AppRadius.cardRadius,
                border: Border.all(color: AppColors.divider),
              ),
              child: SelectableText(
                note.content.isNotEmpty ? note.content : 'No content',
                style: AppTextStyles.bodyMedium.copyWith(height: 1.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
