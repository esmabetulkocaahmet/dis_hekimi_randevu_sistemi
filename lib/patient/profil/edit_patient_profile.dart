import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:randevu_sistemi/services/db_service.dart';

class EditPatientProfilePage extends StatefulWidget {
  final int hastaId;
  final String initialAd;
  final String initialSoyad;
  final String initialKullaniciAdi;

  const EditPatientProfilePage({
    required this.hastaId,
    required this.initialAd,
    required this.initialSoyad,
    required this.initialKullaniciAdi,
    Key? key,
  }) : super(key: key);

  @override
  _EditPatientProfilePageState createState() => _EditPatientProfilePageState();
}

class _EditPatientProfilePageState extends State<EditPatientProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _adController;
  late TextEditingController _soyadController;
  late TextEditingController _kullaniciAdiController;
  final TextEditingController _sifreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _adController = TextEditingController(text: widget.initialAd);
    _soyadController = TextEditingController(text: widget.initialSoyad);
    _kullaniciAdiController = TextEditingController(text: widget.initialKullaniciAdi);
  }

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _kullaniciAdiController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> updatedData = {};


      if (_soyadController.text != widget.initialSoyad) {
        updatedData['soyad'] = _soyadController.text;
      }

      if (_kullaniciAdiController.text != widget.initialKullaniciAdi) {
        updatedData['kullanici_adi'] = _kullaniciAdiController.text;
      }

      if (_sifreController.text.isNotEmpty) {
        updatedData['sifre'] = _sifreController.text;
      }

      if (updatedData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Herhangi bir değişiklik yapılmadı')),
        );
        return;
      }

      try {
        await DBService().updatePatientProfile(widget.hastaId, updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil başarıyla güncellendi')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Güncelleme sırasında hata oluştu: $e')),
        );
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.lightBlue.shade700) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.blue.shade50.withOpacity(0.2),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label boş bırakılamaz';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('Profil Güncelle'),
        backgroundColor: const Color.fromARGB(255, 70, 179, 230),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.lightBlue.shade100,
                child: Icon(Icons.person, size: 40, color: Colors.blue.shade800),
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'Soyad',
                controller: _soyadController,
                icon: FontAwesomeIcons.user,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'Kullanıcı Adı',
                controller: _kullaniciAdiController,
                icon: FontAwesomeIcons.userTag,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'Yeni Şifre',
                controller: _sifreController,
                icon: FontAwesomeIcons.lock,
                obscure: true,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 70, 179, 230),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  iconColor: Colors.black,
                ),
                onPressed: _updateProfile,
                icon: const Icon(Icons.save_alt),
                label: const Text('Güncelle', style: TextStyle(fontSize: 16, color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
