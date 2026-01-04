import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ana_sayfa.dart'; // <--- YÖNLENDİRME İÇİN BU EKLENDİ

class KayitSayfasi extends StatefulWidget {
  final String gelenRol;
  const KayitSayfasi({super.key, required this.gelenRol});

  @override
  State<KayitSayfasi> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<KayitSayfasi>
    with SingleTickerProviderStateMixin {

  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _tcController = TextEditingController();
  final _schoolNoController = TextEditingController();
  final _gradYearController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _passwordErrorText; // <--- ŞİFRE HATASI İÇİN DEĞİŞKEN

  late String _selectedRole;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const Color _primaryRed = Color(0xFFE41D2D);
  static const Color _backgroundLight = Color(0xFFF9FAFB);
  static const Color _textDark = Color(0xFF333333);
  static const Color _accentLight = Color(0xFFFFE5E7);

  // SABİT BÖLÜM LİSTESİ
  static const List<String> _bolumListesi = [
    "İktisat",
    "İşletme",
    "Siyaset Bilimi ve Kamu Yönetimi",
    "Uluslararası Ticaret ve İşletmecilik",
    "Gazeticilik",
    "Halkla İlişkiler ve Tanıtım",
    "Radyo, Televizyon ve Sinema",
    "Temel İslam Bilimleri",
    "Felsefe ve Din Bilimleri",
    "İslam Tarihi ve Sanatları",
    "Elektrik Elektronik Mühendisliği",
    "Gıda Mühendisliği",
    "Makine Mühendisliği",
    "Mimarlık",
    "Şehir ve Bölge Planlama",
    "Yazılım Mühendisliği",
    "Beslenme ve Diyetetik",
    "Dil ve Konuşma Terapisi",
    "Ebelik",
    "Fizyoterapi ve Rehabilitasyon",
    "Gerontoloji",
    "Hemşirelik",
    "İş Sağlığı ve Güvenliği",
    "Odyoloji",
    "Sağlık Yönetimi",
    "Sosyal Hizmet",
    "Beden Eğitimi ve Spor",
    "Engellilerde Egzersiz ve Spor Bilimleri",
    "Antrenörlük Eğitimi",
    "Spor Yöneticiliği",
    "Rekreasyon",
    "Bilişim Sistemleri ve Teknolojileri Bölümü",
    "Bitkisel Üretim ve Teknolojileri",
    "Hayvansal Üretim ve Teknolojileri",
    "Felsefe",
    "Fizik",
    "İngiliz Dili ve Edebiyatı",
    "Kimya",
    "Kürt Dili ve Edebiyatı",
    "Matematik",
    "Moleküler Biyoloji ve Genetik",
    "Psikoloji",
    "Sosyoloji",
    "Tarih",
    "Türk Dili ve Edebiyatı",
    "Doğu Dilleri ve Edebiyatı",
  ];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.gelenRol;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _departmentController.dispose();
    _tcController.dispose();
    _schoolNoController.dispose();
    _gradYearController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // <--- ŞİFRE KONTROL FONKSİYONU --->
  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordErrorText = "Şifre boş olamaz";
      } else if (value.length < 6) {
        _passwordErrorText = "Şifre en az 6 karakter olmalı";
      } else {
        _passwordErrorText = null; // Hata yok
      }
    });
  }

  // DOĞRULAMA VE KAYIT
  Future<void> _verifyAndRegister() async {
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('valid_registry')
          .select()
          .eq('role', _selectedRole)
          .eq('tc_last_4', _tcController.text.trim())
          .eq('is_registered', false)
          .maybeSingle();

      if (response == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('HATA: Bilgiler eşleşmedi veya zaten kayıtlısınız!')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'username': _nameController.text.trim(),
          'full_name': '${_nameController.text} ${_surnameController.text}',
        },
      );

      if (authResponse.user != null) {
        await Supabase.instance.client.from('valid_registry').update({
          'is_registered': true,
          'user_id': authResponse.user!.id,
        }).eq('id', response['id']);

        await Supabase.instance.client.from('profiles').upsert({
          'id': authResponse.user!.id,
          'username': _emailController.text.split('@')[0],
          'full_name': '${_nameController.text} ${_surnameController.text}',
          'points': 0,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tebrikler! Kayıt Başarılı. Yönlendiriliyorsunuz...')),
          );

          // <--- OTOMATİK YÖNLENDİRME KODU BURADA --->
          // 1 saniye bekleyip Ana Sayfaya atıyoruz ki kullanıcı "Başarılı" yazısını görsün.
          await Future.delayed(const Duration(seconds: 1));

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AnaSayfa()),
                  (route) => false, // Geri tuşuna basınca kayıt ekranına dönmesin diye
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bir hata oluştu: $e')),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
    String? helperText,
    String? errorText, // Hata mesajı için parametre
    void Function(String)? onChanged, // Değişiklik dinleyicisi
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLength: maxLength,
        onChanged: onChanged, // <--- Dinleyiciyi bağladık
        style: const TextStyle(color: _textDark, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          errorText: errorText, // <--- Hata mesajını bağladık
          prefixIcon: Icon(icon, color: _primaryRed),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _primaryRed, width: 2)),
        ),
      ),
    );
  }

  // AKILLI ARAMA KUTUSU
  Widget _buildSearchableDepartmentField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<String>.empty();
              }
              return _bolumListesi.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              _departmentController.text = selection;
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              if (textEditingController.text.isEmpty && _departmentController.text.isNotEmpty) {
                textEditingController.text = _departmentController.text;
              }
              textEditingController.addListener(() {
                _departmentController.text = textEditingController.text;
              });

              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                style: const TextStyle(color: _textDark, fontSize: 16),
                decoration: InputDecoration(
                  labelText: "Bölümünüz (Örn: Bilgisayar)",
                  prefixIcon: const Icon(Icons.apartment_outlined, color: _primaryRed),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _primaryRed, width: 2)),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: constraints.maxWidth,
                    color: Colors.white,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return ListTile(
                          title: Text(option),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 32),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: _primaryRed),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Text('Kayıt Ol', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _primaryRed, letterSpacing: -0.5)),
                      ],
                    ),
                  ),
                  Card(
                    elevation: 8,
                    shadowColor: Colors.black.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: _accentLight, borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.verified_user, color: _primaryRed, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                widget.gelenRol == 'student' ? "Öğrenci Kaydı" : "Mezun Kaydı",
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: _accentLight.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _primaryRed.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  widget.gelenRol == 'student'
                                      ? Icons.menu_book_outlined
                                      : Icons.school_outlined,
                                  color: _primaryRed,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  widget.gelenRol == 'student' ? 'Rol: Öğrenci' : 'Rol: Mezun',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _primaryRed),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildModernTextField(controller: _nameController, label: "Adınız", icon: Icons.person_outline),
                          _buildModernTextField(controller: _surnameController, label: "Soyadınız", icon: Icons.badge_outlined),

                          _buildSearchableDepartmentField(),

                          if (_selectedRole == 'student')
                            _buildModernTextField(controller: _schoolNoController, label: "Okul Numaranız", icon: Icons.numbers, keyboardType: TextInputType.number),
                          if (_selectedRole == 'graduate')
                            _buildModernTextField(controller: _gradYearController, label: "Mezuniyet Yılınız", icon: Icons.calendar_month_outlined, keyboardType: TextInputType.number),

                          _buildModernTextField(controller: _tcController, label: "TC Kimlik No (Son 4 Hane)", icon: Icons.lock_outline, keyboardType: TextInputType.number, maxLength: 4, helperText: "Kimliğinizi doğrulamak için gereklidir."),

                          Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Divider(height: 1, thickness: 1, color: Colors.grey.shade300)),

                          Row(children: [
                            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _accentLight, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.account_circle_outlined, color: _primaryRed, size: 24)),
                            const SizedBox(width: 12),
                            const Text("Kalıcı Hesap Bilgisi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
                          ]),
                          const SizedBox(height: 28),
                          _buildModernTextField(controller: _emailController, label: "Kişisel E-Posta (Gmail vb.)", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),

                          // ŞİFRE ALANI (GÜNCELLENDİ)
                          _buildModernTextField(
                              controller: _passwordController,
                              label: "Yeni Şifreniz",
                              icon: Icons.lock_outline,
                              obscureText: true,
                              onChanged: _validatePassword, // <--- DİNLEYİCİ EKLENDİ
                              errorText: _passwordErrorText // <--- HATA MESAJI EKLENDİ
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      // HATA VARSA BUTON TIKLANAMAZ
                      onPressed: (_isLoading || _passwordErrorText != null) ? null : _verifyAndRegister,
                      style: ElevatedButton.styleFrom(backgroundColor: _primaryRed, foregroundColor: Colors.white, elevation: 6, shadowColor: _primaryRed.withValues(alpha: 0.4), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), disabledBackgroundColor: Colors.grey.shade300),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.check_circle_outline, size: 22), SizedBox(width: 12), Text("DOĞRULA VE KAYIT OL", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5))]),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}