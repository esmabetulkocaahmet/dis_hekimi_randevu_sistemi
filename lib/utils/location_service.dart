import 'dart:convert';
import 'package:flutter/services.dart';

class LocationService {
  static Future<Map<String, List<String>>> loadIlIlceVerisi() async {
    final String jsonString = await rootBundle.loadString('assets/json/il-ilce.json');
    final List<dynamic> jsonData = json.decode(jsonString);

    final Map<String, List<String>> ilIlceMap = {};

    for (var item in jsonData) {
      final il = item['il'];
      final List<String> ilceler = List<String>.from(item['ilceler']);
      ilIlceMap[il] = ilceler;
    }

    return ilIlceMap;
  }
}
