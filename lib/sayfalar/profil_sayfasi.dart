import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'post_detay_sayfasi.dart';
import 'mesaj_kutusu.dart';

class ProfilSayfasi extends StatefulWidget {
  const ProfilSayfasi({super.key});

  @override
  State<ProfilSayfasi> createState() => _ProfilSayfasiState();
}

class _ProfilSayfasiState extends State<ProfilSayfasi> {
  String _adSoyad = "";
  String _bolum = "";
  String _rol = "";
  String _rolRaw = ""; // 'student' veya 'grad'/'alumni'
  String _bio = "";
  String _userDepartment = "";
  String _userAboutMe = "";
  int _puan = 0;
  String? _avatarUrl;
  bool _yukleniyor = true;
  bool _resimYukleniyor = false;
  int _gonderiSayisi = 0;
  final int _takipci = 128;
  final int _takip = 45;
  static const Color _primaryRed = Color(0xFFE41D2D);
  final _supabase = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> _kullaniciPostlari;
  late Future<List<Map<String, dynamic>>> _etiketlenenPostlar;
  late Stream<List<Map<String, dynamic>>> _kullaniciIlanlari;

  @override
  void initState() {
    super.initState();
    _profilVerisiniGetir();
    _kullaniciPostlari = _postlariGetir();
    _etiketlenenPostlar = _etiketlendigimPostlariGetir();
    _ilanlariGetir();
  }

