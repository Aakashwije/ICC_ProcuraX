import 'package:flutter/material.dart';
import '../../../theme.dart';
import '../models/meeting.dart';
import '../../../../../../services/meetings_service.dart';

class EditMeetingPage extends StatefulWidget {
  final Meeting meeting;

  const EditMeetingPage({super.key, required this.meeting});

  @override
  State<EditMeetingPage> createState() => _EditMeetingPageState();
}

class _EditMeetingPageState extends State<EditMeetingPage> {
  static const Map<String, Color> _priorityColors = {
    'high': Color(0xFFDC2626),
    'medium': Color(0xFFF59E0B),
    'low': Color(0xFF0EA5E9),
  };

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _priority = 'medium';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.meeting.title);
    _descriptionController = TextEditingController(
      text: widget.meeting.description,
    );
    _locationController = TextEditingController(text: widget.meeting.location);
    _selectedDate = widget.meeting.date;
    _startTime = _parseTime(widget.meeting.startTime);
    _endTime = _parseTime(widget.meeting.endTime);
    _priority = widget.meeting.priority;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTime(String value) {
    if (value.isEmpty) return null;
    final parts = value.split(' ');
    if (parts.isEmpty) return null;
    final timeParts = parts[0].split(':');
    if (timeParts.length < 2) return null;
    var hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts[1]) ?? 0;
    final period = parts.length > 1 ? parts[1].toLowerCase() : '';
    if (period == 'pm' && hour < 12) hour += 12;
    if (period == 'am' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
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

    final updated = Meeting(
      id: widget.meeting.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _selectedDate!,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      location: _locationController.text.trim(),
      priority: _priority,
      done: widget.meeting.done,
    );

    try {
      final saved = await MeetingsService.updateMeeting(updated);
      if (!mounted) return;
      Navigator.pop(context, saved);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update meeting: $err')));
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

  Widget _prioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Priority', style: TextStyle(color: primaryBlue)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _priorityColors.entries.map((entry) {
            final label = entry.key;
            final color = entry.value;
            final selected = _priority == label;
            return ChoiceChip(
              label: Text(
                label[0].toUpperCase() + label.substring(1),
                style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: selected,
              backgroundColor: color.withValues(alpha: 0.12),
              selectedColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (_) => setState(() => _priority = label),
            );
          }).toList(),
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
        title: const Text('Edit Meeting'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
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
                  _prioritySelector(),
                  _input(
                    'Meeting Type or Location (Optional)',
                    _locationController,
                    hint: 'Enter location or meeting type',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
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
                  label: Text(_saving ? 'Saving...' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _saving ? null : _saveMeeting,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
