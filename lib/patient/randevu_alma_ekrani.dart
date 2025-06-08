import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:randevu_sistemi/services/db_service.dart';
import 'randevu_saat_secimi.dart';

class RandevuAlEkrani extends StatefulWidget {
  final int hastaId;

  const RandevuAlEkrani({Key? key, required this.hastaId}) : super(key: key);

  @override
  State<RandevuAlEkrani> createState() => _RandevuAlEkraniState();
}

class _RandevuAlEkraniState extends State<RandevuAlEkrani> {
  final DBService _dbService = DBService();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? selectedCity;
  String? selectedDistrict;
  Map<String, dynamic>? selectedDoctor;

  List<String> cities = [];
  List<String> districts = [];
  List<Map<String, dynamic>> doctors = [];

  @override
  void initState() {
    super.initState();
    _fetchCities();
  }

  Future<void> _fetchCities() async {
    final response = await http.get(Uri.parse("https://turkiyeapi.dev/api/v1/provinces"));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        cities = List<String>.from(data['data'].map((il) => il['name']));
      });
    } else {
      _showMessage("Şehirler alınamadı");
    }
  }

  Future<void> _fetchDistricts(String cityName) async {
    selectedDistrict = null;
    selectedDoctor = null;
    districts.clear();
    doctors.clear();
    selectedTime = null;

    final response = await http.get(Uri.parse("https://turkiyeapi.dev/api/v1/provinces"));

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final List provinces = decoded['data'];

      final Map<String, dynamic>? city = provinces.firstWhere(
        (il) => il['name'] == cityName,
        orElse: () => null,
      );

      if (city != null && city['districts'] != null) {
        setState(() {
          districts = List<String>.from((city['districts'] as List).map((ilce) => ilce['name']));
        });
      } else {
        _showMessage("Seçilen şehir bulunamadı.");
      }
    } else {
      _showMessage("İlçeler alınamadı");
    }
  }

  Future<void> _loadDoctors({String? city, String? district}) async {
    selectedDoctor = null;
    selectedTime = null;
    doctors.clear();

    if (city != null && district != null) {
      doctors = await _dbService.getDoctorsByCityDistrict(city, district);
    } else {
      doctors = await _dbService.getAllDoctors();
    }

    setState(() {});
  }

Future<void> _selectDate(BuildContext context) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now().add(Duration(days: 1)),
    firstDate: DateTime.now(),
    lastDate: DateTime.now().add(Duration(days: 365)),
    builder: (context, child) {
      return Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: const Color.fromARGB(255, 96, 151, 202),     
            onPrimary: Colors.white,        
            surface: Colors.white,          
            onSurface: Colors.black87,      
          ),
          dialogBackgroundColor: Colors.white,
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 96, 151, 202),
            ),
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    setState(() {
      selectedDate = picked;
      selectedTime = null;
    });
  }
}


  Future<void> _selectTime(BuildContext context) async {
    if (selectedDoctor == null || selectedDate == null) {
      _showMessage('Lütfen önce doktor ve tarih seçin');
      return;
    }

    final selectedSaat = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RandevuSaatSecimi(
          doctorId: selectedDoctor!['doktor_id'],
          selectedDate: DateFormat('yyyy-MM-dd').format(selectedDate!),
        ),
      ),
    );

    if (selectedSaat != null && mounted) {
      final parts = (selectedSaat as String).split(':');
      setState(() {
        selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      });
    }
  }

  Future<void> _submitAppointment() async {
    if (selectedDate == null || selectedTime == null || selectedDoctor == null) {
      _showMessage('Tüm alanları doldurmalısınız');
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
    final timeStr = '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';

    final appointmentData = {
      'hasta_id': widget.hastaId,
      'doktor_id': selectedDoctor!['doktor_id'],
      'tarih': dateStr,
      'saat': timeStr,
    };

    try {
      await _dbService.makeAppointment(appointmentData);
      _showMessage('Randevu başarıyla alındı');
      Navigator.pop(context);
    } catch (e) {
      _showMessage('Hata: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text('Diş Randevusu Al'),
        backgroundColor: const Color.fromARGB(255, 70, 179, 230),
        centerTitle: true,
        leading: Icon(Icons.medical_services_outlined),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildDropdown(
                  label: 'Şehir Seçin',
                  value: selectedCity,
                  items: cities,
                  onChanged: (val) {
                    setState(() {
                      selectedCity = val;
                      selectedDistrict = null;
                      selectedDoctor = null;
                      districts.clear();
                      doctors.clear();
                      selectedTime = null;
                    });
                    if (val != null) _fetchDistricts(val);
                  },
                ),
                const SizedBox(height: 10),
                _buildDropdown(
                  label: 'İlçe Seçin',
                  value: selectedDistrict,
                  items: districts,
                  onChanged: (val) {
                    setState(() {
                      selectedDistrict = val;
                      selectedDoctor = null;
                      doctors.clear();
                      selectedTime = null;
                    });
                    if (selectedCity != null && val != null) {
                      _loadDoctors(city: selectedCity, district: val);
                    }
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<Map<String, dynamic>>(
                  decoration: InputDecoration(
                    labelText: 'Doktor Seçin',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: doctors.map((doc) {
                    final fullName = '${doc['ad']} ${doc['soyad']}';
                    return DropdownMenuItem(value: doc, child: Text(fullName));
                  }).toList(),
                  value: selectedDoctor,
                  onChanged: (val) {
                    setState(() {
                      selectedDoctor = val;
                      selectedTime = null;
                    });
                  },
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: Icon(Icons.calendar_month_outlined),
                  label: Text(selectedDate == null
                      ? 'Tarih Seç'
                      : 'Tarih: ${DateFormat('dd-MM-yyyy').format(selectedDate!)}'),
                  style: _buttonStyle(),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: (selectedDoctor != null && selectedDate != null)
                      ? () => _selectTime(context)
                      : null,
                  icon: Icon(Icons.access_time),
                  label: Text(selectedTime == null
                      ? 'Saat Seç'
                      : 'Saat: ${selectedTime!.format(context)}'),
                  style: _buttonStyle(),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: _submitAppointment,
                  child: const Text('Randevuyu Kaydet', style: TextStyle(fontSize: 16)),
                  style: _buttonStyle().copyWith(
                    backgroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 96, 151, 202),),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      value: value,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 96, 151, 202),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }
}
