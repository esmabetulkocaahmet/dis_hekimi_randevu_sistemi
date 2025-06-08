import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; 
import 'doktor_calender_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  final int doktorId;
  final String doktorAdi;

  const DoctorHomeScreen({
    Key? key,
    required this.doktorId,
    required this.doktorAdi,
  }) : super(key: key);

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<dynamic> _appointments = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchAppointments(_selectedDay!);
  }

  String _formatDateReadable(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'tr_TR').format(date);
  }

  String _formatDate(DateTime date) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)}';
  }

  Future<void> _fetchAppointments(DateTime date) async {
    final formattedDate = _formatDate(date);
    final url = Uri.parse(
        'http://192.168.1.2:5000/appointments?doktor_id=${widget.doktorId}&tarih=$formattedDate');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _appointments = data;
        });
      } else {
        setState(() {
          _appointments = [];
        });
      }
    } catch (e) {
      setState(() {
        _appointments = [];
      });
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _fetchAppointments(selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        appBar: AppBar(
          elevation: 0,
          backgroundColor:  const Color.fromARGB(255, 70, 179, 230),
          automaticallyImplyLeading: false,
          title: Text(
            'Dr. ${widget.doktorAdi}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person, color: Colors.black),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/doctor_profile',
                  arguments: {'doktor_id': widget.doktorId},
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.black),
              onPressed: () {
                _showLogoutConfirmation(context);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            DoctorCalendarScreen(
              selectedDay: _selectedDay!,
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              onDaySelected: _onDaySelected,
              onPageChanged: (day) {
                setState(() {
                  _focusedDay = day;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    "Seçilen Gün: ${_formatDateReadable(_selectedDay!)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _appointments.isEmpty
                    ? const Center(
                        child: Text(
                          "Bu gün için randevu bulunamadı.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _appointments.length,
                        itemBuilder: (context, index) {
                          final item = _appointments[index];
                          final cinsiyet = (item['cinsiyet'] ?? 'erkek').toLowerCase();
                          final assetPath = cinsiyet == 'kadın'
                              ? 'assets/images/female_user.png'
                              : 'assets/images/male_user.png';
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 3,
                            color: Colors.lightBlue.shade50,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              leading: CircleAvatar(
                                backgroundColor: Colors.transparent,
                                backgroundImage: AssetImage(assetPath),
                              ),
                              title: Text(
                                '${item['hasta_adi']} ${item['hasta_soyadi']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text('Saat: ${item['saat']}'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/hasta_detay',
                                  arguments: {
                                    'hasta_id': item['hasta_id'],
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black, 
            ),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/User_Type_Selection',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black, 
              backgroundColor: Colors.white,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

}
