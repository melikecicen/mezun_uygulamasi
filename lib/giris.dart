import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'kayit_sayfasi.dart';
import 'giris_yap_sayfasi.dart'; // <--- 1. BU IMPORT EKLENDİ

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  static const _dots = ['.', '..', '...'];
  late Timer _timer;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      setState(() => _tick = (_tick + 1) % _dots.length);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arka Plan
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Image.asset(
              'assets/images/mus_alparslan.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Container(color: Colors.black.withValues(alpha: 0.6)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                children: [
                  const Spacer(),
                  Column(
                    children: [
                      // LOGO KISMI
                      Container(
                        width: 130,
                        height: 130,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                          border: Border.all(color: Colors.white30, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE41D2D).withValues(alpha: 0.5),
                              blurRadius: 25,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/mus.jpg', // Logo dosya adın
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Muş Alparslan Üniversitesi',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedDotsText(dots: _dots[_tick]),
                    ],
                  ),
                  const Spacer(),

                  // ROL BUTONLARI (Mezun / Öğrenci)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RoleButton(
                        label: 'Mezunum',
                        icon: Icons.school_outlined,
                        color: const Color(0xFFF6C446),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const KayitSayfasi(gelenRol: 'graduate'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 28),
                      _RoleButton(
                        label: 'Öğrenciyim',
                        icon: Icons.menu_book_outlined,
                        color: const Color(0xFFFC4D57),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const KayitSayfasi(gelenRol: 'student'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // <--- 2. GİRİŞ YAP BUTONU BURAYA EKLENDİ --->
                  const SizedBox(height: 40), // Biraz boşluk bırakalım

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GirisYapSayfasi()),
                      );
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: "Zaten hesabın var mı? ",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                        children: [
                          TextSpan(
                            text: "Giriş Yap",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // <--- GİRİŞ YAP BUTONU BİTTİ --->

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ... (AnimatedDotsText ve _RoleButton sınıfları aynı kalıyor)
class AnimatedDotsText extends StatelessWidget {
  final String dots;
  const AnimatedDotsText({super.key, required this.dots});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Seni Çağırıyor$dots',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Colors.white,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 34),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}