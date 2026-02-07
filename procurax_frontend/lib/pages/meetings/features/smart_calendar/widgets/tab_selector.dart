import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../theme.dart';

class TabSelector extends StatelessWidget {
  final CalendarFormat selectedFormat;
  final ValueChanged<CalendarFormat> onFormatChanged;

  const TabSelector({
    super.key,
    required this.selectedFormat,
    required this.onFormatChanged,
  });

  Widget _tab(String title, CalendarFormat format) {
    final bool isActive = selectedFormat == format;

    return GestureDetector(
      onTap: () => onFormatChanged(format),
      child: Text(
        title,
        style: TextStyle(
          color: isActive ? primaryBlue : Colors.grey,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _tab('Day', CalendarFormat.week),
        const SizedBox(width: 20),
        _tab('Week', CalendarFormat.twoWeeks),
        const SizedBox(width: 20),
        _tab('Month', CalendarFormat.month),
      ],
    );
  }
}
