import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sohbet_sayfasi.dart';
// akis_sayfasi.dart importuna gerek kalmadı çünkü bu sayfada özel grid yapısı kullanıyoruz

class KullaniciProfili extends StatefulWidget {
  final String userId;

  const KullaniciProfili({super.key, required this.userId});

  @override
  State<KullaniciProfili> createState() => _KullaniciProfiliState();
}

class _KullaniciProfiliState extends State<KullaniciProfili> {
  // Profil Bilgileri
  String _adSoyad = ""; // Başta boş olsun, yükleniyor yazmasın
  String _bolum = "...";
  String _rol = "";
  String _bio = "";
  String? _avatarUrl;

  // İstatistikler
  int _gonderiSayisi = 0;
  int _takipciSayisi = 0;
  int _takipEdilenSayisi = 0;

  // Durumlar
  bool _yukleniyor = true;
  bool _takipEdiyor = false;
  bool _takipButonuYukleniyor = true; // Başta kontrol edene kadar loading dönsün

  static const Color _primaryRed = Color(0xFFE41D2D);
  final _supabase = Supabase.instance.client;

  // Veri Akışları
  late Future<List<Map<String, dynamic>>> _kullaniciPostlari;
  late Future<List<Map<String, dynamic>>> _etiketlenenPostlar;
  late Future<List<Map<String, dynamic>>> _kullaniciIlanlari;

  final Map<String, Color> _kategoriRenkleri = {
    'yazilim': Colors.blue,
    'tasarim': Colors.purple,
    'ozel_ders': Colors.orange,
    'ev_esya': Colors.green,
    'sosyal': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _sayfaVerileriniGetir();
  }

  // Tüm verileri paralel çekelim ki sayfa hızlı açılsın
  Future<void> _sayfaVerileriniGetir() async {
    // 1. Profil ve Takip Durumu
    await Future.wait([
      _profilVerisiniGetir(),
      _takipDurumunuKontrolEt(),
      _istatistikleriGetir(), // Sayıları çeken yeni fonksiyon
    ]);

    // 2. Listeleri Hazırla
    _kullaniciPostlari = _postlariGetir();
    _etiketlenenPostlar = _etiketlendigimPostlariGetir();
    _kullaniciIlanlari = _ilanlariGetir();
  }

  // --- YENİ EKLENEN: TAKİPÇİ SAYILARINI GETİR ---
  Future<void> _istatistikleriGetir() async {
    try {
      // Takipçi Sayısı (Beni takip edenler)
      final followers = await _supabase
          .from('followers')
          .select()
          .eq('following_id', widget.userId)
          .count(CountOption.exact);

      // Takip Edilen Sayısı (Benim takip ettiklerim)
      final following = await _supabase
          .from('followers')
          .select()
          .eq('follower_id', widget.userId)
          .count(CountOption.exact);

      if (mounted) {
        setState(() {
          _takipciSayisi = followers.count;
          _takipEdilenSayisi = following.count;
        });
      }
    } catch (e) {
      debugPrint("İstatistik hatası: $e");
    }
  }

