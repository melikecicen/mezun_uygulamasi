import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';// SSL sertifikası için (HttpOverrides)

// Sayfalar
import 'giris.dart';
import 'ana_sayfa.dart';


// --- SSL SERTİFİKA HATASINI AŞMAK İÇİN ---
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SSL Sertifika kontrolünü devre dışı bırak (Okul sitesi için gerekli olabilir)
  HttpOverrides.global = MyHttpOverrides();

  // Supabase Başlatma
  await Supabase.initialize(
      url: 'https://eoqswyxtzfuzpyzlqeef.supabase.co', // <-- KENDİ URL'İNİ KONTROL ET
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVvcXN3eXh0emZ1enB5emxxZWVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM0Mjk4NTksImV4cCI6MjA3OTAwNTg1OX0.Jb1iWu9VADf1fv9W7dFoR3Rigg6tzzu-D-4PjM_4PE4'
    // <-- KENDİ KEY'İNİ KONTROL ET
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MAUN Sosyal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red, // Ana renk kırmızı
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      // HANGİ EKRAN AÇILACAK? (KONTROL NOKTASI)
      home: const BaslangicKontrol(),
    );
  }
}

// --- AKILLI BAŞLANGIÇ KONTROLÜ ---
class BaslangicKontrol extends StatefulWidget {
  const BaslangicKontrol({super.key});

  @override
  State<BaslangicKontrol> createState() => _BaslangicKontrolState();
}

class _BaslangicKontrolState extends State<BaslangicKontrol> {
  @override
  void initState() {
    super.initState();
    _yonlendir();
  }

  Future<void> _yonlendir() async {
    // Supabase'in başlaması için çok kısa bekle (Milisaniyelik)
    await Future.delayed(Duration.zero);

    // Oturum var mı kontrol et
    final session = Supabase.instance.client.auth.currentSession;

    if (!mounted) return;

    if (session != null) {
      // Zaten giriş yapmış -> ANA SAYFAYA GİT
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AnaSayfa()),
      );
    } else {
      // Giriş yapmamış -> GİRİŞ EKRANINA GİT
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GirisEkrani()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Yönlendirme yapılırken boş beyaz ekran veya logo göster
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFE41D2D)),
      ),
    );
  }
}