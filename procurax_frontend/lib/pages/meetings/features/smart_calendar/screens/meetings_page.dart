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
import 'meeting_added_page.dart';
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
  final List<Meeting> _allMeetings = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMeetings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final meetings = await MeetingsService.getMeetings();
      if (!mounted) return;
      setState(() {
        _allMeetings
          ..clear()
          ..addAll(meetings);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Meeting> get _filteredMeetings {
    final meetings = _filterByCalendar(_allMeetings);
    if (_query.trim().isEmpty) return meetings;
    final q = _query.toLowerCase();
    return meetings.where((meeting) {
      return meeting.title.toLowerCase().contains(q) ||
          meeting.description.toLowerCase().contains(q) ||
          meeting.location.toLowerCase().contains(q);
    }).toList();
  }

  List<Meeting> _filterByCalendar(List<Meeting> meetings) {
    return meetings.where((meeting) {
      final date = meeting.startTime;

      if (_calendarFormat == CalendarFormat.week) {
        return isSameDay(date, _selectedDay);
      }

      if (_calendarFormat == CalendarFormat.twoWeeks) {
        final weekStart = _focusedDay.subtract(
          Duration(days: _focusedDay.weekday - 1),
        );
        final weekEnd = weekStart.add(const Duration(days: 6));

        return date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
            date.isBefore(weekEnd.add(const Duration(days: 1)));
      }

      return date.month == _focusedDay.month && date.year == _focusedDay.year;
    }).toList();
  }

  Map<DateTime, int> get _meetingCounts {
    final Map<DateTime, int> counts = {};
    for (final meeting in _allMeetings) {
      final key = DateTime(
        meeting.startTime.year,
        meeting.startTime.month,
        meeting.startTime.day,
      );
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _addMeeting() async {
    final action = await Navigator.push<MeetingAddedAction>(
      context,
      MaterialPageRoute(builder: (_) => const AddMeetingPage()),
    );

    if (!mounted) return;
    if (action != null) {
      await _loadMeetings();
    }

    if (action == MeetingAddedAction.addAnother) {
      await _addMeeting();
    }
  }

  Future<void> _editMeeting(Meeting meeting) async {
    final messenger = ScaffoldMessenger.of(context);
    final updated = await Navigator.push<Meeting>(
      context,
      MaterialPageRoute(builder: (_) => EditMeetingPage(meeting: meeting)),
    );

    if (!mounted || updated == null) return;

    try {
      await MeetingsService.updateMeeting(updated);
      if (!mounted) return;
      setState(() {
        _focusedDay = updated.startTime;
        _selectedDay = updated.startTime;
      });
      await _loadMeetings();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update meeting: $e')),
      );
    }
  }

  Future<void> _deleteMeeting(Meeting meeting) async {
    final messenger = ScaffoldMessenger.of(context);
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    try {
      await MeetingsService.deleteMeeting(meeting.id ?? '');
      if (!mounted) return;
      await _loadMeetings();
      messenger.showSnackBar(const SnackBar(content: Text('Meeting deleted')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete meeting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.meetings),
      backgroundColor: Colors.white,

      // ➕ Add Meeting
      floatingActionButton: FloatingActionButton(
        backgroundColor: lightBlue,
        elevation: 0,
        onPressed: _addMeeting,
        child: const Icon(Icons.add, color: primaryBlue),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 TOP BAR
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

              const SizedBox(height: 30),

              const SizedBox(height: 12),

              _searchBar(),

              const SizedBox(height: 16),

              TabSelector(
                selectedFormat: _calendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
              ),

              const SizedBox(height: 12),

              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: CalendarWidget(
                  calendarFormat: _calendarFormat,
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  meetingCounts: _meetingCounts,
                  onPageChanged: (day) {
                    setState(() {
                      _focusedDay = day;
                    });
                  },
                  onDaySelected: (day) {
                    setState(() {
                      _selectedDay = day;
                      _focusedDay = day;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Meetings',
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              // 🔹 Meetings list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : _filteredMeetings.isEmpty
                    ? const Center(
                        child: Text(
                          "No meetings found",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView(
                        children: _filteredMeetings
                            .map(
                              (m) => MeetingListItem(
                                meeting: m,
                                onEdit: () => _editMeeting(m),
                                onDelete: () => _deleteMeeting(m),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_outlined, color: greyText),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: "Search meetings",
                border: InputBorder.none,
              ),
            ),
          ),
          if (_query.trim().isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              icon: const Icon(Icons.close_rounded, color: greyText),
            ),
        ],
      ),
    );
  }
}
