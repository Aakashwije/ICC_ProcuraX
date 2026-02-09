import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../theme.dart';

class CalendarWidget extends StatelessWidget {
  final CalendarFormat calendarFormat;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Map<DateTime, int> meetingCounts;
  final Function(DateTime) onDaySelected;
  final void Function(DateTime) onPageChanged;

  const CalendarWidget({
    super.key,
    required this.calendarFormat,
    required this.focusedDay,
    required this.selectedDay,
    this.meetingCounts = const {},
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2020),
      lastDay: DateTime.utc(2030),
      focusedDay: focusedDay,
      calendarFormat: calendarFormat,
      selectedDayPredicate: (day) => isSameDay(day, selectedDay),
      eventLoader: (day) {
        final key = DateTime(day.year, day.month, day.day);
        final count = meetingCounts[key] ?? 0;
        return List.filled(count, 'event');
      },
      onDaySelected: (selected, focused) {
        onDaySelected(selected);
      },

      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
        CalendarFormat.twoWeeks: 'Week',
        CalendarFormat.week: 'Day',
      },

      onPageChanged: onPageChanged,
      headerVisible: true,
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: lightBlue,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: primaryBlue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
