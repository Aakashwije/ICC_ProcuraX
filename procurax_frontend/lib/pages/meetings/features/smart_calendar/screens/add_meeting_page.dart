import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../models/meeting.dart';
import '../../../../../../services/meetings_service.dart';

class AddMeetingPage extends StatefulWidget {
  const AddMeetingPage({super.key});

  @override
  State<AddMeetingPage> createState() => _AddMeetingPageState();
}

class _AddMeetingPageState extends State<AddMeetingPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    return time.format(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _saveMeeting() async {
    if (_titleController.text.trim().isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and date are required.')),
      );
      return;
    }

    setState(() => _saving = true);

    final meeting = Meeting(
      id: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _selectedDate!,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      location: _locationController.text.trim(),
    );

    try {
      final created = await MeetingsService.createMeeting(meeting);
      if (!mounted) return;
      Navigator.pop(context, created);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save meeting: $err')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    String hint = '',
    bool large = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: primaryBlue)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: large ? 4 : 1,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: lightBlue,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _pickerRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: primaryBlue)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value.isEmpty ? 'Select' : value,
              style: TextStyle(
                color: value.isEmpty ? Colors.grey : Colors.black87,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _selectedDate == null
        ? ''
        : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Add New Meeting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _input(
              'Meeting Title',
              _titleController,
              hint: 'Enter meeting title',
            ),
            _input(
              'Description (Optional)',
              _descriptionController,
              hint: 'Add meeting details...',
              large: true,
            ),
            _pickerRow(
              label: 'Select Date',
              value: dateLabel,
              onTap: _pickDate,
            ),
            Row(
              children: [
                Expanded(
                  child: _pickerRow(
                    label: 'Start Time',
                    value: _formatTime(_startTime),
                    onTap: _pickStartTime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _pickerRow(
                    label: 'End Time',
                    value: _formatTime(_endTime),
                    onTap: _pickEndTime,
                  ),
                ),
              ],
            ),
            _input(
              'Meeting Type or Location (Optional)',
              _locationController,
              hint: 'Enter location or meeting type',
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save Meeting'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saving ? null : _saveMeeting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
