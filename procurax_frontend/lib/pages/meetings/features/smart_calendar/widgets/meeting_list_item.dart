import 'package:flutter/material.dart';
import '../models/meeting.dart';
import '../../../theme.dart';

class MeetingListItem extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleDone;

  const MeetingListItem(
    this.meeting, {
    super.key,
    this.onEdit,
    this.onDelete,
    this.onToggleDone,
  });

  DateTime _normalizeDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  ({String label, Color color}) _statusTag() {
    final today = _normalizeDay(DateTime.now());
    final meetingDay = _normalizeDay(meeting.date);

    if (meetingDay.isAtSameMomentAs(today)) {
      return (label: 'Today', color: const Color(0xFF16A34A));
    }

    if (meetingDay.isBefore(today)) {
      return (label: 'Past', color: const Color(0xFF6B7280));
    }

    return (label: 'Upcoming', color: const Color(0xFF2563EB));
  }

  ({String label, Color color}) _priorityTag() {
    switch (meeting.priority.toLowerCase()) {
      case 'high':
        return (label: 'High', color: const Color(0xFFDC2626));
      case 'low':
        return (label: 'Low', color: const Color(0xFF0EA5E9));
      default:
        return (label: 'Medium', color: const Color(0xFFF59E0B));
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = meeting.location.isNotEmpty
        ? '${meeting.timeLabel} • ${meeting.location}'
        : meeting.timeLabel;
    final status = _statusTag();
    final priority = _priorityTag();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.groups_2_outlined, color: primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        meeting.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          decoration: meeting.done
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    Checkbox(
                      value: meeting.done,
                      onChanged: (value) {
                        if (value != null) {
                          onToggleDone?.call(value);
                        }
                      },
                      activeColor: primaryBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildChip(status.label, status.color),
                    _buildChip(priority.label, priority.color),
                    _buildChip(meeting.timeLabel, primaryBlue),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: greyText, fontSize: 12),
                ),
                if (meeting.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    meeting.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: greyText),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_note_outlined, color: primaryBlue),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
