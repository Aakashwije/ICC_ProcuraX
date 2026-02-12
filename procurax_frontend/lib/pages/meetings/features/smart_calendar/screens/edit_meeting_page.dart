import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme.dart';
import '../models/meeting.dart';
import '../services/meeting_api_service.dart';

class EditMeetingPage extends StatefulWidget {
  final Meeting meeting;

  const EditMeetingPage({super.key, required this.meeting});

  @override
  State<EditMeetingPage> createState() => _EditMeetingPageState();
}

class _EditMeetingPageState extends State<EditMeetingPage> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  late String _selectedPriority;
  late DateTime _startDateTime;
  late DateTime _endDateTime;
  late bool _done;

  bool _isLoading = false;

  final MeetingApiService _apiService = MeetingApiService();

  @override
  void initState() {
    super.initState();
    // Initialize with existing meeting data
    _titleController = TextEditingController(text: widget.meeting.title);
    _descriptionController = TextEditingController(
      text: widget.meeting.description,
    );
    _locationController = TextEditingController(text: widget.meeting.location);
    _selectedPriority = widget.meeting.priority;
    _startDateTime = widget.meeting.startTime;
    _endDateTime = widget.meeting.endTime;
    _done = widget.meeting.done;
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  Future<void> _updateMeeting() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }

    // Validate end time > start time
    if (_endDateTime.isBefore(_startDateTime) ||
        _endDateTime.isAtSameMomentAs(_startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final updatedMeeting = widget.meeting.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startTime: _startDateTime,
        endTime: _endDateTime,
        location: _locationController.text.trim(),
        priority: _selectedPriority,
        done: _done,
      );

      await _apiService.updateMeeting(widget.meeting.id!, updatedMeeting);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } on MeetingConflictException catch (e) {
      _showConflictDialog(e);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update meeting: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsDone() async {
    setState(() => _isLoading = true);

    try {
      await _apiService.markMeetingDone(widget.meeting.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meeting marked as done'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to mark as done: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showConflictDialog(MeetingConflictException e) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Time Conflict'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.message),
            const SizedBox(height: 16),
            if (e.suggestion != null) ...[
              const Text(
                'Suggested next available slot:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Start: ${_formatDateTime(e.suggestion!.suggestedStart)}'),
              Text('End: ${_formatDateTime(e.suggestion!.suggestedEnd)}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (e.suggestion != null)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _startDateTime = e.suggestion!.suggestedStart;
                  _endDateTime = e.suggestion!.suggestedEnd;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Use Suggested'),
            ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: isStart ? _startDateTime : _endDateTime,
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        isStart ? _startDateTime : _endDateTime,
      ),
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
      appBar: AppBar(
        title: const Text('Edit Meeting'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Mark as done button
          if (!_done)
            TextButton.icon(
              onPressed: _isLoading ? null : _markAsDone,
              icon: const Icon(Icons.check_circle, color: Colors.green),
              label: const Text(
                'Mark Done',
                style: TextStyle(color: Colors.green),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
                hintText: 'Enter meeting title',
              ),
            ),
            const SizedBox(height: 16),

            // Description field
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                hintText: 'Enter meeting description',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Location field
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(),
                hintText: 'Enter meeting location',
              ),
            ),
            const SizedBox(height: 16),

            // Priority dropdown
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('🔵 LOW')),
                DropdownMenuItem(value: 'medium', child: Text('🟡 MEDIUM')),
                DropdownMenuItem(value: 'high', child: Text('🔴 HIGH')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPriority = value);
                }
              },
            ),
            const SizedBox(height: 24),

            // Date/Time card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text(
                      'Start Date & Time',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      _formatDateTime(_startDateTime),
                      style: const TextStyle(color: Colors.black),
                    ),
                    trailing: const Icon(
                      Icons.calendar_month,
                      color: primaryBlue,
                    ),
                    onTap: () => _pickDateTime(true),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    title: const Text(
                      'End Date & Time',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      _formatDateTime(_endDateTime),
                      style: const TextStyle(color: Colors.black),
                    ),
                    trailing: const Icon(
                      Icons.calendar_month,
                      color: primaryBlue,
                    ),
                    onTap: () => _pickDateTime(false),
                  ),
                ],
              ),
            ),

            // Done status checkbox
            CheckboxListTile(
              title: const Text('Meeting Completed'),
              value: _done,
              onChanged: (value) {
                setState(() {
                  _done = value ?? false;
                });
              },
              activeColor: Colors.green,
              controlAffinity: ListTileControlAffinity.leading,
            ),

            const SizedBox(height: 32),

            // Update button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateMeeting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Update Meeting',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
