import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class DoctorCalendarScreen extends StatelessWidget {
  final DateTime selectedDay;
  final DateTime focusedDay;
  final CalendarFormat calendarFormat;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final Function(CalendarFormat) onFormatChanged;

  const DoctorCalendarScreen({
    Key? key,
    required this.selectedDay,
    required this.focusedDay,
    required this.calendarFormat,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onFormatChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      locale: 'tr_TR',
      startingDayOfWeek: StartingDayOfWeek.monday,
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: focusedDay,
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,
      calendarFormat: calendarFormat,
      onFormatChanged: onFormatChanged,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Ay',
        CalendarFormat.week: 'Hafta',
        CalendarFormat.twoWeeks: '2 Hafta',
      },
      calendarStyle: const CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Color.fromARGB(255, 238, 182, 97),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Color.fromARGB(255, 70, 179, 230),
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        selectedTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
        formatButtonDecoration: BoxDecoration(
          color: Color.fromARGB(255, 70, 179, 230),
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
        ),
        formatButtonTextStyle: TextStyle(
          color: Colors.white,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
