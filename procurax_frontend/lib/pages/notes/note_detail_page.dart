import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:procurax_frontend/models/note_model.dart';
import 'package:procurax_frontend/theme/app_theme.dart';

/// Read-only detail view for a single [Note].
///
/// Displays the tag chip, title, metadata (created / edited dates),
/// and the note body. If the note has an attachment, a tappable card
/// shows the filename and opens the Cloudinary URL in an external browser
/// via [url_launcher].
///
/// Tapping the edit icon in the AppBar pops with the string `'edit'`
/// so [NotesPage] can immediately push [EditNotePage].
class NoteDetailPage extends StatelessWidget {
  /// The note to display — passed in directly from the list.
  final Note note;

  const NoteDetailPage({super.key, required this.note});

  /// Returns the accent colour for the tag badge based on the tag text.
  /// Falls back to [AppColors.primary] for unknown tag values.
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

  /// Returns the icon to display inside the tag badge.
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

            // ── Attachment ──────────────────────────────────────────
            // Only shown when the note has an attachment.
            // If a URL exists (uploaded to Cloudinary) we render a
            // tappable card that opens the file in the device's default
            // external browser / document viewer.
            // If hasAttachment is true but the URL is empty (legacy notes
            // migrated before the attachment URL field was added) we fall
            // back to a plain "Has attachment" row so nothing crashes.
            if (note.hasAttachment) ...[
              AppSpacing.verticalSm,
              if (note.attachmentUrl.isNotEmpty)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    // Parse the Cloudinary URL and open it externally.
                    final uri = Uri.parse(note.attachmentUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.insert_drive_file_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            note.attachmentName.isNotEmpty
                                ? note.attachmentName
                                : 'Attachment',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.open_in_new_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                )
              else
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
