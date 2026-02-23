import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../models/meeting.dart';

enum MeetingAddedAction { viewMeetings, addAnother }

class MeetingAddedPage extends StatelessWidget {
  final Meeting meeting;

  const MeetingAddedPage({super.key, required this.meeting});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 90, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'Meeting Added Successfully',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '"${meeting.title}" is now on your schedule.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, MeetingAddedAction.viewMeetings),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'View Meetings',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, MeetingAddedAction.addAnother),
                child: const Text('Add Another Meeting'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
