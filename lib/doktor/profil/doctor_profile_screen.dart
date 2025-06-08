import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DoctorProfileScreen extends StatefulWidget {
  final int doktorId;

  const DoctorProfileScreen({super.key, required this.doktorId});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  Map<String, dynamic>? doctorData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctorData();
  }

  Future<void> _fetchDoctorData() async {
    final url = Uri.parse('http://192.168.1.2:5000/doctor_profile/${widget.doktorId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        doctorData = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Doktor bilgileri alınamadı")),
      );
    }
  }

  Widget profileImage(String gender) {
    String assetPath = gender.toLowerCase() == 'kadın'
        ? 'assets/images/female_user.png'
        : 'assets/images/male_user.png';

    return CircleAvatar(
      radius: 50,
      backgroundImage: AssetImage(assetPath),
      backgroundColor: Colors.white,
    );
  }

  Widget infoTile(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16)),
        const Divider(thickness: 0.5),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Profilim'),
        backgroundColor: const Color.fromARGB(255, 70, 179, 230),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : doctorData == null
              ? const Center(child: Text("Bilgiler getirilemedi"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              profileImage(doctorData!['cinsiyet']),
                              const SizedBox(height: 12),
                              Text(
                                "${doctorData!['ad']} ${doctorData!['soyad']}",
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                doctorData!['brans'],
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                icon: const Icon(Icons.edit, color: Colors.white),
                                label: const Text("Profili Düzenle", style: TextStyle(color: Colors.white)),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/edit_doctor_profile', arguments: {
                                    'doktor_id': widget.doktorId,
                                    'soyad': "",
                                    'brans': "",
                                    'kullanici_adi': "",
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo.shade600,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                icon: const Icon(Icons.schedule, color: Colors.white),
                                label: const Text("Randevuları Düzenle", style: TextStyle(color: Colors.white)),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/randevu_ayarla', arguments: {
                                    'doktor_id': widget.doktorId,
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                "Belgeler",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                                label: const Text("Diploma Belgesini Görüntüle", style: TextStyle(color: Colors.white)),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/view_file', arguments: {
                                    'title': 'Diploma Belgesi',
                                    'file_base64': doctorData!['diploma_belgesi'],
                                    'doktor_id': widget.doktorId,
                                    'belge_turu': 'diploma_belgesi',
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                icon: const Icon(Icons.work, color: Colors.white),
                                label: const Text("İş Yeri Belgesini Görüntüle", style: TextStyle(color: Colors.white)),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/view_workplace_file', arguments: {
                                    'title': 'İş Yeri Belgesi',
                                    'file_base64': doctorData!['isyeri_belgesi'],
                                    'doktor_id': widget.doktorId,
                                    'belge_turu': 'isyeri_belgesi',
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
