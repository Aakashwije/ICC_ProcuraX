import 'package:flutter/material.dart';
import '../models/meeting.dart';
import '../../../theme.dart';

class MeetingListItem extends StatelessWidget {
  final Meeting meeting;

  const MeetingListItem(this.meeting, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meeting.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            meeting.timeRange,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Text(meeting.description, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
