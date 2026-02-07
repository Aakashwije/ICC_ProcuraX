import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../theme.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../../../../widgets/app_drawer.dart';

import '../models/meeting.dart';
import '../widgets/tab_selector.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/meeting_list_item.dart';
import 'add_meeting_page.dart';
import 'edit_meeting_page.dart';
import '../../../../../../services/meetings_service.dart';

class MeetingsPage extends StatefulWidget {
  const MeetingsPage({super.key});

  @override
  State<MeetingsPage> createState() => _MeetingsPageState();
}

class _MeetingsPageState extends State<MeetingsPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<Meeting> _meetings = [];
  bool _loading = true;
  String? _errorMessage;

  // Filter meetings based on Day / Week / Month
  List<Meeting> _filteredMeetings(List<Meeting> allMeetings) {
    final filtered = allMeetings.where((meeting) {
      // Day view
      if (_calendarFormat == CalendarFormat.week) {
        return isSameDay(meeting.date, _selectedDay);
      }

      // Week view
      if (_calendarFormat == CalendarFormat.twoWeeks) {
        final weekStart = _focusedDay.subtract(
          Duration(days: _focusedDay.weekday - 1),
        );
        final weekEnd = weekStart.add(const Duration(days: 6));

        return meeting.date.isAfter(
              weekStart.subtract(const Duration(days: 1)),
            ) &&
            meeting.date.isBefore(weekEnd.add(const Duration(days: 1)));
      }

      // Month view
      return meeting.date.month == _focusedDay.month &&
          meeting.date.year == _focusedDay.year;
    }).toList();

    filtered.sort((a, b) {
      if (a.done != b.done) {
        return a.done ? 1 : -1;
      }
      return a.date.compareTo(b.date);
    });

    return filtered;
  }

  DateTime _normalizeDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Map<DateTime, int> _meetingCountsByDay(List<Meeting> meetings) {
    final Map<DateTime, int> counts = {};
    for (final meeting in meetings) {
      final dayKey = _normalizeDay(meeting.date);
      counts[dayKey] = (counts[dayKey] ?? 0) + 1;
    }
    return counts;
  }

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final meetings = await MeetingsService.fetchMeetings();
      if (!mounted) return;
      setState(() => _meetings = meetings);
    } catch (err) {
      if (!mounted) return;
      setState(() => _errorMessage = err.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _openAddMeeting() async {
    final created = await Navigator.push<Meeting>(
      context,
      MaterialPageRoute(builder: (_) => const AddMeetingPage()),
    );

    if (!mounted) return;

    if (created != null) {
      await _loadMeetings();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _editMeeting(Meeting meeting) async {
    final updated = await Navigator.push<Meeting>(
      context,
      MaterialPageRoute(builder: (_) => EditMeetingPage(meeting: meeting)),
    );

    if (!mounted || updated == null) return;

    try {
      await MeetingsService.updateMeeting(updated);
      if (!mounted) return;
      await _loadMeetings();
      _showSuccess('Meeting updated');
    } catch (err) {
      if (!mounted) return;
      _showError(err.toString());
    }
  }

  Future<void> _deleteMeeting(Meeting meeting) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.red),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Delete meeting',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this meeting? This action cannot be undone.',
          style: TextStyle(color: greyText, height: 1.4),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: greyText,
              side: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    try {
      await MeetingsService.deleteMeeting(meeting.id);
      if (!mounted) return;
      await _loadMeetings();
      _showSuccess('Meeting deleted');
    } catch (err) {
      if (!mounted) return;
      _showError(err.toString());
    }
  }

  Future<void> _toggleMeetingDone(Meeting meeting, bool done) async {
    final updated = Meeting(
      id: meeting.id,
      title: meeting.title,
      description: meeting.description,
      date: meeting.date,
      startTime: meeting.startTime,
      endTime: meeting.endTime,
      location: meeting.location,
      priority: meeting.priority,
      done: done,
    );

    setState(() {
      final index = _meetings.indexWhere((m) => m.id == meeting.id);
      if (index != -1) {
        _meetings[index] = updated;
      }
    });

    try {
      await MeetingsService.updateMeeting(updated);
      if (!mounted) return;
      await _loadMeetings();
      _showSuccess(done ? 'Meeting marked done' : 'Meeting reopened');
    } catch (err) {
      if (!mounted) return;
      _showError(err.toString());
      await _loadMeetings();
    }
  }

  Widget _buildSummaryCard(int totalMeetings) {
    final selectedLabel =
        '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.event_available, color: primaryBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upcoming meetings',
                  style: TextStyle(color: greyText, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalMeetings scheduled',
                  style: const TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Selected: $selectedLabel',
                  style: TextStyle(color: greyText, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _openAddMeeting,
            style: TextButton.styleFrom(
              foregroundColor: primaryBlue,
              backgroundColor: lightBlue,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: lightBlue,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.event_busy, color: primaryBlue, size: 32),
            ),
            const SizedBox(height: 12),
            const Text(
              'No meetings yet',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Create your first meeting to get started.',
              style: TextStyle(color: greyText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openAddMeeting,
              icon: const Icon(Icons.add),
              label: const Text('Add meeting'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meetings = _meetings;
    final filteredMeetings = _filteredMeetings(meetings);
    final meetingCounts = _meetingCountsByDay(meetings);

    Widget listContent;
    if (_loading) {
      listContent = const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    } else if (_errorMessage != null) {
      listContent = Center(
        key: const ValueKey('error'),
        child: Text(_errorMessage!),
      );
    } else if (filteredMeetings.isEmpty) {
      listContent = KeyedSubtree(
        key: const ValueKey('empty'),
        child: _buildEmptyState(),
      );
    } else {
      listContent = RefreshIndicator(
        key: const ValueKey('list'),
        onRefresh: _loadMeetings,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 12),
          children: filteredMeetings
              .map(
                (m) => MeetingListItem(
                  m,
                  onEdit: () => _editMeeting(m),
                  onDelete: () => _deleteMeeting(m),
                  onToggleDone: (done) => _toggleMeetingDone(m, done),
                ),
              )
              .toList(),
        ),
      );
    }

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.meetings),
      backgroundColor: const Color(0xFFF8FAFC),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      onPressed: () => Scaffold.of(context).openDrawer(),
                      icon: const Icon(
                        Icons.menu_rounded,
                        size: 30,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Meetings',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: primaryBlue,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 12),

              _buildSummaryCard(meetings.length),

              const SizedBox(height: 18),

              // 🔹 Day / Week / Month selector
              TabSelector(
                selectedFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
              ),

              const SizedBox(height: 12),

              // 🔹 Calendar
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: CalendarWidget(
                  calendarFormat: _calendarFormat,
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  meetingCounts: meetingCounts,
                  onPageChanged: (day) {
                    setState(() {
                      _focusedDay = day;
                    });
                  },
                  onDaySelected: (day) {
                    setState(() {
                      _selectedDay = day;
                    });
                  },
                ),
              ),

              const SizedBox(height: 18),

              _buildSectionHeader('Meetings', filteredMeetings.length),

              const SizedBox(height: 12),

              // 🔹 Meetings list (filtered)
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: listContent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
