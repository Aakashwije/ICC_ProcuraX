import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme.dart';
import '../models/meeting.dart';
import '../../../../../../services/meetings_service.dart';

class AddMeetingPage extends StatefulWidget {
  const AddMeetingPage({super.key});

  @override
  State<AddMeetingPage> createState() => _AddMeetingPageState();
}

class _AddMeetingPageState extends State<AddMeetingPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _startDateTime;
  DateTime? _endDateTime;

  bool _isLoading = false;

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  Future<void> _addMeeting() async {
    if (_titleController.text.trim().isEmpty ||
        _startDateTime == null ||
        _endDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final meeting = Meeting(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),

        startTime: _startDateTime!,
        endTime: _endDateTime!,
        location: _locationController.text.trim(),
      );

      await MeetingsService.addMeeting(meeting);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add meeting: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _startDateTime = dateTime;
      } else {
        _endDateTime = dateTime;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Meeting')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 16),

            ListTile(
              title: Text(
                _startDateTime == null
                    ? 'Select start date & time *'
                    : _formatDateTime(_startDateTime!),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDateTime(true),
            ),

            ListTile(
              title: Text(
                _endDateTime == null
                    ? 'Select end date & time *'
                    : _formatDateTime(_endDateTime!),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDateTime(false),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addMeeting,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Add Meeting'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
