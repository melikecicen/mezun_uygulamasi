import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'kullanici_profili.dart';

class AramaSayfasi extends StatefulWidget {
  const AramaSayfasi({super.key});

  @override
  State<AramaSayfasi> createState() => _AramaSayfasiState();
}

class _AramaSayfasiState extends State<AramaSayfasi> {
  final _aramaController = TextEditingController();
  List<Map<String, dynamic>> _sonuclar = [];
  bool _yukleniyor = false;
  bool _aramaYapildi = false; // Kullanıcı arama yaptı mı?
  static const Color _primaryRed = Color(0xFFE41D2D);
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _aramaController.addListener(() {
      // Text değiştiğinde suffixIcon'u güncelle
      setState(() {});
    });
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  void _aramaTemizle() {
    _aramaController.clear();
    setState(() {
      _sonuclar = [];
      _aramaYapildi = false;
    });
  }

  Future<void> _kullaniciAra(String arananKelime) async {
    if (arananKelime.trim().isEmpty) {
      setState(() {
        _sonuclar = [];
        _aramaYapildi = false;
        _yukleniyor = false;
      });
      return;
    }

    setState(() {
      _yukleniyor = true;
      _aramaYapildi = true;
    });

    try {
      final myUserId = _supabase.auth.currentUser!.id;

      // 1. PROFILES TABLOSUNDA ARA
      dynamic sorgu = _supabase
          .from('profiles')
          .select('id, full_name, avatar_url')
          .neq('id', myUserId);

      if (arananKelime.trim().isNotEmpty) {
        sorgu = sorgu.ilike('full_name', '%${arananKelime.trim()}%');
      }

      final List<dynamic> profilesData = await sorgu;

      if (profilesData.isEmpty) {
        if (mounted) setState(() { _sonuclar = []; _yukleniyor = false; });
        return;
      }

      // 2. BULUNAN KİŞİLERİN ID'LERİNİ AL
      final userIds = profilesData.map((p) => p['id'] as String).toList();

      // 3. BÖLÜM BİLGİLERİNİ ÇEK (DÜZELTİLEN KISIM BURASI)
      List<dynamic> registryData = [];
      try {
        registryData = await _supabase
            .from('valid_registry')
            .select('user_id, department, role')
            .filter('user_id', 'in', userIds); // .in_ YERİNE .filter KULLANDIK
      } catch (e) {
        debugPrint("Bölüm bilgisi çekilemedi (Önemli değil): $e");
      }

      // 4. VERİLERİ EŞLEŞTİR
      final Map<String, Map<String, dynamic>> registryMap = {};
      for (var reg in registryData) {
        registryMap[reg['user_id'] as String] = reg as Map<String, dynamic>;
      }

      final List<Map<String, dynamic>> birlesikSonuclar = [];
      for (var profile in profilesData) {
        final userId = profile['id'] as String;
        final registry = registryMap[userId];

        birlesikSonuclar.add({
          ...profile as Map<String, dynamic>,
          // Eğer registry verisi yoksa varsayılan değerleri ata
          'valid_registry': registry ?? {'department': 'Bölüm Belirtilmemiş', 'role': 'student'},
        });
      }

      if (mounted) {
        setState(() {
          _sonuclar = birlesikSonuclar;
          _yukleniyor = false;
        });
      }
    } catch (e) {
      debugPrint("Genel Arama Hatası: $e");
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // MODERN ARAMA KUTUSU
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _aramaController,
                onChanged: (deger) => _kullaniciAra(deger),
                onSubmitted: (deger) => _kullaniciAra(deger),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: "Öğrenci veya Mezun Ara...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _aramaController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: _aramaTemizle,
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: _primaryRed.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),

            // SONUÇ LİSTESİ
            Expanded(
              child: _yukleniyor
                  ? const Center(
                      child: CircularProgressIndicator(color: _primaryRed),
                    )
                  : !_aramaYapildi
                      ? _buildEmptyState()
                      : _sonuclar.isEmpty
                          ? _buildNoResultsState()
                          : _buildResultsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            "İnsanları Keşfet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Öğrenci veya mezun ara...",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            "Kullanıcı bulunamadı",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Farklı bir arama terimi deneyin",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _sonuclar.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final user = _sonuclar[index];
        final profile = user;
        final registry = user['valid_registry'] as Map<String, dynamic>? ?? <String, dynamic>{};

        final adSoyad = profile['full_name'] ?? "İsimsiz";
        final bolum = registry['department'] ?? "Bölüm Yok";
        final role = registry['role'] ?? 'student';
        final isStudent = role == 'student';
        final roleText = isStudent ? 'Öğrenci' : 'Mezun';
        final userId = profile['id'] as String;
        final avatarUrl = profile['avatar_url'] as String?;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Text(
                    adSoyad.isNotEmpty
                        ? adSoyad[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          title: Text(
            adSoyad,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isStudent ? Colors.blue.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  roleText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isStudent ? Colors.blue.shade800 : Colors.orange.shade800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bolum,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => KullaniciProfili(userId: userId),
              ),
            );
          },
        );
      },
    );
  }
}