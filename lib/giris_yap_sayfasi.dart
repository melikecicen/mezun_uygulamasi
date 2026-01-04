import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ana_sayfa.dart';

class GirisYapSayfasi extends StatefulWidget {
  const GirisYapSayfasi({super.key});

  @override
  State<GirisYapSayfasi> createState() => _GirisYapSayfasiState();
}

class _GirisYapSayfasiState extends State<GirisYapSayfasi> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Şifre hatası için değişken (null ise hata yok demektir)
  String? _passwordErrorText;

  // Renk Paleti (Diğer sayfalarla uyumlu)
  static const Color _primaryRed = Color(0xFFE41D2D);
  static const Color _backgroundLight = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF333333);

  // ✅ İSTEDİĞİN ÖZELLİK: Canlı Şifre Kontrolü
  void _sifreKontrol(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordErrorText = "Şifre boş olamaz";
      } else if (value.length < 6) {
        _passwordErrorText = "Şifre en az 6 karakter olmalıdır";
      } else {
        _passwordErrorText = null; // Hata yok, kırmızı yazı gider
      }
    });
  }

  Future<void> _girisYap() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        if (mounted) {
          // Giriş başarılı, Ana Sayfaya git
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AnaSayfa()),
          );
        }
      }
    } on AuthException catch (e) {
      // Supabase'den gelen hatalar (Yanlış şifre vb.)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message == "Invalid login credentials"
                ? "HATA: E-posta veya şifre yanlış!"
                : "Hata: ${e.message}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Beklenmedik bir hata oluştu.")),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _primaryRed),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LOGO veya İKON
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _primaryRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.login_rounded, size: 60, color: _primaryRed),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                "Tekrar Hoş Geldiniz! 👋",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                "Hesabınıza giriş yapın.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // E-POSTA
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "E-Posta",
                  prefixIcon: const Icon(Icons.email_outlined, color: _primaryRed),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _primaryRed, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ŞİFRE (Canlı Kontrollü)
              TextField(
                controller: _passwordController,
                obscureText: true,
                onChanged: _sifreKontrol, // Her harf yazışta kontrol eder
                decoration: InputDecoration(
                  labelText: "Şifre",
                  prefixIcon: const Icon(Icons.lock_outline, color: _primaryRed),
                  // HATA MESAJI BURADA GÖRÜNÜR
                  errorText: _passwordErrorText,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _primaryRed, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              // Şifremi Unuttum (Süs olarak)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text("Şifremi Unuttum?", style: TextStyle(color: _primaryRed)),
                ),
              ),
              const SizedBox(height: 24),

              // GİRİŞ BUTONU
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isLoading || _passwordErrorText != null) ? null : _girisYap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("GİRİŞ YAP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}