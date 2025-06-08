import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PatientDetailScreen extends StatefulWidget {
  final int hastaId;

  const PatientDetailScreen({super.key, required this.hastaId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  Map<String, dynamic>? hastaVerisi;
  bool isLoading = true;
  String? hataMesaji;

  @override
  void initState() {
    super.initState();
    _hastaBilgileriniGetir();
  }

  Future<void> _hastaBilgileriniGetir() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.2:5000/patient_profile/${widget.hastaId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          hastaVerisi = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          hataMesaji = 'Hasta bilgisi getirilemedi';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hataMesaji = 'Bir hata oluştu: $e';
        isLoading = false;
      });
    }
  }


  String _formatDogumTarihi(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('d MMMM y', 'tr_TR').format(dt);
    } catch (e) {
      return 'N/A';
    }
  }

  String _hesaplaYas(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'N/A';
    try {
      final dogumTarihi = DateTime.parse(isoDate);
      final bugun = DateTime.now();
      int yas = bugun.year - dogumTarihi.year;
      if (bugun.month < dogumTarihi.month ||
          (bugun.month == dogumTarihi.month && bugun.day < dogumTarihi.day)) {
        yas--;
      }
      return '$yas';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dogumTarihiStr = hastaVerisi?['dogum_tarihi'];
    final dogumTarihiFormatted = _formatDogumTarihi(dogumTarihiStr);
    final yas = _hesaplaYas(dogumTarihiStr);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Hasta Detayı"),
        backgroundColor: const Color.fromARGB(255, 70, 179, 230),
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hataMesaji != null
              ? Center(child: Text(hataMesaji!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Hasta Bilgileri",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 70, 179, 230),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Ad Soyad ve Profil Resmi Satırı
                                Row(
                                  children: [
                                    Image.asset(
                                      (hastaVerisi?['cinsiyet']?.toLowerCase() ?? 'erkek') == 'kadın'
                                          ? 'assets/images/female_user.png'
                                          : 'assets/images/male_user.png',
                                      width: 24,
                                      height: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Adı Soyadı: ${hastaVerisi?['ad'] ?? 'N/A'} ${hastaVerisi?['soyad'] ?? ''}",
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 12),
                              Text(
                                "🆔 T.C. No: ${hastaVerisi?['tc_kimlik_no'] ?? 'N/A'}",
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "🎂 Doğum Tarihi: $dogumTarihiFormatted",
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "📅 Yaş: $yas",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Belgeler",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 70, 179, 230),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Ameliyat Raporu
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color.fromARGB(255, 70, 179, 230),
                          side: const BorderSide(color: const Color.fromARGB(255, 70, 179, 230)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/view_patient_file',
                            arguments: {
                              'title': 'Ameliyat Raporu',
                              'file_base64': hastaVerisi?['ameliyat_raporu'],
                            },
                          );
                        },
                        icon: const Icon(Icons.description),
                        label: const Text("Ameliyat Raporunu Görüntüle"),
                      ),
                      const SizedBox(height: 10),

                      // Röntgen Görüntüsü
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color.fromARGB(255, 70, 179, 230),
                          side: const BorderSide(color: const Color.fromARGB(255, 70, 179, 230)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/view_patient_rontgen_file',
                            arguments: {
                              'title': 'Röntgen Görüntüsü',
                              'file_base64': hastaVerisi?['rontgen'],
                            },
                          );
                        },
                        icon: const Icon(Icons.medical_information),
                        label: const Text("Röntgeni Görüntüle"),
                      ),
                    ]  
                  ),
                ),
    );
  }
}