  void _ilanlariGetir() {
    final myId = _supabase.auth.currentUser!.id;
    _kullaniciIlanlari = _supabase
        .from('collab_posts')
        .stream(primaryKey: ['id'])
        .eq('owner_id', myId)
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> _postlariGetir() async {
    final userId = _supabase.auth.currentUser!.id;
    final data = await _supabase
        .from('posts')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    if (mounted) setState(() => _gonderiSayisi = data.length);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> _etiketlendigimPostlariGetir() async {
    final userId = _supabase.auth.currentUser!.id;
    final data = await _supabase
        .from('post_tags')
        .select('posts(*)')
        .eq('user_id', userId);
    List<Map<String, dynamic>> temizListe = [];
    for (var item in data) {
      if (item['posts'] != null) {
        temizListe.add(item['posts'] as Map<String, dynamic>);
      }
    }
    return temizListe;
  }

  Future<void> _profilVerisiniGetir() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      final registryData = await _supabase
          .from('valid_registry')
          .select()
          .eq('user_id', userId)
          .single();
      if (mounted) {
        setState(() {
          _adSoyad = profileData['full_name'] ?? "İsimsiz";
          _bio = profileData['bio'] ?? "";
          _puan = profileData['points'] ?? 0;
          _avatarUrl = profileData['avatar_url'];
          _userDepartment = profileData['department'] ?? "";
          _userAboutMe = profileData['about_me'] ?? "";
          _bolum = registryData['department'] ?? "";
          _rolRaw = registryData['role'] ?? 'student';
          _rol = _rolRaw == 'student' ? 'Öğrenci' : 'Mezun';
          _yukleniyor = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _profilResmiDegistir() async {
    final ImagePicker picker = ImagePicker();
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text("Galeriden Seç"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? img =
                await picker.pickImage(source: ImageSource.gallery);
                if (img != null) _resmiYukle(File(img.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Fotoğraf Çek"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? img =
                await picker.pickImage(source: ImageSource.camera);
                if (img != null) _resmiYukle(File(img.path));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resmiYukle(File dosya) async {
    setState(() => _resimYukleniyor = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      final ext = dosya.path.split('.').last;
      final path = '$userId/avatar.$ext';
      await _supabase.storage.from('avatars').upload(
        path,
        dosya,
        fileOptions: const FileOptions(upsert: true),
      );
      final url = _supabase.storage.from('avatars').getPublicUrl(path);
      final urlTime = "$url?t=${DateTime.now().millisecondsSinceEpoch}";
      await _supabase
          .from('profiles')
          .update({'avatar_url': urlTime}).eq('id', userId);
      if (mounted) {
        setState(() {
          _avatarUrl = urlTime;
          _resimYukleniyor = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _resimYukleniyor = false);
    }
  }

  void _profiliDuzenle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Düzenleme özelliği yakında...")),
    );
  }

  void _profiliPaylas() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    final shareText = [
      if (_adSoyad.isNotEmpty) _adSoyad,
      if (_userDepartment.isNotEmpty) _userDepartment,
      "Profilimi MAUN Sosyal'de incele: maunapp://profile/$userId",
    ].join("\n");
    await Clipboard.setData(ClipboardData(text: shareText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Paylaşım metni panoya kopyalandı!")),
    );
  }

  // QR Kod Okut ve Puan Kazan
  Future<void> _qrKodOkut() async {
    // Şimdilik TextField dialog ile test
    final qrController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("QR Kod Okut"),
        content: TextField(
          controller: qrController,
          decoration: const InputDecoration(
            hintText: "QR kod içeriğini girin (örn: etkinlik_50puan)",
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, qrController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: _primaryRed),
            child: const Text("Gönder", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      final userId = _supabase.auth.currentUser!.id;
      
      // Anti-cheat: Daha önce bu QR kodunu kullanmış mı?
      final existing = await _supabase
          .from('claimed_rewards')
          .select()
          .eq('user_id', userId)
          .eq('qr_code_text', result)
          .maybeSingle();

      if (existing != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Bu ödülü daha önce aldınız!"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // QR kod formatını parse et (örn: "etkinlik_50puan" -> 50 puan)
      int puanKazan = 50; // Varsayılan
      if (result.contains('_')) {
        final parts = result.split('_');
        if (parts.length >= 2) {
          final puanStr = parts.last.replaceAll('puan', '');
          puanKazan = int.tryParse(puanStr) ?? 50;
        }
      }

      // Puanı ekle
      final currentPoints = _puan;
      await _supabase
          .from('profiles')
          .update({'points': currentPoints + puanKazan})
          .eq('id', userId);

      // claimed_rewards tablosuna kayıt ekle
      await _supabase.from('claimed_rewards').insert({
        'user_id': userId,
        'qr_code_text': result,
        'reward_level': puanKazan,
        'status': 'claimed',
      });

      if (mounted) {
        setState(() {
          _puan = currentPoints + puanKazan;
        });

        // Başarı dialogu
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.celebration, color: _primaryRed, size: 28),
                const SizedBox(width: 8),
                const Text("Tebrikler!"),
              ],
            ),
            content: Text(
              "$puanKazan Puan Kazandınız!\n\nToplam Puanınız: ${_puan} P",
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: _primaryRed),
                child: const Text("Harika!", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Puan Harcama (250 puan)
  Future<void> _puanHarca(int miktar, String islemAdi, Function() onSuccess) async {
    if (_puan < miktar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Yetersiz puan! Mevcut puanınız: $_puan P"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Onay"),
        content: Text(
          "$miktar Puan harcanacak.\n\n$islemAdi işlemini onaylıyor musunuz?",
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primaryRed),
            child: const Text("Onayla", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (onay != true) return;

    try {
      final userId = _supabase.auth.currentUser!.id;
      final yeniPuan = _puan - miktar;

      await _supabase
          .from('profiles')
          .update({'points': yeniPuan})
          .eq('id', userId);

      if (mounted) {
        setState(() {
          _puan = yeniPuan;
        });
        onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Öğrenci: Yemek Hakkı Yükle
  Future<void> _yemekHakkiYukle() async {
    await _puanHarca(250, "Yemek Hakkı Yükleme", () {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Yemek kartınıza 1 hak tanımlandı!"),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  // Mezun: İndirim Kuponu Al
  Future<void> _indirimKuponuAl() async {
    await _puanHarca(250, "İndirim Kuponu Alma", () {
      final kuponKodu = "MAUN${DateTime.now().year}${Random().nextInt(9999).toString().padLeft(4, '0')}";
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.local_offer, color: _primaryRed, size: 28),
              const SizedBox(width: 8),
              const Text("Kupon Kodunuz"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryRed, width: 2),
                ),
                child: Text(
                  kuponKodu,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _primaryRed,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "%10 İndirim Kuponu",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                "Bu kodu MAUN Store'da kullanabilirsiniz.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: _primaryRed),
              child: const Text("Tamam", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    });
  }

  void _basvuranlariGor(int postId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Başvuranlar",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder(
                future: _supabase.from('collab_requests').select(
                  'applicant_id, profiles:applicant_id(full_name, avatar_url)',
                ).eq('post_id', postId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final list = snapshot.data as List;
                  if (list.isEmpty) return const Text("Henüz başvuru yok.");
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      final p = item['profiles'];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                          NetworkImage(p['avatar_url'] ?? ""),
                        ),
                        title: Text(p['full_name']),
                        trailing: IconButton(
                          icon: const Icon(Icons.message,
                              color: _primaryRed),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MesajKutusu(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ilanDurumuDegistir(int id, bool val) async {
    await _supabase
        .from('collab_posts')
        .update({'is_active': val}).eq('id', id);
    setState(() {
      _ilanlariGetir();
    });
  }

  Future<void> _ilanSil(int id) async {
    await _supabase.from('collab_posts').delete().eq('id', id);
    setState(() {
      _ilanlariGetir();
    });
  }

  Future<void> _etiketiKaldir(int postId) async {
    await _supabase
        .from('post_tags')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', _supabase.auth.currentUser!.id);
    setState(() {
      _etiketlenenPostlar = _etiketlendigimPostlariGetir();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _yukleniyor
          ? const Center(
        child: CircularProgressIndicator(color: _primaryRed),
      )
          : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _profilResmiDegistir,
                    child: Stack(
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 2,
                            ),
                            image: _avatarUrl != null
                                ? DecorationImage(
                              image:
                              NetworkImage(_avatarUrl!),
                              fit: BoxFit.cover,
                            )
                                : const DecorationImage(
                              image: AssetImage(
                                  'assets/images/mus.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (_resimYukleniyor)
                          const Positioned.fill(
                            child: CircularProgressIndicator(
                                color: _primaryRed),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _primaryRed,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.add_a_photo,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat("Gönderi", _gonderiSayisi),
                        _buildStat("Takipçi", _takipci),
                        _buildStat("Takip", _takip),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_adSoyad.isNotEmpty)
                    Text(
                      _adSoyad,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  if (_userDepartment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _userDepartment,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (_rol.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _bolum.isNotEmpty ? "$_rol • $_bolum" : _rol,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  if (_bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _bio,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _profiliDuzenle,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text("Profili Düzenle"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _profiliPaylas,
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text("Paylaş"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Modern Puan Kartı
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryRed,
                    _primaryRed.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primaryRed.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Mevcut Puan",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$_puan P",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // QR Okut Butonu
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                      onPressed: _qrKodOkut,
                      tooltip: "QR Kod Okut ve Puan Kazan",
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Role göre ödül butonu
                  if (_rolRaw == 'student')
                    ElevatedButton.icon(
                      onPressed: _yemekHakkiYukle,
                      icon: const Icon(Icons.restaurant, size: 18),
                      label: const Text("Yemek Hakkı\nYükle", textAlign: TextAlign.center),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _primaryRed,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _indirimKuponuAl,
                      icon: const Icon(Icons.local_offer, size: 18),
                      label: const Text("%10 İndirim\nKuponu", textAlign: TextAlign.center),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _primaryRed,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  const TabBar(
                    indicatorColor: _primaryRed,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(icon: Icon(Icons.info_outline)),
                      Tab(icon: Icon(Icons.grid_on)),
                      Tab(icon: Icon(Icons.assignment_ind_outlined)),
                      Tab(icon: Icon(Icons.handshake_outlined)),
                    ],
                  ),
                  SizedBox(
                    height: 500,
                    child: TabBarView(
                      children: [
                        _buildAboutSection(),
                        _buildPhotoGrid(
                          _kullaniciPostlari,
                          "Gönderi yok",
                          isTagged: false,
                        ),
                        _buildPhotoGrid(
                          _etiketlenenPostlar,
                          "Etiket yok",
                          isTagged: true,
                        ),
                        _buildIlanListesi(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid(
      Future<List<Map<String, dynamic>>> future,
      String emptyMsg, {
        bool isTagged = false,
      }) {
    return FutureBuilder(
      future: future,
      builder: (ctx, snap) {
        if (!snap.hasData || (snap.data as List).isEmpty) {
          return Center(child: Text(emptyMsg));
        }
        final posts = snap.data as List;
        return GridView.builder(
          padding: const EdgeInsets.all(2),
          itemCount: posts.length,
          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemBuilder: (ctx, i) {
            final post = posts[i];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PostDetaySayfasi(post: post),
                  ),
                ).then((_) {
                  setState(() {
                    _kullaniciPostlari = _postlariGetir();
                    _etiketlenenPostlar =
                        _etiketlendigimPostlariGetir();
                  });
                });
              },
              onLongPress:
              isTagged ? () => _etiketiKaldir(post['id']) : null,
              child: Image.network(
                post['image_url'],
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    Container(color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIlanListesi() {
    return StreamBuilder(
      stream: _kullaniciIlanlari,
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final jobs = snap.data as List;
        if (jobs.isEmpty) return const Center(child: Text("İlanın yok"));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          separatorBuilder: (c, i) => const Divider(),
          itemBuilder: (ctx, i) {
            final job = jobs[i];
            final bool active = job['is_active'] ?? true;
            return ListTile(
              title: Text(
                job['title'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.black : Colors.grey,
                ),
              ),
              subtitle: Text(
                active ? "Yayında" : "Pasif",
                style: TextStyle(
                  color: active ? Colors.green : Colors.grey,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.people, color: Colors.blue),
                    onPressed: () => _basvuranlariGor(job['id']),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: active,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.green,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey,
                      onChanged: (val) =>
                          _ilanDurumuDegistir(job['id'], val),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _ilanSil(job['id']),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAboutSection() {
    if (_userAboutMe.isEmpty) {
      return const Center(
        child: Text("Henüz bir Hakkımda yazısı eklenmedi."),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: _primaryRed.withOpacity(0.8)),
              const SizedBox(width: 8),
              const Text(
                "Hakkımda",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _userAboutMe,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }
}