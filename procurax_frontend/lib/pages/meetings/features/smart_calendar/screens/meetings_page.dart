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
import '../services/meeting_api_service.dart';

class MeetingsPage extends StatefulWidget {
  const MeetingsPage({super.key});

  @override
  State<MeetingsPage> createState() => _MeetingsPageState();
}

class _MeetingsPageState extends State<MeetingsPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  final MeetingApiService _api = MeetingApiService();
  List<Meeting> _allMeetings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    try {
      final meetings = await _api.getMeetings();
      setState(() {
        _allMeetings = meetings;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🔹 Filter meetings based on Day / Week / Month
  List<Meeting> _filteredMeetings() {
    return _allMeetings.where((meeting) {
      final meetingDate = meeting.startTime;

      // DAY
      if (_calendarFormat == CalendarFormat.week) {
        return isSameDay(meetingDate, _selectedDay);
      }

      // WEEK
      if (_calendarFormat == CalendarFormat.twoWeeks) {
        final weekStart = _focusedDay.subtract(
          Duration(days: _focusedDay.weekday - 1),
        );
        final weekEnd = weekStart.add(const Duration(days: 6));

        return meetingDate.isAfter(
              weekStart.subtract(const Duration(days: 1)),
            ) &&
            meetingDate.isBefore(weekEnd.add(const Duration(days: 1)));
      }

      // MONTH
      return meetingDate.month == _focusedDay.month &&
          meetingDate.year == _focusedDay.year;
    }).toList();
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
        child: const Icon(Icons.add, color: primaryBlue),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMeetingPage()),
          );
          _loadMeetings(); // 🔁 refresh after add
        },
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
                    : _filteredMeetings().isEmpty
                    ? const Center(
                        child: Text(
                          "No meetings found",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView(
                        children: _filteredMeetings()
                            .map((m) => MeetingListItem(m))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
