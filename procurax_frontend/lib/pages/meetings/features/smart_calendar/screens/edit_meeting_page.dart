import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../theme.dart';
import '../models/meeting.dart';
import 'location_picker_screen.dart';
import '../../../../../../widgets/custom_toast.dart';

class EditMeetingPage extends StatefulWidget {
  final Meeting meeting;

  const EditMeetingPage({super.key, required this.meeting});

  @override
  State<EditMeetingPage> createState() => _EditMeetingPageState();
}

class _EditMeetingPageState extends State<EditMeetingPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  DateTime? _startDateTime;
  DateTime? _endDateTime;

  bool _isSaving = false;

  // Location picked via LocationPickerScreen
  LocationPickerResult? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.meeting.title);
    _descriptionController = TextEditingController(
      text: widget.meeting.description,
    );
    _startDateTime = widget.meeting.startTime;
    _endDateTime = widget.meeting.endTime;
    // Pre-fill existing location if coordinates are present
    if (widget.meeting.hasCoordinates) {
      _selectedLocation = LocationPickerResult(
        address: widget.meeting.location,
        latitude: widget.meeting.latitude!,
        longitude: widget.meeting.longitude!,
      );
    } else if (widget.meeting.location.isNotEmpty) {
      // Address-only (legacy) — still show it as selected text
      _selectedLocation = null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  Future<void> _saveMeeting() async {
    if (_titleController.text.trim().isEmpty ||
        _startDateTime == null ||
        _endDateTime == null) {
      CustomToast.warning(
        context,
        'Please fill in all required fields including title, start time, and end time.',
        title: 'Missing Information',
      );
      return;
    }

    if (_startDateTime!.isAfter(_endDateTime!)) {
      CustomAlertDialog.showTimeValidationError(context);
      return;
    }

    setState(() => _isSaving = true);

    final updatedMeeting = Meeting(
      id: widget.meeting.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      startTime: _startDateTime!,
      endTime: _endDateTime!,
      location: _selectedLocation?.address ?? widget.meeting.location,
      latitude: _selectedLocation?.latitude ?? widget.meeting.latitude,
      longitude: _selectedLocation?.longitude ?? widget.meeting.longitude,
    );

    if (!mounted) return;
    Navigator.pop(context, updatedMeeting);
  }

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: isStart
          ? (_startDateTime ?? DateTime.now())
          : (_endDateTime ?? _startDateTime ?? DateTime.now()),
    );

    if (date == null) return;

    if (!mounted) return;

    final baseTime = isStart
        ? (_startDateTime ?? DateTime.now())
        : (_endDateTime ?? _startDateTime ?? DateTime.now());

    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      baseTime.hour,
      baseTime.minute,
    );

    setState(() {
      if (isStart) {
        _startDateTime = dateTime;
      } else {
        _endDateTime = dateTime;
      }
    });
  }

  Future<void> _pickTime(bool isStart) async {
    final baseDate = isStart
        ? (_startDateTime ?? DateTime.now())
        : (_endDateTime ?? _startDateTime ?? DateTime.now());

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(baseDate),
    );

    if (time == null) return;

    final dateTime = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Meeting',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        foregroundColor: primaryBlue,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _headerCard(
              title: 'Update meeting details',
              subtitle: 'Adjust schedule, location, and agenda notes.',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _field(
                    'Meeting title *',
                    _titleController,
                    icon: Icons.title_rounded,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    'Description',
                    _descriptionController,
                    icon: Icons.edit_note_outlined,
                    lines: 4,
                  ),
                  const SizedBox(height: 12),
                  _locationPickerTile(),
                  const SizedBox(height: 12),
                  _sectionLabel('Start'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _dateTile(
                          label: _startDateTime == null
                              ? 'Select date *'
                              : _formatDate(_startDateTime!),
                          icon: Icons.calendar_today,
                          onTap: () => _pickDate(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _timeTile(
                          label: _startDateTime == null
                              ? 'Select time *'
                              : _formatTime(_startDateTime!),
                          icon: Icons.schedule,
                          onTap: () => _pickTime(true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionLabel('End'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _dateTile(
                          label: _endDateTime == null
                              ? 'Select date *'
                              : _formatDate(_endDateTime!),
                          icon: Icons.calendar_today,
                          onTap: () => _pickDate(false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _timeTile(
                          label: _endDateTime == null
                              ? 'Select time *'
                              : _formatTime(_endDateTime!),
                          icon: Icons.schedule,
                          onTap: () => _pickTime(false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveMeeting,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Changes',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.meeting_room, color: primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Location picker ────────────────────────────────────────────────────────

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialAddress: _selectedLocation?.address ?? widget.meeting.location,
          initialLatitude:
              _selectedLocation?.latitude ?? widget.meeting.latitude,
          initialLongitude:
              _selectedLocation?.longitude ?? widget.meeting.longitude,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedLocation = result);
    }
  }

  Widget _locationPickerTile() {
    final hasLocation =
        _selectedLocation != null || widget.meeting.location.isNotEmpty;
    final displayAddress =
        _selectedLocation?.address ?? widget.meeting.location;
    return InkWell(
      onTap: _openLocationPicker,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasLocation
                ? const Color(0xFF4CAF50)
                : Colors.black.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: hasLocation ? const Color(0xFFE8F5E9) : lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasLocation
                    ? Icons.place_rounded
                    : Icons.add_location_alt_outlined,
                color: hasLocation ? const Color(0xFF4CAF50) : primaryBlue,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasLocation ? displayAddress : 'Add Location',
                    style: TextStyle(
                      fontSize: 13,
                      color: hasLocation ? Colors.black87 : Colors.black54,
                      fontWeight: hasLocation
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  if (_selectedLocation != null)
                    Text(
                      '${_selectedLocation!.latitude.toStringAsFixed(4)}, '
                      '${_selectedLocation!.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black38,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              hasLocation
                  ? Icons.edit_location_alt_outlined
                  : Icons.chevron_right_rounded,
              color: hasLocation ? primaryBlue : greyText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── Other helpers ──────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black54,
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    required IconData icon,
    int lines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryBlue),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primaryBlue, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: greyText),
          ],
        ),
      ),
    );
  }

  Widget _timeTile({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: primaryBlue, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: greyText),
          ],
        ),
      ),
    );
  }
}
