import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Backend adresini burada tanımla
const String baseUrl = "http://192.168.1.2:5000"; 

class DoctorSchedulePage extends StatefulWidget {
  final int doctorId;

  const DoctorSchedulePage({required this.doctorId, Key? key}) : super(key: key);

  @override
  State<DoctorSchedulePage> createState() => _DoctorSchedulePageState();
}

class _DoctorSchedulePageState extends State<DoctorSchedulePage> {
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  int intervalMinutes = 30;
  DateTime selectedDay = DateTime.now();
  List<TimeOfDay> closedSlots = [];

  @override
  void initState() {
    super.initState();
    _loadDoctorSettings();
    _loadClosedSlotsForSelectedDay();
  }

  Future<void> _loadDoctorSettings() async {
    final response = await http.get(Uri.parse("$baseUrl/api/doctor/settings/${widget.doctorId}"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        startTime = TimeOfDay(hour: data['start_hour'], minute: data['start_minute']);
        endTime = TimeOfDay(hour: data['end_hour'], minute: data['end_minute']);
        intervalMinutes = data['interval_minutes'];
      });
    }
  }

  Future<void> _loadClosedSlotsForSelectedDay() async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDay);
    final response = await http.get(Uri.parse("$baseUrl/api/doctor/closed_slots/${widget.doctorId}?date=$formattedDate"));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        closedSlots = data.map((e) {
          final parts = e.split(":");
          return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }).toList();
      });
    }
  }

  List<TimeOfDay> _generateSlots() {
    if (startTime == null || endTime == null) return [];
    final slots = <TimeOfDay>[];
    TimeOfDay current = startTime!;
    while (_compareTime(current, endTime!) < 0) {
      slots.add(current);
      current = _addMinutes(current, intervalMinutes);
    }
    return slots;
  }

  TimeOfDay _addMinutes(TimeOfDay time, int minutes) {
    final dt = DateTime(0, 0, 0, time.hour, time.minute).add(Duration(minutes: minutes));
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }

  int _compareTime(TimeOfDay a, TimeOfDay b) {
    return a.hour * 60 + a.minute - (b.hour * 60 + b.minute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }

  bool _isSlotClosed(TimeOfDay slot) {
    return closedSlots.any((s) => s.hour == slot.hour && s.minute == slot.minute);
  }

  Future<void> _saveSettings() async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/doctor/settings"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'doctor_id': widget.doctorId,
        'start_hour': startTime?.hour,
        'start_minute': startTime?.minute,
        'end_hour': endTime?.hour,
        'end_minute': endTime?.minute,
        'interval_minutes': intervalMinutes,
      }),
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ayarlar kaydedildi")),
      );
    }
  }

  Future<void> _toggleSlotClosure(TimeOfDay slot) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDay);
    final slotStr = _formatTimeOfDay(slot);
    final isClosed = _isSlotClosed(slot);

    final response = await http.post(
      Uri.parse("$baseUrl/api/doctor/closed_slot"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'doctor_id': widget.doctorId,
        'date': formattedDate,
        'time': slotStr,
        'closed': !isClosed,
      }),
    );

    if (response.statusCode == 200) {
      _loadClosedSlotsForSelectedDay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = _generateSlots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dişçi Randevu Ayarları"),
        backgroundColor: const Color.fromARGB(255, 70, 179, 230),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
        leading: const Icon(Icons.medical_services),
      ),
      body: Container(
        color: Colors.grey.shade100,
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.schedule, color: const Color.fromARGB(255, 121, 172, 209),),
                    title: Text("Başlangıç Saati: ${startTime?.format(context) ?? 'Seçilmedi'}"),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: startTime ?? TimeOfDay.now());
                      if (picked != null) setState(() => startTime = picked);
                    },
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.schedule_outlined, color: const Color.fromARGB(255, 121, 172, 209),),
                    title: Text("Bitiş Saati: ${endTime?.format(context) ?? 'Seçilmedi'}"),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: endTime ?? TimeOfDay.now());
                      if (picked != null) setState(() => endTime = picked);
                    },
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.timer, color: const Color.fromARGB(255, 121, 172, 209),),
                    title: const Text("Randevu Aralığı (dakika):"),
                    trailing: DropdownButton<int>(
                      value: intervalMinutes,
                      items: [15, 30, 45, 60]
                          .map((e) => DropdownMenuItem(value: e, child: Text("$e dakika")))
                          .toList(),
                      onChanged: (val) => setState(() => intervalMinutes = val!),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text("Ayarları Kaydet"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 70, 179, 230),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: selectedDay,
                  selectedDayPredicate: (day) => isSameDay(day, selectedDay),
                  onDaySelected: (selected, focused) {
                    setState(() => selectedDay = selected);
                    _loadClosedSlotsForSelectedDay();
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color:  const Color.fromARGB(255, 121, 172, 209),
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color:  Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Randevu Slotları", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...slots.map((slot) {
              final isClosed = _isSlotClosed(slot);
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading: const Icon(Icons.access_time, color: const Color.fromARGB(255, 121, 172, 209),),
                  title: Text(slot.format(context)),
                  trailing: Switch(
                    value: !isClosed,
                    activeColor: const Color.fromARGB(255, 121, 172, 209),
                    onChanged: (_) => _toggleSlotClosure(slot),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}