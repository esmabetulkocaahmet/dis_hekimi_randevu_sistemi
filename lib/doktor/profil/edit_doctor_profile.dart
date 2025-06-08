import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:randevu_sistemi/services/db_service.dart';

class EditProfilePage extends StatefulWidget {
  final int doktorId;
  final String initialSoyad;
  final String initialBrans;
  final String initialKullaniciAdi;

  const EditProfilePage({
    required this.doktorId,
    required this.initialSoyad,
    required this.initialBrans,
    required this.initialKullaniciAdi,
    Key? key,
  }) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _soyadController;
  late TextEditingController _bransController;
  late TextEditingController _kullaniciAdiController;
  final TextEditingController _sifreController = TextEditingController();
  final TextEditingController _tamAdresController = TextEditingController();

  List<Map<String, dynamic>> _iller = [];
  List<String> _ilceler = [];
  String? _selectedIl;
  String? _selectedIlce;

  @override
  void initState() {
    super.initState();
    _soyadController = TextEditingController(text: widget.initialSoyad);
    _bransController = TextEditingController(text: widget.initialBrans);
    _kullaniciAdiController = TextEditingController(text: widget.initialKullaniciAdi);
    fetchProvinces();
  }

  Future<void> fetchProvinces() async {
    final response = await http.get(Uri.parse('https://turkiyeapi.dev/api/v1/provinces'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List provinces = data['data'];
      setState(() {
        _iller = provinces.map<Map<String, dynamic>>((e) => {
          'name': e['name'],
          'districts': List<String>.from((e['districts'] as List).map((d) => d['name'])),
        }).toList();
      });
    }
  }

  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> updatedData = {};

      if (_soyadController.text != widget.initialSoyad) {
        updatedData['soyad'] = _soyadController.text;
      }

      if (_bransController.text != widget.initialBrans) {
        updatedData['brans'] = _bransController.text;
      }

      if (_kullaniciAdiController.text != widget.initialKullaniciAdi) {
        updatedData['kullanici_adi'] = _kullaniciAdiController.text;
      }

      if (_sifreController.text.isNotEmpty) {
        updatedData['sifre'] = _sifreController.text;
      }

      if (_selectedIl != null || _selectedIlce != null || _tamAdresController.text.isNotEmpty) {
        updatedData['adres'] = {
          'il': _selectedIl,
          'ilce': _selectedIlce,
          'tamadres': _tamAdresController.text,
        };
      }

      if (updatedData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Herhangi bir değişiklik yapılmadı')),
        );
        return;
      }

      try {
        await DBService().updateDoctorProfile(widget.doktorId, updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil başarıyla güncellendi')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e')),
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
                child: Icon(Icons.medical_services, size: 40, color: Colors.blue.shade800),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Soyad',
                controller: _soyadController,
                icon: FontAwesomeIcons.user,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'Branş',
                controller: _bransController,
                icon: FontAwesomeIcons.tooth,
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
              const Divider(thickness: 1.5),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Adres Bilgileri", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'İl',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                value: _selectedIl,
                items: _iller.map<DropdownMenuItem<String>>((il) => DropdownMenuItem<String>(
                  value: il['name'],
                  child: Text(il['name']),
                )).toList(),

                onChanged: (value) {
                  setState(() {
                    _selectedIl = value;
                    _selectedIlce = null;
                    _ilceler = _iller.firstWhere((il) => il['name'] == value)['districts'].cast<String>();
                  });
                },
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'İlçe',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                value: _selectedIlce,
                items: _ilceler.map((ilce) => DropdownMenuItem(
                  value: ilce,
                  child: Text(ilce),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedIlce = value;
                  });
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _tamAdresController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Tam Adres',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:  const Color.fromARGB(255, 70, 179, 230), 
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
