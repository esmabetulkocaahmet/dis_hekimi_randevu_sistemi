import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RandevuSaatSecimi extends StatefulWidget {
  final int doctorId;
  final String selectedDate;

  const RandevuSaatSecimi({required this.doctorId, required this.selectedDate, Key? key}) : super(key: key);

  @override
  State<RandevuSaatSecimi> createState() => _RandevuSaatSecimiState();
}

class _RandevuSaatSecimiState extends State<RandevuSaatSecimi> {
  List<String> availableSlots = [];
  List<String> doluSaatler = [];
  bool isLoading = true;
  String? error;
  String? selectedSlot;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      error = null;
      selectedSlot = null;
    });

    try {
      // Doktor ayarlarını al
      final settingsUrl = Uri.parse('http://192.168.1.2:5000/api/doctor/settings/${widget.doctorId}');
      final settingsResp = await http.get(settingsUrl);
      if (settingsResp.statusCode != 200) throw Exception("Doktor ayarları alınamadı");
      final settingsData = json.decode(settingsResp.body);

      final int startHour = settingsData['start_hour'];
      final int startMinute = settingsData['start_minute'];
      final int endHour = settingsData['end_hour'];
      final int endMinute = settingsData['end_minute'];
      final int interval = settingsData['interval_minutes'];

      // Kapalı saatler
      final closedUrl = Uri.parse('http://192.168.1.2:5000/api/doctor/closed_slots/${widget.doctorId}?date=${widget.selectedDate}');
      final closedResp = await http.get(closedUrl);
      if (closedResp.statusCode != 200) throw Exception("Kapalı saatler alınamadı");
      final closedSlots = List<String>.from(json.decode(closedResp.body));

      // Randevusu alınmış saatler
      final bookedUrl = Uri.parse('http://192.168.1.2:5000/api/doctor/booked_slots/${widget.doctorId}?date=${widget.selectedDate}');
      final bookedResp = await http.get(bookedUrl);
      if (bookedResp.statusCode != 200) throw Exception("Alınan randevular alınamadı");
      final bookedSlots = List<String>.from(json.decode(bookedResp.body));

      List<String> allSlots = generateTimeSlots(startHour, startMinute, endHour, endMinute, interval);

      setState(() {
        availableSlots = allSlots;
        doluSaatler = [...closedSlots, ...bookedSlots].toSet().toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  List<String> generateTimeSlots(int sh, int sm, int eh, int em, int interval) {
    List<String> slots = [];
    DateFormat fmt = DateFormat("HH:mm");
    DateTime start = DateTime(0, 1, 1, sh, sm);
    DateTime end = DateTime(0, 1, 1, eh, em);

    while (start.isBefore(end) || start.isAtSameMomentAs(end)) {
      slots.add(fmt.format(start));
      start = start.add(Duration(minutes: interval));
    }

    return slots;
  }

  void onSelectSlot(String slot) {
    if (doluSaatler.contains(slot)) return;
    setState(() {
      selectedSlot = slot;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Randevu Saati Seçimi"),
        backgroundColor: const Color.fromARGB(255, 70, 179, 230),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text("Hata: $error"))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.blue.shade50,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                         "Tarih: ${DateFormat('dd.MM.yyyy').format(DateTime.parse(widget.selectedDate))}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5081DB),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Text(
                        "Uygun Saatler",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 2.5,
                            ),
                            itemCount: availableSlots.length,
                            itemBuilder: (context, index) {
                              final saat = availableSlots[index];
                              final isDisabled = doluSaatler.contains(saat);
                              final isSelected = selectedSlot == saat;

                              Color bgColor;
                              Color textColor;

                              if (isDisabled) {
                                bgColor = Colors.grey.shade300;
                                textColor = Colors.grey;
                              } else if (isSelected) {
                                bgColor = const Color(0xFF5081DB);
                                textColor = Colors.white;
                              } else {
                                bgColor = Colors.white;
                                textColor = Colors.black;
                              }

                              return GestureDetector(
                                onTap: () => onSelectSlot(saat),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    saat,
                                    style: TextStyle(fontSize: 16, color: textColor),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (selectedSlot != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text("Seçilen Saat: $selectedSlot", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context, selectedSlot);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                side: const BorderSide(color: Colors.black),
                              ),
                              child: const Text("Devam Et"),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
}
