import 'package:flutter/material.dart';
import '../models/meeting.dart';
import '../../../theme.dart';

class MeetingListItem extends StatelessWidget {
  final Meeting meeting;

  const MeetingListItem(this.meeting, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.people_outline, color: primaryBlue),
      title: Text(
        meeting.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        meeting.location.isNotEmpty
            ? '${meeting.timeLabel} • ${meeting.location}'
            : meeting.timeLabel,
        style: const TextStyle(color: greyText, fontSize: 12),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
