import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../theme.dart';
import '../../../../../../routes/app_routes.dart';
import '../../../../../../widgets/app_drawer.dart';

import '../models/meeting.dart';
import '../widgets/tab_selector.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/meeting_list_item.dart';
import 'package:procurax_frontend/pages/meetings/features/smart_calendar/screens/add_meeting_page.dart';

class MeetingsPage extends StatefulWidget {
  const MeetingsPage({super.key});

  @override
  State<MeetingsPage> createState() => _MeetingsPageState();
}

class _MeetingsPageState extends State<MeetingsPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

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
  Widget build(BuildContext context) {
    // Dummy meetings (UI only for now)
    final meetings = [
      Meeting(
        'Project Alpha Team Meeting',
        '10:00 AM - 11:00 AM',
        DateTime.now(),
      ),
      Meeting('Procurement Review', '10:00 AM - 11:00 AM', DateTime.now()),
      Meeting(
        'Team Sync',
        '10:00 AM - 11:00 AM',
        DateTime.now().add(const Duration(days: 1)),
      ),
    ];

    return Scaffold(
      drawer: const AppDrawer(currentRoute: AppRoutes.meetings),
      backgroundColor: Colors.white,

      // ➕ Add Meeting
      floatingActionButton: FloatingActionButton(
        backgroundColor: lightBlue,
        elevation: 0,
        child: const Icon(Icons.add, color: primaryBlue),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMeetingPage()),
          );
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
                child: ListView(
                  children: _filteredMeetings(
                    meetings,
                  ).map((m) => MeetingListItem(m)).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
