import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PatientAppointmentScreen extends StatefulWidget {
  final int hastaId;
  const PatientAppointmentScreen({super.key, required this.hastaId});

  @override
  State<PatientAppointmentScreen> createState() => _PatientAppointmentScreenState();
}

class _PatientAppointmentScreenState extends State<PatientAppointmentScreen> {
  List<dynamic> gecmisRandevular = [];
  List<dynamic> gelecekRandevular = [];
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    randevulariGetir();
  }

  Future<void> randevulariGetir() async {
    final url = Uri.parse("http://192.168.1.2:5000/api/appointments/hasta?hasta_id=${widget.hastaId}");
    final cevap = await http.get(url);

    if (cevap.statusCode == 200) {
      final veriler = json.decode(cevap.body);
      setState(() {
        gecmisRandevular = veriler.where((r) => r['durum'] == 'geçmiş').toList();
        gelecekRandevular = veriler.where((r) => r['durum'] == 'gelecek').toList();
        yukleniyor = false;
      });
    } else {
      print("Randevular alınamadı");
      setState(() {
        yukleniyor = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Randevular alınamadı.")),
      );
    }
  }

  Future<void> randevuIptalEt(int randevuId) async {
    final url = Uri.parse("http://192.168.1.2:5000/api/appointments/delete/$randevuId");
    final cevap = await http.delete(url);

    if (cevap.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Randevu iptal edildi")),
      );
      randevulariGetir();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Randevu iptal edilemedi")),
      );
    }
  }

  Widget randevuKart(Map randevu, bool iptalEdilebilir) {
    Widget card = Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      color: iptalEdilebilir ? Colors.white : Colors.grey.shade100,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        leading: Icon(Icons.event_note_rounded, color: const Color(0xFFBFD7ED), size: 36),
        title: Text(
          "${randevu['tarih']} - ${randevu['saat']}",
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(Icons.person, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                "Doktor: ${randevu['doktor_adi']}",
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
            ],
          ),
        ),
        trailing: iptalEdilebilir
            ? ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 233, 112, 110),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(90, 36),
                ),
                icon: const Icon(Icons.cancel, size: 20, color: Colors.black,),
                label: const Text("İptal", style: TextStyle(fontSize: 14, color: Colors.black)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Randevuyu İptal Et"),
                      content: const Text("Randevuyu iptal etmek istediğinize emin misiniz?"),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Hayır",style: TextStyle(color: Colors.black ),)),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            randevuIptalEt(randevu['randevu_id']);
                          },
                          child: const Text("Evet", style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  );
                },
              )
            : null,
      ),
    );

    // Eğer iptalEdilebilir değilse opacity uygula
    if (!iptalEdilebilir) {
      return Opacity(
        opacity: 0.5, // istediğin siliklik seviyesi
        child: card,
      );
    } else {
      return card;
    }
  }

  Widget sectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFBFD7ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 70, 179, 230)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text("Randevularım"),
        backgroundColor: const Color.fromARGB(255, 70, 179, 230),
      ),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: randevulariGetir,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  sectionHeader("Yaklaşan Randevular"),
                  if (gelecekRandevular.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "Yaklaşan randevunuz bulunmamaktadır.",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...gelecekRandevular.map((r) => randevuKart(r, true)).toList(),
                  const SizedBox(height: 30),
                  sectionHeader("Geçmiş Randevular"),
                  if (gecmisRandevular.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        "Geçmiş randevunuz bulunmamaktadır.",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...gecmisRandevular.map((r) => randevuKart(r, false)).toList(),
                ],
              ),
            ),
    );
  }
}
