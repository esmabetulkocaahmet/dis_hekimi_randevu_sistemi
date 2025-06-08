import 'package:flutter/material.dart';
import 'package:randevu_sistemi/services/db_service.dart';

class PatientProfileScreen extends StatefulWidget {
  final int hastaId;

  const PatientProfileScreen({super.key, required this.hastaId});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final DBService _dbService = DBService();
  Map<String, dynamic>? patientData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  Future<void> _getProfile() async {
    try {
      final data = await _dbService.getHastaProfile(widget.hastaId);
      setState(() {
        patientData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hasta bilgileri alınamadı")),
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
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
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
          : patientData == null
              ? const Center(child: Text("Bilgiler getirilemedi"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              profileImage(patientData!['cinsiyet']),
                              const SizedBox(height: 12),
                              Text(
                                "${patientData!['ad']} ${patientData!['soyad']}",
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "TC Kimlik No: ${patientData!['tc_kimlik_no']}",
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
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
                                label: const Text("Profili Düzenle",
                                    style: TextStyle(color: Colors.white)),
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, '/edit_patient_profile',
                                      arguments: {
                                        'hasta_id': widget.hastaId,
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
                                icon: const Icon(Icons.calendar_today,
                                    color: Colors.white),
                                label: const Text("Randevularımı Görüntüle",
                                    style: TextStyle(color: Colors.white)),
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, '/hasta_randevulari',
                                      arguments: {
                                        'hasta_id': widget.hastaId,
                                      });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                "Belgelerim",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                icon: const Icon(Icons.picture_as_pdf,
                                    color: Colors.white),
                                label: const Text("Ameliyat Raporunu Görüntüle",
                                    style: TextStyle(color: Colors.white)),
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, '/view_patient_file',
                                      arguments: {
                                        'title': 'Ameliyat Raporu',
                                        'file_base64': patientData!['ameliyat_raporu'],
                                      });
                                },
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                icon: const Icon(Icons.image,
                                    color: Colors.white),
                                label: const Text("Röntgeni Görüntüle",
                                    style: TextStyle(color: Colors.white)),
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, '/view_patient_rontgen_file',
                                      arguments: {
                                        'title': 'Röntgen Görüntüsü',
                                        'file_base64': patientData!['rontgen'],
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
