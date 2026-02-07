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
    required this.meetingCounts,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  DateTime _normalizeDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2020),
      lastDay: DateTime.utc(2030),
      focusedDay: focusedDay,
      calendarFormat: calendarFormat,
      selectedDayPredicate: (day) => isSameDay(day, selectedDay),
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
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          final key = _normalizeDay(day);
          final count = meetingCounts[key] ?? 0;
          if (count == 0) return const SizedBox.shrink();

          return Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: primaryBlue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
