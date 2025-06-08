import 'dart:convert';
import 'package:http/http.dart' as http;

class DBService {
  static const String baseUrl = 'http://192.168.1.2:5000';
  static const String turkiyeApiUrl = 'https://turkiyeapi.dev/api/v1/provinces';

  void _handleError(http.Response response, {String? defaultMessage}) {
    try {
      final body = json.decode(response.body);
      throw Exception(body['error'] ?? defaultMessage ?? 'Bir hata oluştu');
    } catch (_) {
      throw Exception(defaultMessage ?? 'Bir hata oluştu');
    }
  }

  Future<void> registerDoctor(Map<String, dynamic> doktorData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/doctor_register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(doktorData),
    );
    if (response.statusCode != 200) {
      _handleError(response, defaultMessage: 'Doktor kaydı başarısız');
    }
  }

  Future<Map<String, dynamic>> loginDoctor(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/doctor_login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'kullanici_adi': username,
        'sifre': password,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      _handleError(response, defaultMessage: 'Doktor girişi başarısız');
    }
    return {};
  }

  Future<void> registerPatient(Map<String, dynamic> hastaData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/patient_register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(hastaData),
    );
    if (response.statusCode != 200) {
      _handleError(response, defaultMessage: 'Hasta kaydı başarısız');
    }
  }

  Future<void> updateDoctorProfile(int doktorId, Map<String, dynamic> updatedData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/doctor_update/$doktorId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updatedData),
    );
    if (response.statusCode != 200) {
      _handleError(response, defaultMessage: 'Profil güncelleme başarısız');
    }
  }

  Future<Map<String, dynamic>?> getNextAppointment(int hastaId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/next_appointment/$hastaId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data is Map<String, dynamic> && data.isNotEmpty) {
          return data;
        } else {
          throw Exception("Boş randevu verisi alındı.");
        }
      } else if (response.statusCode == 404) {
        return null; // Randevu bulunamadı
      } else {
        throw Exception("Sunucu hatası: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Randevu bilgisi alınamadı: $e");
    }
  }

  /// Türkiye API'den şehirleri çeker
  Future<List<String>> getCities() async {
    try {
      final response = await http.get(Uri.parse(turkiyeApiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final cities = List<String>.from(data['data'].map((il) => il['name']));
        return cities;
      } else {
        throw Exception('Şehirler alınamadı: Sunucudan ${response.statusCode} kodu döndü.');
      }
    } catch (e) {
      print('Hata: $e');
      throw Exception('Şehirler alınamadı: $e');
    }
  }

  /// Türkiye API'den ilçeleri çeker
  Future<List<String>> getDistricts(String cityName) async {
    try {
      final response = await http.get(Uri.parse(turkiyeApiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final city = data['data'].firstWhere((il) => il['name'] == cityName, orElse: () => null);

        if (city != null && city['districts'] != null) {
          return List<String>.from(city['districts'].map((ilce) => ilce['name']));
        } else {
          return [];
        }
      } else {
        throw Exception('İlçeler alınamadı: Sunucudan ${response.statusCode} kodu döndü.');
      }
    } catch (e) {
      print('Hata: $e');
      throw Exception('İlçeler alınamadı: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getDoctorsByCityDistrict(String city, String district) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/doctors?city=$city&district=$district'),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);

      if (decoded is List) {
        // Eğer doğrudan liste geliyorsa bu çalışır
        return List<Map<String, dynamic>>.from(decoded);
      } else if (decoded is Map && decoded.containsKey('data')) {
        // Eğer JSON içinde 'data' anahtarı varsa onu kullan
        return List<Map<String, dynamic>>.from(decoded['data']);
      } else {
        throw Exception('Beklenmeyen veri formatı');
      }
    } else {
      throw Exception('Doktorlar getirilemedi');
    }
  }


  Future<void> makeAppointment(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/appointments/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      final responseBody = jsonDecode(response.body);
      throw Exception(responseBody['error'] ?? 'Randevu oluşturulamadı');
    }
  }


  Future<List<Map<String, dynamic>>> getAllDoctors() async {
    final response = await http.get(Uri.parse('$baseUrl/all_doctors'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      _handleError(response, defaultMessage: 'Doktor listesi alınamadı');
    }
    return [];
  }


  Future<Map<String, dynamic>?> getDoctorWorkingHours(int doctor_id) async {
  final response = await http.get(Uri.parse('$baseUrl/api/doctor/settings/$doctor_id'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getHastaProfile(int hastaId) async {
    final url = Uri.parse('$baseUrl/patient_profile/$hastaId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Hasta profili bulunamadı. Durum kodu: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Hata (getHastaProfile): $e');
      return null;
    }
  }


  Future<void> updatePatientProfile(int hastaId, Map<String, dynamic> updatedData) async {
    final url = Uri.parse('$baseUrl/update_patient_profile');
    final Map<String, dynamic> payload = {
      'hasta_id': hastaId,
      ...updatedData,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Profil güncellenemedi: ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (!(data['success'] ?? false)) {
      throw Exception('Hata: ${data['message']}');
    }
  }

  Future<List<Map<String, dynamic>>> getAllFutureAppointments(int hastaId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/appointments/future/$hastaId'));

    if (response.statusCode == 200) {
      List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.cast<Map<String, dynamic>>();
    } else {
      throw Exception("Randevular alınamadı");
    }
  }

  
}