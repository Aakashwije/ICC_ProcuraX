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
    return allMeetings.where((meeting) {
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

  @override
  Widget build(BuildContext context) {
    final meetings = _meetings;

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.meetings),
      backgroundColor: Colors.white,

      // ➕ Add Meeting
      floatingActionButton: FloatingActionButton(
        backgroundColor: lightBlue,
        elevation: 0,
        child: const Icon(Icons.add, color: primaryBlue),
        onPressed: () async {
          final created = await Navigator.push<Meeting>(
            context,
            MaterialPageRoute(builder: (_) => const AddMeetingPage()),
          );

          if (!mounted) return;

          if (created != null) {
            await _loadMeetings();
          }
        },
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 TOP BAR (Drawer + Centered title)
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

              const SizedBox(height: 20),

              // 🔹 Meetings header
              const Text(
                'Meetings',
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              // 🔹 Meetings list (filtered)
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _filteredMeetings(meetings).isEmpty
                    ? const Center(child: Text('No meetings found'))
                    : RefreshIndicator(
                        onRefresh: _loadMeetings,
                        child: ListView(
                          children: _filteredMeetings(
                            meetings,
                          ).map((m) => MeetingListItem(m)).toList(),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
