import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _formData = {};
  DateTime? _selectedDate;
  String? _selectedGender;

  File? _diplomaFile;
  File? _isYeriFile;

  final TextEditingController _dateController = TextEditingController();

  List<Map<String, dynamic>> _iller = [];
  List<String> _ilceler = [];
  String? _selectedIl;
  String? _selectedIlce;

  @override
  void initState() {
    super.initState();
    fetchProvinces();
  }

  Future<void> fetchProvinces() async {
    final url = Uri.parse('https://turkiyeapi.dev/api/v1/provinces');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List provinces = data['data'];
      setState(() {
        _iller = provinces
            .map<Map<String, dynamic>>((e) => {
                  'name': e['name'],
                  'districts': List<String>.from(
                      (e['districts'] as List).map((d) => d['name'])),
                })
            .toList();
      });
    } else {
      print('İller alınamadı: ${response.body}');
    }
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    }
  }

  Future<void> _pickFile(bool isDiploma) async {
    await requestPermissions();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      setState(() {
        if (isDiploma) {
          _diplomaFile = file;
        } else {
          _isYeriFile = file;
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        final formatted = DateFormat('dd-MM-yyyy', 'tr_TR').format(picked);
        _dateController.text = formatted;
        _formData['dogum_tarihi'] = formatted;
      });
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
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const buttonColor = Color.fromARGB(255, 70, 179, 230);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doktor Kayıt'),
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

                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Doğum Tarihi (gg-aa-yyyy)',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () => _selectDate(context),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Doğum tarihi gerekli";
                      }
                      try {
                        DateFormat('dd-MM-yyyy', 'tr_TR').parseStrict(value);
                        return null;
                      } catch (_) {
                        return "Geçerli bir tarih girin (gg-aa-yyyy)";
                      }
                    },
                    onSaved: (value) =>
                        _formData['dogum_tarihi'] = value!,
                  ),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'İl'),
                    value: _selectedIl,
                    items: _iller
                        .map<DropdownMenuItem<String>>(
                          (il) => DropdownMenuItem<String>(
                            value: il['name'],
                            child: Text(il['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedIl = value!;
                        _formData['il'] = value;
                        _selectedIlce = null;
                        _ilceler = _iller
                            .firstWhere((il) => il['name'] == value)['districts']
                            .cast<String>();
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Lütfen il seçin' : null,
                  ),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'İlçe'),
                    value: _selectedIlce,
                    items: _ilceler
                        .map((ilce) =>
                            DropdownMenuItem(value: ilce, child: Text(ilce)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedIlce = value!;
                        _formData['ilce'] = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Lütfen ilçe seçin' : null,
                  ),

                  _buildTextField("Tam Adres", "tamadres"),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _pickFile(true),
                    icon: const Icon(Icons.upload_file),
                    label: Text(_diplomaFile != null
                        ? 'Diploma: ${_diplomaFile!.path.split('/').last}'
                        : 'Diploma Belgesi Seç'),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _pickFile(false),
                    icon: const Icon(Icons.upload_file),
                    label: Text(_isYeriFile != null
                        ? 'İş yeri Belgesi: ${_isYeriFile!.path.split('/').last}'
                        : 'İş Yeri Belgesi Seç'),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      if (_diplomaFile == null || _isYeriFile == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Lütfen tüm belgeleri yükleyin.")),
                        );
                        return;
                      }

                      _formKey.currentState!.save();

                      try {
                        final diplomaBase64 =
                            base64Encode(_diplomaFile!.readAsBytesSync());
                        final isYeriBase64 =
                            base64Encode(_isYeriFile!.readAsBytesSync());

                        final requestBody = {
                          "ad": _formData['ad'],
                          "soyad": _formData['soyad'],
                          "tc_kimlik_no": _formData['tc_kimlik_no'],
                          "brans": _formData['brans'],
                          "kullanici_adi": _formData['kullanici_adi'],
                          "sifre": _formData['sifre'],
                          "cinsiyet": _selectedGender,
                          "dogum_tarihi": _formData['dogum_tarihi'],
                          "diploma_belgesi": diplomaBase64,
                          "isyeri_belgesi": isYeriBase64,
                          "il": _selectedIl,
                          "ilce": _selectedIlce,
                          "tamadres": _formData['tamadres'],
                        };

                        final response = await http.post(
                          Uri.parse('http://192.168.1.2:5000/doctor_register'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode(requestBody),
                        );

                        if (response.statusCode == 200) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Kayıt başarılı!")),
                          );
                          Navigator.pushNamed(context, '/User_Type_Selection');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text("Kayıt başarısız: ${response.body}")),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Bir hata oluştu: $e")),
                        );
                      }
                    },
                    child: const Text("Kayıt Ol"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