  Future<void> _profilVerisiniGetir() async {
    try {
      final profileData = await _supabase.from('profiles').select().eq('id', widget.userId).single();
      final registryData = await _supabase.from('valid_registry').select().eq('user_id', widget.userId).maybeSingle();

      if (mounted) {
        setState(() {
          _adSoyad = profileData['full_name'] ?? "İsimsiz";
          _bio = profileData['bio'] ?? "";
          _avatarUrl = profileData['avatar_url'];
          if (registryData != null) {
            _bolum = registryData['department'] ?? "Bölüm Yok";
            _rol = registryData['role'] == 'student' ? 'Öğrenci' : 'Mezun';
          } else {
            _rol = "Misafir";
          }
          _yukleniyor = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _takipDurumunuKontrolEt() async {
    final myId = _supabase.auth.currentUser!.id;
    // Kendime bakıyorsam takip butonu yüklenmesin
    if (myId == widget.userId) {
      if(mounted) setState(() => _takipButonuYukleniyor = false);
      return;
    }

    try {
      final data = await _supabase.from('followers').select().eq('follower_id', myId).eq('following_id', widget.userId).maybeSingle();
      if (mounted) setState(() { _takipEdiyor = data != null; _takipButonuYukleniyor = false; });
    } catch (e) {
      if (mounted) setState(() => _takipButonuYukleniyor = false);
    }
  }

  // --- DÜZELTİLEN TAKİP İŞLEMİ (ANLIK GÜNCELLEME) ---
  Future<void> _takipIslemi() async {
    // Optimistic Update (Hemen arayüzü güncelle, sonra veritabanına yaz)
    setState(() {
      if (_takipEdiyor) {
        _takipciSayisi--; // Takibi bırakıyorsam sayıyı düşür
      } else {
        _takipciSayisi++; // Takip ediyorsam sayıyı artır
      }
      _takipEdiyor = !_takipEdiyor;
      _takipButonuYukleniyor = true; // İşlem bitene kadar loading
    });

    final myId = _supabase.auth.currentUser!.id;
    try {
      if (!_takipEdiyor) {
        // Az önce true yaptık ama buradaki mantık tersine döndüğü için !takipEdiyor siliyor demektir
        // (Mantık karışmasın: yukarıda state'i değiştirdik, burada veritabanı işlemi yapıyoruz)
        // Eğer şu an false ise (yani takipten çıktıysak)
        await _supabase.from('followers').delete().eq('follower_id', myId).eq('following_id', widget.userId);
      } else {
        // Eğer şu an true ise (takip ettiysek)
        await _supabase.from('followers').insert({'follower_id': myId, 'following_id': widget.userId});
      }
    } catch (e) {
      // Hata olursa eski haline döndür
      if (mounted) {
        setState(() {
          _takipEdiyor = !_takipEdiyor;
          if (_takipEdiyor) _takipciSayisi++; else _takipciSayisi--;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İşlem başarısız.")));
      }
    } finally {
      if(mounted) setState(() => _takipButonuYukleniyor = false);
    }
  }

  // Veri Çekme Metotları
  Future<List<Map<String, dynamic>>> _postlariGetir() async {
    final data = await _supabase.from('posts').select().eq('user_id', widget.userId).order('created_at', ascending: false);
    if (mounted) setState(() => _gonderiSayisi = data.length);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> _etiketlendigimPostlariGetir() async {
    final data = await _supabase.from('post_tags').select('posts(*)').eq('user_id', widget.userId);
    List<Map<String, dynamic>> temizListe = [];
    for (var item in data) { if (item['posts'] != null) temizListe.add(item['posts'] as Map<String, dynamic>); }
    return temizListe;
  }

  Future<List<Map<String, dynamic>>> _ilanlariGetir() async {
    final data = await _supabase.from('collab_posts').select().eq('owner_id', widget.userId).eq('is_active', true).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _basvur(int postId) async {
    try {
      await _supabase.from('collab_requests').insert({'post_id': postId, 'applicant_id': _supabase.auth.currentUser!.id});
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İlgilendiğini belirttin! ✋")));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Zaten başvurdun.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = _supabase.auth.currentUser!.id;
    final bool kendiProfilim = myId == widget.userId;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_adSoyad.isEmpty ? "Profil" : _adSoyad, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: _primaryRed))
          : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profil Resmi
            Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200, width: 1),
                image: _avatarUrl != null
                    ? DecorationImage(image: NetworkImage(_avatarUrl!), fit: BoxFit.cover)
                    : const DecorationImage(image: AssetImage('assets/images/mus.jpg'), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),

            Text(_adSoyad, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 4),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _rol == 'Öğrenci' ? Colors.blue.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _rol == 'Öğrenci' ? Colors.blue.shade200 : Colors.orange.shade200),
              ),
              child: Text("$_rol • $_bolum", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _rol == 'Öğrenci' ? Colors.blue.shade800 : Colors.orange.shade800)),
            ),

            if (_bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 30), child: Text(_bio, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade800, fontSize: 14))),
            ],

            const SizedBox(height: 20),

            // İSTATİSTİKLER (Artık gerçek veriler)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem("Gönderi", _gonderiSayisi.toString()),
                _buildStatItem("Takipçi", _takipciSayisi.toString()), // DÜZELTİLDİ
                _buildStatItem("Takip", _takipEdilenSayisi.toString()), // DÜZELTİLDİ
              ],
            ),

            const SizedBox(height: 20),

            // TAKİP VE MESAJ BUTONLARI (Kendi profilim değilse göster)
            if (!kendiProfilim)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _takipButonuYukleniyor ? null : _takipIslemi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _takipEdiyor ? Colors.grey.shade200 : _primaryRed,
                          foregroundColor: _takipEdiyor ? Colors.black : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _takipButonuYukleniyor
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_takipEdiyor ? "Takibi Bırak" : "Takip Et"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => SohbetSayfasi(aliciId: widget.userId, aliciAdi: _adSoyad)));
                        },
                        style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: BorderSide(color: Colors.grey.shade300)),
                        child: const Text("Mesaj", style: TextStyle(color: Colors.black)),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    indicatorColor: _primaryRed, labelColor: _primaryRed, unselectedLabelColor: Colors.grey,
                    tabs: [Tab(icon: Icon(Icons.grid_on)), Tab(icon: Icon(Icons.assignment_ind_outlined)), Tab(icon: Icon(Icons.handshake))],
                  ),
                  SizedBox(
                    height: 400,
                    child: TabBarView(
                      children: [
                        _buildPhotoGrid(_kullaniciPostlari, "Henüz gönderisi yok."),
                        _buildPhotoGrid(_etiketlenenPostlar, "Henüz etiketlenmemiş."),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _kullaniciIlanlari,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _primaryRed));
                            final jobs = snapshot.data ?? [];
                            if (jobs.isEmpty) return const Center(child: Text("Henüz aktif ilanı yok.", style: TextStyle(color: Colors.grey)));
                            return ListView.separated(
                              padding: const EdgeInsets.all(16), itemCount: jobs.length, separatorBuilder: (ctx, i) => const Divider(),
                              itemBuilder: (context, index) {
                                final job = jobs[index];
                                final color = _kategoriRenkleri[job['category']] ?? Colors.blue;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(Icons.work, color: color, size: 20)),
                                  title: Text(job['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(job['description'], maxLines: 1, overflow: TextOverflow.ellipsis),
                                  trailing: ElevatedButton(onPressed: () => _basvur(job['id']), style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, visualDensity: VisualDensity.compact, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text("Başvur", style: TextStyle(fontSize: 12))),
                                );
                              },
                            );
                          },
                        ),
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

  Widget _buildPhotoGrid(Future<List<Map<String, dynamic>>> future, String emptyMessage) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20.0), child: CircularProgressIndicator(color: _primaryRed)));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text(emptyMessage, style: const TextStyle(color: Colors.grey)));
        final posts = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(2),
          itemCount: posts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
          itemBuilder: (context, index) => Image.network(posts[index]['image_url'], fit: BoxFit.cover),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}