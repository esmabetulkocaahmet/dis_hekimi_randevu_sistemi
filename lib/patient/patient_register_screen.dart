import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class PatientRegisterScreen extends StatefulWidget {
  const PatientRegisterScreen({super.key});

  @override
  State<PatientRegisterScreen> createState() => _PatientRegisterScreenState();
}

class _PatientRegisterScreenState extends State<PatientRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _formData = {};
  File? _raporFile;
  File? _rontgenFile;
  DateTime? _selectedDate;
  String? _selectedGender;

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      if (!await Permission.storage.isGranted) {
        await Permission.storage.request();
      }
    }
  }

  Future<void> _pickFile(bool isRapor) async {
    await requestPermissions();
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      setState(() {
        if (isRapor) {
          _raporFile = file;
        } else {
          _rontgenFile = file;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isRapor ? "Rapor yüklendi." : "Röntgen yüklendi.")),
      );
    }
  }

  Future<void> _registerPatient() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGender == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cinsiyet ve doğum tarihi zorunludur.")),
      );
      return;
    }

    if (_raporFile == null || _rontgenFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen rapor ve röntgen belgelerini yükleyin.")),
      );
      return;
    }

    _formKey.currentState!.save();
    _formData['cinsiyet'] = _selectedGender!;
    _formData['dogum_tarihi'] = DateFormat('dd-MM-yyyy').format(_selectedDate!);

    try {
      final raporBase64 = base64Encode(await _raporFile!.readAsBytes());
      final rontgenBase64 = base64Encode(await _rontgenFile!.readAsBytes());

      final response = await http.post(
        Uri.parse('http://192.168.1.2:5000/patient_register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          ..._formData,
          'rapor_belgesi': raporBase64,
          'rontgen_belgesi': rontgenBase64,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kayıt başarılı!")),
        );
        Navigator.pushNamed(context, '/User_Type_Selection');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Kayıt başarısız. Sunucu cevabı: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bir hata oluştu: $e")),
      );
    }
  }

  Widget _buildTextField(String label, String field,
      {bool obscure = false}) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      obscureText: obscure,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return "$label gerekli";
        return null;
      },
      onSaved: (value) => _formData[field] = value!.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const buttonColor = Color.fromARGB(255, 70, 179, 230);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hasta Kayıt"),
        backgroundColor: buttonColor,
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: 0.3,
            child: Image.asset(
              'assets/images/tooth.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField("Ad", "ad"),
                  _buildTextField("Soyad", "soyad"),
                  _buildTextField("T.C. Kimlik No", "tc_kimlik_no"),
                  _buildTextField("Branş", "brans"),
                  _buildTextField("Kullanıcı Adı", "kullanici_adi"),
                  _buildTextField("Şifre", "sifre", obscure: true),
                  _buildTextField("Adres", "adres"),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(labelText: 'Cinsiyet'),
                    items: const [
                      DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
                      DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                        _formData['cinsiyet'] = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Lütfen cinsiyet seçin' : null,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    title: Text(_selectedDate == null
                        ? 'Doğum tarihi seçin'
                        : DateFormat('dd-MM-yyyy').format(_selectedDate!)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2000),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(_raporFile != null ? Icons.check_circle : Icons.upload_file),
                          label: Text(_raporFile != null ? 'Rapor Yüklendi' : 'Rapor Yükle'),
                          onPressed: () => _pickFile(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(_rontgenFile != null ? Icons.check_circle : Icons.upload_file),
                          label: Text(_rontgenFile != null ? 'Röntgen Yüklendi' : 'Röntgen Yükle'),
                          onPressed: () => _pickFile(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _registerPatient,
                    child: const Text("Kayıt Ol", style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
