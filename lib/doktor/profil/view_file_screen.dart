import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class ViewFileScreen extends StatefulWidget {
  final String title;
  final String fileBase64;
  final int doktorId;
  final String belgeTuru;

  const ViewFileScreen({
    super.key,
    required this.title,
    required this.fileBase64,
    required this.doktorId,
    required this.belgeTuru,
  });

  @override
  State<ViewFileScreen> createState() => _ViewFileScreenState();
}

class _ViewFileScreenState extends State<ViewFileScreen> {
  File? _secilenDosya;
  String? _tempPdfPath;
  String? _base64FromServer;

  @override
  void initState() {
    super.initState();
    _base64FromServer = widget.fileBase64;
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.storage,
        Permission.mediaLibrary,
        Permission.photos,
        Permission.manageExternalStorage
      ].request();
    }
  }

  Future<void> _belgeSecVeGuncelle() async {
    await requestPermissions();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result == null || result.files.single.path == null) return;

    File dosya = File(result.files.single.path!);
    final bytes = await dosya.readAsBytes();
    final base64String = base64Encode(bytes);

    final response = await http.put(
      Uri.parse('http://192.168.1.2:5000/doctor_update/${widget.doktorId}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({widget.belgeTuru: base64String}),
    );

    if (response.statusCode == 200) {
      setState(() {
        _secilenDosya = dosya;
        _base64FromServer = base64String;
        _tempPdfPath = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Belge başarıyla güncellendi")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Güncelleme başarısız: ${response.body}")),
      );
    }
  }

 Future<Widget> _buildBelgeWidget() async {
  if (_secilenDosya != null) {
    final path = _secilenDosya!.path.toLowerCase();

    if (path.endsWith('.pdf')) {
      _tempPdfPath = _secilenDosya!.path;
      return SizedBox(height: 400, child: PDFView(filePath: _tempPdfPath!));
    }

    if (path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png')) {
      return InteractiveViewer(
        child: Image.file(_secilenDosya!, fit: BoxFit.contain),
      );
    }

    return Text("Desteklenmeyen dosya türü: ${_secilenDosya!.path.split('/').last}");
  }

  if (_base64FromServer != null && _base64FromServer!.isNotEmpty) {
    final bytes = base64Decode(_base64FromServer!.replaceAll(RegExp(r'\s'), ''));

    final isPdf = bytes.length >= 4 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;

    if (isPdf) {
      if (_tempPdfPath == null) {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/temp_${widget.belgeTuru}.pdf';
        await File(filePath).writeAsBytes(bytes, flush: true);
        _tempPdfPath = filePath;
      }
      return SizedBox(height: 400, child: PDFView(filePath: _tempPdfPath!));
    } else {
      return InteractiveViewer(
        child: Image.memory(bytes, fit: BoxFit.contain),
      );
    }
  }

  return const Text("Henüz belge yüklenmemiş");
}


  @override
  Widget build(BuildContext context) {
    final bool belgeYuklu = _base64FromServer != null && _base64FromServer!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color.fromARGB(255, 70, 179, 230),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Widget>(
          future: _buildBelgeWidget(),
          builder: (context, snapshot) {
            final belgeWidget = snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : snapshot.data ?? const Text("Belge bulunamadı");

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                belgeWidget,
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _belgeSecVeGuncelle,
                  icon: const Icon(Icons.upload_file, color: Colors.black),
                  label: Text(
                    belgeYuklu ? "Diş Belgesini Güncelle" : "Diş Belgesi Ekle",
                    style: const TextStyle(color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 70, 179, 230),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
