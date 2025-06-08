import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randevu_sistemi/services/db_service.dart';

class PatientHomeScreen extends StatefulWidget {
  final int hastaId;

  const PatientHomeScreen({Key? key, required this.hastaId}) : super(key: key);

  @override
  State<PatientHomeScreen> createState() => _PatientHomeState();
}

class _PatientHomeState extends State<PatientHomeScreen> {
  final DBService _dbService = DBService();
  Map<String, dynamic>? randevu;
  String hastaAdi = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final List<Map<String, dynamic>> randevular = await _dbService.getAllFutureAppointments(widget.hastaId);
      final profile = await _dbService.getHastaProfile(widget.hastaId);

      final now = DateTime.now();

      // En yakın geçerli randevuyu bul (şu andan sonra olan)
      randevular.sort((a, b) {
        final aDateTime = _combineDateTime(a['tarih'], a['saat']);
        final bDateTime = _combineDateTime(b['tarih'], b['saat']);
        return aDateTime.compareTo(bDateTime);
      });

      final nextRandevu = randevular.firstWhere(
        (r) => _combineDateTime(r['tarih'], r['saat']).isAfter(now),
        orElse: () => {},
      );

      setState(() {
        randevu = nextRandevu.isNotEmpty ? nextRandevu : null;
        hastaAdi = profile?['ad']?.toString() ?? "";
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Hata: $e");
      setState(() {
        isLoading = false;
        randevu = null;
      });
    }
  }

// Yardımcı fonksiyon
DateTime _combineDateTime(String? dateStr, String? timeStr) {
  final DateTime date = DateTime.parse(dateStr!);
  final parts = timeStr!.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  return DateTime(date.year, date.month, date.day, hour, minute);
}


  String _formatDate(String? dateStr) {
    if (dateStr == null) return "";
    try {
      final DateTime date = DateTime.parse(dateStr);
      return DateFormat('dd MMMM yyyy', 'tr_TR').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.blue[50],
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 70, 179, 230),
          elevation: 2,
          centerTitle: false,
          automaticallyImplyLeading: false,
          title: Text(
            "Hoşgeldiniz, $hastaAdi",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person, color: Colors.black),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/hasta_profil',
                  arguments: {'hasta_id': widget.hastaId},
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.black),
              onPressed: () => _showLogoutConfirmation(context),
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: randevu == null || randevu!.isEmpty
                  ? _buildEmptyMessage("Yaklaşan randevunuz bulunmamaktadır.")
                  : _buildRandevuCard(randevu?['tarih'], randevu?['saat'], randevu?['doktor_adi']),
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(
              context,
              "/randevu_al",
              arguments: {'hasta_id': widget.hastaId},
            );
          },
          label: const Text("Randevu Al", style: TextStyle(color: Colors.black)),
          icon: const Icon(Icons.add, color: Colors.black),
          backgroundColor: const Color(0xFFBFD7ED),
        ),
      ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.event_busy, size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(fontSize: 18, color: Colors.black54)),
      ],
    );
  }

  Widget _buildRandevuCard(String? tarih, String? saat, String? doktor) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFBFD7ED), 
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Yaklaşan Randevunuz",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.calendar_today, color: Colors.black),
                Text("Tarih: ${_formatDate(tarih)}", style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.access_time, color: Colors.black),
                Text("Saat: $saat", style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.medical_services, color: Colors.black),
                Expanded(
                  child: Text(
                    "Doktor: $doktor",
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
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
            style: TextButton.styleFrom(foregroundColor: Colors.black),
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
