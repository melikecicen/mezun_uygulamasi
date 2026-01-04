import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../giris.dart'; // Giriş ekranına dönmek için

class AyarlarSayfasi extends StatefulWidget {
  const AyarlarSayfasi({super.key});

  @override
  State<AyarlarSayfasi> createState() => _AyarlarSayfasiState();
}

class _AyarlarSayfasiState extends State<AyarlarSayfasi> {
  bool _karanlikMod = false;
  bool _bildirimler = true;
  bool _bildirimlerYukleniyor = false;

  @override
  void initState() {
    super.initState();
    _bildirimAyarlariniGetir();
  }

  // Bildirim ayarlarını Supabase'den çek
  Future<void> _bildirimAyarlariniGetir() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      
      if (currentUser == null) return;
      
      final response = await supabase
          .from('profiles')
          .select('is_notifications_enabled')
          .eq('id', currentUser.id)
          .single();
      
      if (mounted && response['is_notifications_enabled'] != null) {
        setState(() {
          _bildirimler = response['is_notifications_enabled'] as bool;
        });
      }
    } catch (e) {
      // Hata durumunda varsayılan değer (true) kullanılır
      if (mounted) {
        setState(() {
          _bildirimler = true;
        });
      }
    }
  }

  // Bildirim ayarını Supabase'e kaydet
  Future<void> _bildirimAyarlariniKaydet(bool yeniDeger) async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Oturum bilgisi bulunamadı.")),
          );
        }
        return;
      }
      
      setState(() {
        _bildirimlerYukleniyor = true;
      });
      
      await supabase
          .from('profiles')
          .update({'is_notifications_enabled': yeniDeger})
          .eq('id', currentUser.id);
      
      if (mounted) {
        setState(() {
          _bildirimler = yeniDeger;
          _bildirimlerYukleniyor = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              yeniDeger 
                ? "Bildirimler açıldı" 
                : "Bildirimler kapatıldı"
            ),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bildirimlerYukleniyor = false;
          // Hata durumunda eski değere geri dön
          _bildirimler = !yeniDeger;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Ayarlar kaydedilemedi: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- ŞİFRE DEĞİŞTİRME PENCERESİ (Modern BottomSheet) ---
  void _sifreDegistirPenceresi() {
    final eskiSifreController = TextEditingController();
    final yeniSifreController = TextEditingController();
    final yeniSifreTekrarController = TextEditingController();
    
    bool eskiSifreGizli = true;
    bool yeniSifreGizli = true;
    bool yeniSifreTekrarGizli = true;
    bool yukleniyor = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tutma Çubuğu (Handle Bar)
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Başlık
              const Text(
                "Yeni Şifre Belirle",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 32),
              
              // Eski Şifre
              TextField(
                controller: eskiSifreController,
                obscureText: eskiSifreGizli,
                enabled: !yukleniyor,
                decoration: InputDecoration(
                  hintText: "Mevcut şifreniz",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(eskiSifreGizli ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () {
                      setModalState(() => eskiSifreGizli = !eskiSifreGizli);
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              
              // Yeni Şifre
              TextField(
                controller: yeniSifreController,
                obscureText: yeniSifreGizli,
                enabled: !yukleniyor,
                decoration: InputDecoration(
                  hintText: "En az 6 karakter",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(yeniSifreGizli ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () {
                      setModalState(() => yeniSifreGizli = !yeniSifreGizli);
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              
              // Yeni Şifre Tekrar
              TextField(
                controller: yeniSifreTekrarController,
                obscureText: yeniSifreTekrarGizli,
                enabled: !yukleniyor,
                decoration: InputDecoration(
                  hintText: "Yeni şifrenizi tekrar girin",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(yeniSifreTekrarGizli ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () {
                      setModalState(() => yeniSifreTekrarGizli = !yeniSifreTekrarGizli);
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 32),
              
              // GÜNCELLE Butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: yukleniyor ? null : () async {
                    final eskiSifre = eskiSifreController.text.trim();
                    final yeniSifre = yeniSifreController.text.trim();
                    final yeniSifreTekrar = yeniSifreTekrarController.text.trim();
                    
                    // Validasyonlar
                    if (eskiSifre.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Lütfen mevcut şifrenizi girin.")),
                      );
                      return;
                    }
                    
                    if (yeniSifre.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Yeni şifre en az 6 karakter olmalıdır.")),
                      );
                      return;
                    }
                    
                    if (yeniSifre != yeniSifreTekrar) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Yeni şifreler uyuşmuyor.")),
                      );
                      return;
                    }
                    
                    if (eskiSifre == yeniSifre) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Yeni şifre mevcut şifre ile aynı olamaz.")),
                      );
                      return;
                    }
                    
                    // Loading durumu
                    setModalState(() => yukleniyor = true);
                    
                    try {
                      final supabase = Supabase.instance.client;
                      final currentUser = supabase.auth.currentUser;
                      
                      if (currentUser == null || currentUser.email == null) {
                        throw Exception("Kullanıcı bilgisi bulunamadı.");
                      }
                      
                      // Re-Authentication: Eski şifreyi doğrula
                      try {
                        await supabase.auth.signInWithPassword(
                          email: currentUser.email!,
                          password: eskiSifre,
                        );
                      } catch (e) {
                        if (mounted) {
                          setModalState(() => yukleniyor = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Eski şifreniz hatalı.")),
                          );
                        }
                        return;
                      }
                      
                      // Şifreyi güncelle
                      await supabase.auth.updateUser(
                        UserAttributes(password: yeniSifre),
                      );
                      
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Şifreniz başarıyla güncellendi"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        setModalState(() => yukleniyor = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Hata oluştu: ${e.toString()}")),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE41D2D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: yukleniyor
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          "GÜNCELLE",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Çıkış Yapma Fonksiyonu
  Future<void> _cikisYap() async {
    bool? eminMi = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Çıkış Yap"),
        content: const Text("Uygulamadan çıkış yapmak istediğine emin misin?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Evet, Çıkış Yap", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (eminMi == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const GirisEkrani()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayarlar"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),

          // GÖRÜNÜM AYARLARI
          _baslik("Görünüm"),
          SwitchListTile(
            title: const Text("Karanlık Mod"),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: _karanlikMod,
            activeColor: Colors.green,
            onChanged: (val) {
              setState(() {
                _karanlikMod = val;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Gelecek sürümde eklenecek!")),
                );
              });
            },
          ),

          const Divider(),

          // BİLDİRİM AYARLARI
          _baslik("Bildirimler"),
          SwitchListTile(
            title: const Text("Bildirimleri Aç"),
            secondary: const Icon(Icons.notifications_active_outlined),
            value: _bildirimler,
            activeColor: Colors.green,
            onChanged: _bildirimlerYukleniyor ? null : (val) {
              _bildirimAyarlariniKaydet(val);
            },
          ),

          const Divider(),

          // HESAP AYARLARI
          _baslik("Hesap"),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text("Şifre Değiştir"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _sifreDegistirPenceresi, // <--- FONKSİYONU BURADA ÇAĞIRIYORUZ
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Dil Seçeneği"),
            trailing: const Text("Türkçe", style: TextStyle(color: Colors.grey)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Şu an sadece Türkçe desteklenmektedir.")),
              );
            },
          ),

          const Divider(),

          // ÇIKIŞ YAP BUTONU
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Çıkış Yap", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: _cikisYap,
          ),
        ],
      ),
    );
  }

  Widget _baslik(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}