import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:randevu_sistemi/doktor/patient_detail_screen.dart';

import 'user_type_selection_screen.dart';
import 'doktor/doctor_login_screen.dart';
import 'patient/patient_login_screen.dart';
import 'patient/patient_register_screen.dart';
import 'doktor/doctor_register_screen.dart';
import 'doktor/profil/doktor_home_screen.dart';
import 'doktor/profil/doctor_profile_screen.dart';
import 'doktor/profil/edit_doctor_profile.dart';
import 'doktor/profil/view_file_screen.dart';
import 'doktor/profil/doctor_schedule_page.dart';
import 'patient/patient_home.dart'; 
import 'patient/randevu_alma_ekrani.dart';
import 'patient/profil/patient_profile_screen.dart';
import 'patient/profil/edit_patient_profile.dart';
import 'patient/profil/view_patient_file_screen.dart';
import 'patient/profil/patient_apointment_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doktor Randevu Sistemi',
      theme: ThemeData(
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.black,
        ),
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.black),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          suffixIconColor: Colors.black,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionColor: Colors.black12,
          selectionHandleColor: Colors.black,
        ),
      ),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      home: const UserTypeSelectionScreen(),
      routes: {
        '/patient_login': (context) => const PatientLoginScreen(),
        '/doctor_login': (context) => const DoctorLoginScreen(),
        '/patient_register': (context) => const PatientRegisterScreen(),
        '/doctor_register': (context) => const DoctorRegisterScreen(),
        '/User_Type_Selection': (context) => const UserTypeSelectionScreen(),
    
        // Doktor profil ekranı
        '/doctor_profile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return DoctorProfileScreen(doktorId: args['doktor_id']);
        },

        // Doktor randevu saat ayarlama ekranı
        '/randevu_ayarla': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return DoctorSchedulePage(doctorId: args['doktor_id']);
        },

        // Dosya görüntüleme ekranı
        '/view_file': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ViewFileScreen(
            title: args['title'] as String,
            fileBase64: args['file_base64'] as String? ?? '',
            doktorId: args['doktor_id'] as int? ?? 0,
            belgeTuru: args['belge_turu'] as String? ?? 'diploma_belgesi',
          );
        },

        // İş yeri belgesi için aynı view
        '/view_workplace_file': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ViewFileScreen(
            title: args['title'] as String,
            fileBase64: args['file_base64'] as String? ?? '',
            doktorId: args['doktor_id'] as int? ?? 0,
            belgeTuru: args['belge_turu'] as String? ?? 'isyeri_belgesi',
          );
        },

        '/hasta_profil': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return PatientProfileScreen(hastaId: args['hasta_id']);
        },

        '/hasta_randevulari': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return PatientAppointmentScreen(hastaId: args['hasta_id']);
        },

        '/view_patient_file': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ViewPatientFileScreen(
            title: args['title'] as String,
            fileBase64: args['file_base64'] as String? ?? '',
            hastaId: args['hasta_id'] as int? ?? 0,
            belgeTuru: args['belge_turu'] as String? ?? 'ameliyat_raporu',
          );
        },

        '/view_patient_rontgen_file': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ViewPatientFileScreen(
            title: args['title'] as String,
            fileBase64: args['file_base64'] as String? ?? '',
            hastaId: args['hasta_id'] as int? ?? 0,
            belgeTuru: args['belge_turu'] as String? ?? 'rontgen',
          );
        },


      },

      onGenerateRoute: (settings) {
        if (settings.name == '/doctor_home') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => DoctorHomeScreen(
              doktorId: args?['doktor_id'] ?? 0,
              doktorAdi: args?['doktor_adi'] ?? '',
            ),
          );
        }

        if (settings.name == '/edit_doctor_profile') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => EditProfilePage(
              doktorId: args?['doktor_id'] ?? 0,
              initialSoyad: args?['soyad'] ?? '',
              initialBrans: args?['brans'] ?? '',
              initialKullaniciAdi: args?['kullanici_adi'] ?? '',
            ),
          );
        }
        
        if (settings.name == '/patient_home') {
          final args = settings.arguments as Map<String, dynamic>?;

          final hastaIdRaw = args?['hasta_id'];
          final hastaId = hastaIdRaw is int
              ? hastaIdRaw
              : int.tryParse(hastaIdRaw.toString()) ?? 0;

          return MaterialPageRoute(
            builder: (context) => PatientHomeScreen(
              hastaId: hastaId,
            ),
          );
        }

        if (settings.name == '/randevu_al') {
          final args = settings.arguments as Map<String, dynamic>?;

          print('RandevuAl sayfasına gelen argümanlar: $args');

          final hastaIdRaw = args?['hasta_id'];
          final hastaId = hastaIdRaw is int
              ? hastaIdRaw
              : int.tryParse(hastaIdRaw.toString()) ?? 0;

          return MaterialPageRoute(
            builder: (context) => RandevuAlEkrani(
              hastaId: hastaId,
            ),
          );
        }
        
        if (settings.name == '/edit_patient_profile') {
          final args = settings.arguments as Map<String, dynamic>?;

          return MaterialPageRoute(
            builder: (context) => EditPatientProfilePage(
              hastaId: args?['hasta_id'] ?? 0,
              initialAd: args?['ad'] ?? '',
              initialSoyad: args?['soyad'] ?? '',
              initialKullaniciAdi: args?['kullanici_adi'] ?? '',
            ),
          );
        }

        if (settings.name == '/hasta_detay') {
          final args = settings.arguments as Map<String, dynamic>?;
          final id = args?['hasta_id'] ?? 0;
          return MaterialPageRoute(
            builder: (context) => PatientDetailScreen(hastaId: id),
          );
        }


        return null; 
      },
    );
  }
}
