import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaylasimSayfasi extends StatefulWidget {
  const PaylasimSayfasi({super.key});

  @override
  State<PaylasimSayfasi> createState() => _PaylasimSayfasiState();
}

class _PaylasimSayfasiState extends State<PaylasimSayfasi> {
  final _aciklamaController = TextEditingController();
  final _aramaController = TextEditingController();
  File? _secilenResim;
  bool _yukleniyor = false;
  final ImagePicker _picker = ImagePicker();
  final _supabase = Supabase.instance.client;
  static const Color _primaryRed = Color(0xFFE41D2D);

  // Kişi etiketleme için
  List<Map<String, dynamic>> _seciliKullanicilar = [];
  List<Map<String, dynamic>> _tumKullanicilar = [];
  bool _kullanicilarYukleniyor = false;

  @override
  void dispose() {
    _aciklamaController.dispose();
    _aramaController.dispose();
    super.dispose();
  }

  // RESİM SEÇME (KAMERA VEYA GALERİ)
  Future<void> _resimSec() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: _primaryRed),
                title: const Text("Galeriden Seç"),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() => _secilenResim = File(image.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: _primaryRed),
                title: const Text("Fotoğraf Çek"),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() => _secilenResim = File(image.path));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // KULLANICI ARAMA VE LİSTELEME
  Future<void> _kullanicilariGetir(String arama) async {
    setState(() => _kullanicilarYukleniyor = true);
    try {
      final myUserId = _supabase.auth.currentUser?.id;
      if (myUserId == null) return;

      dynamic sorgu = _supabase
          .from('profiles')
          .select('id, full_name, avatar_url')
          .neq('id', myUserId);

      if (arama.isNotEmpty) {
        sorgu = sorgu.ilike('full_name', '%$arama%');
      } else {
        sorgu = sorgu.limit(20);
      }

      final data = await sorgu;

      if (mounted) {
        setState(() {
          _tumKullanicilar = List<Map<String, dynamic>>.from(data);
          _kullanicilarYukleniyor = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _kullanicilarYukleniyor = false);
      }
    }
  }

  // KİŞİ ETİKETLEME BOTTOM SHEET
  void _kisileriEtiketle() {
    _aramaController.clear();
    _kullanicilariGetir("");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Kişileri Etiketle",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _aramaController,
                decoration: InputDecoration(
                  hintText: "Kullanıcı ara...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) => _kullanicilariGetir(value),
              ),
            ),
            Expanded(
              child: _kullanicilarYukleniyor
                  ? const Center(child: CircularProgressIndicator())
                  : _tumKullanicilar.isEmpty
                      ? const Center(
                          child: Text("Kullanıcı bulunamadı."),
                        )
                      : ListView.builder(
                          itemCount: _tumKullanicilar.length,
                          itemBuilder: (context, index) {
                            final kullanici = _tumKullanicilar[index];
                            final userId = kullanici['id'] as String;
                            final name =
                                (kullanici['full_name'] as String?) ?? "Kullanıcı";
                            final avatarUrl = kullanici['avatar_url'] as String?;
                            final seciliMi = _seciliKullanicilar
                                .any((k) => k['id'] == userId);

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: avatarUrl != null
                                    ? NetworkImage(avatarUrl)
                                    : const AssetImage('assets/images/mus.jpg')
                                        as ImageProvider,
                              ),
                              title: Text(name),
                              trailing: seciliMi
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: _primaryRed,
                                    )
                                  : const Icon(
                                      Icons.circle_outlined,
                                      color: Colors.grey,
                                    ),
                              onTap: () {
                                setState(() {
                                  if (seciliMi) {
                                    _seciliKullanicilar
                                        .removeWhere((k) => k['id'] == userId);
                                  } else {
                                    _seciliKullanicilar.add(kullanici);
                                  }
                                });
                              },
                            );
                          },
                        ),
            ),
            if (_seciliKullanicilar.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: const Border(
                    top: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${_seciliKullanicilar.length} kişi seçildi",
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Tamam",
                        style: TextStyle(
                          color: _primaryRed,
                          fontWeight: FontWeight.bold,
                        ),
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

  // SUPABASE'E YÜKLEME VE KAYDETME
  Future<void> _paylas() async {
    if (_secilenResim == null) return;

    setState(() => _yukleniyor = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      final dosyaAdi = '/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      // A) Resmi Storage'a Yükle ('posts' kovasına)
      await _supabase.storage.from('posts').upload(dosyaAdi, _secilenResim!);

      // B) Resmin Herkese Açık Linkini Al
      final resimUrl =
          _supabase.storage.from('posts').getPublicUrl(dosyaAdi);

      // C) Veritabanına Kaydet ('posts' tablosuna)
      final response = await _supabase.from('posts').insert({
        'user_id': userId,
        'image_url': resimUrl,
        'caption': _aciklamaController.text.trim(),
      }).select('id').single();

      final postId = response['id'] as int;

      // D) Etiketlenen kullanıcıları 'post_tags' tablosuna kaydet
      if (_seciliKullanicilar.isNotEmpty) {
        final tags = _seciliKullanicilar.map((kullanici) {
          return {
            'post_id': postId,
            'user_id': kullanici['id'] as String,
          };
        }).toList();

        await _supabase.from('post_tags').insert(tags);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gönderi başarıyla paylaşıldı! 🎉"),
            backgroundColor: _primaryRed,
          ),
        );
        Navigator.pop(context); // Sayfayı kapat
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata oluştu: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Yeni Gönderi",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // RESİM ALANI - MODERN TASARIM
                  GestureDetector(
                    onTap: _resimSec,
                    child: Container(
                      height: 350,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                        image: _secilenResim != null
                            ? DecorationImage(
                                image: FileImage(_secilenResim!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _secilenResim == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: _primaryRed.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_a_photo,
                                    size: 50,
                                    color: _primaryRed,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Fotoğraf Seç",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Galeriden veya kameradan seç",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // AÇIKLAMA ALANI
                  TextField(
                    controller: _aciklamaController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Açıklama yaz... (İsteğe bağlı)",
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: _primaryRed,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // KİŞİ ETİKETLEME ALANI
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.person_add_outlined,
                        color: _primaryRed,
                      ),
                      title: const Text(
                        "Kişileri Etiketle",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: _seciliKullanicilar.isEmpty
                          ? null
                          : Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  ...(_seciliKullanicilar.take(3).map((k) {
                                    final avatarUrl =
                                        k['avatar_url'] as String?;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.grey.shade200,
                                        backgroundImage: avatarUrl != null
                                            ? NetworkImage(avatarUrl)
                                            : const AssetImage(
                                                    'assets/images/mus.jpg')
                                                as ImageProvider,
                                      ),
                                    );
                                  })),
                                  if (_seciliKullanicilar.length > 3)
                                    Text(
                                      " +${_seciliKullanicilar.length - 3}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${_seciliKullanicilar.length} kişi etiketlendi",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: _kisileriEtiketle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // PAYLAŞ BUTONU - SAYFANIN ALTINDA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      (_secilenResim == null || _yukleniyor) ? null : _paylas,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryRed,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _yukleniyor
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          "Paylaş",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
