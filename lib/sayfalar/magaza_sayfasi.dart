import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<_MagazaSayfasiState> magazaKey = GlobalKey<_MagazaSayfasiState>();

class MagazaSayfasi extends StatefulWidget {
  const MagazaSayfasi({super.key});

  @override
  State<MagazaSayfasi> createState() => _MagazaSayfasiState();
}

class _MagazaSayfasiState extends State<MagazaSayfasi> {
  final _supabase = Supabase.instance.client;
  static const Color _primaryRed = Color(0xFFE41D2D);
  int _kullaniciPuani = 0;
  bool _nakitModu = false; // false = Puanlı İndirim, true = Nakit
  List<Map<String, dynamic>> _sepet = [];

  // HARDCODED ÜRÜNLER (Supabase kotası yemez, resimli)
  final List<Map<String, dynamic>> _urunler = [
    {
      'id': 1,
      'title': 'MAUN Kupa Bardak',
      'fiyat_tl': 200,
      'fiyat_puan': 500,
      'indirimli_tl': 50,
      'image': 'assets/images/kupa_bardak.png',
      'desc': 'Logolu porselen kupa.'
    },
    {
      'id': 2,
      'title': 'Sekiz Cafe Kahve İndirimi',
      'fiyat_tl': 50,
      'fiyat_puan': 100,
      'indirimli_tl': 10,
      'image': 'assets/images/images.jpg',
      'desc': 'Kantin kahvelerinde geçerli.'
    },
    {
      'id': 3,
      'title': 'MAUN sweatshirt',
      'fiyat_tl': 300,
      'fiyat_puan': 500,
      'indirimli_tl': 100,
      'image': 'assets/images/sweatshirt.png',
      'desc': 'S-M-L Beden seçenekli.'
    },
    {
      'id': 4,
      'title': 'MAUN şapka',
      'fiyat_tl': 150,
      'fiyat_puan': 150,
      'indirimli_tl': 30,
      'image': 'assets/images/sapka.png',
      'desc': 'Kampüs kırtasiyesinde geçerli.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _puanGetir();
  }

  Future<void> _puanGetir() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final data = await _supabase.from('profiles').select('points').eq('id', user.id).single();
      if (mounted) setState(() => _kullaniciPuani = data['points'] ?? 0);
    }
  }

  Future<void> refreshPoints() async {
    await _puanGetir();
  }

  void _sepeteEkle(Map<String, dynamic> urun) {
    final sepetUrunu = {
      ...urun,
      'mod': _nakitModu ? 'nakit' : 'puanli',
    };

    setState(() {
      _sepet.add(sepetUrunu);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${urun['title']} sepete eklendi!"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _sepettenCikar(int index) {
    setState(() {
      _sepet.removeAt(index);
    });
  }

  void _sepetiGoster() {
    if (_sepet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sepetiniz boş!")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 16),
            const Text(
              "Sepetim",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _sepet.length,
                itemBuilder: (context, index) {
                  final urun = _sepet[index];
                  final mod = urun['mod'] as String;
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        urun['image'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    title: Text(urun['title']),
                    subtitle: Text(
                      mod == 'nakit'
                          ? "${urun['fiyat_tl']} TL"
                          : "${urun['fiyat_puan']} Puan + ${urun['indirimli_tl']} TL",
                      style: const TextStyle(
                        color: _primaryRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _sepettenCikar(index),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Toplam:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _toplamHesapla(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _primaryRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _odemeyeGec,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Ödemeye Geç",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  String _toplamHesapla() {
    int toplamPuan = 0;
    int toplamTL = 0;

    for (var urun in _sepet) {
      if (urun['mod'] == 'nakit') {
        toplamTL += urun['fiyat_tl'] as int;
      } else {
        toplamPuan += urun['fiyat_puan'] as int;
        toplamTL += urun['indirimli_tl'] as int;
      }
    }

    if (toplamPuan > 0 && toplamTL > 0) {
      return "$toplamPuan P + $toplamTL TL";
    } else if (toplamPuan > 0) {
      return "$toplamPuan Puan";
    } else {
      return "$toplamTL TL";
    }
  }

  void _odemeyeGec() {
    Navigator.pop(context); // Sepet bottom sheet'i kapat

    // Puan kontrolü
    int toplamPuan = 0;
    for (var urun in _sepet) {
      if (urun['mod'] == 'puanli') {
        toplamPuan += urun['fiyat_puan'] as int;
      }
    }

    if (toplamPuan > 0 && _kullaniciPuani < toplamPuan) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Puanınız yetersiz!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Ödeme ekranını göster
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OdemeEkrani(
        sepet: _sepet,
        kullaniciPuani: _kullaniciPuani,
        onOdemeTamamlandi: _odemeTamamlandi,
      ),
    );
  }

  Future<void> _odemeTamamlandi(int harcananPuan) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final yeniPuan = _kullaniciPuani - harcananPuan;

      await _supabase.from('profiles').update({'points': yeniPuan}).eq('id', userId);

      setState(() {
        _kullaniciPuani = yeniPuan;
        _sepet.clear();
      });

      if (mounted) {
        Navigator.pop(context); // Ödeme ekranını kapat
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Tebrikler! 🎉"),
            content: const Text("Siparişiniz alındı. Teslim almak için öğrenci numaranı görevliye göster."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Tamam"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hata oluştu.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MAUN Store 🛍️", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
                onPressed: _sepetiGoster,
              ),
              if (_sepet.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: _primaryRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      "${_sepet.length}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_primaryRed, Colors.orange]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                const Text("Mevcut Puanın", style: TextStyle(color: Colors.white70)),
                Text(
                  "$_kullaniciPuani P",
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Fiyatlandırma Modu Toggle
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildModButonu(
                    label: "Nakit (TL)",
                    isSelected: _nakitModu,
                    onTap: () => setState(() => _nakitModu = true),
                  ),
                ),
                Expanded(
                  child: _buildModButonu(
                    label: "Puanlı İndirim",
                    isSelected: !_nakitModu,
                    onTap: () => setState(() => _nakitModu = false),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _urunler.length,
              itemBuilder: (context, index) {
                final urun = _urunler[index];
                return _buildUrunKarti(urun);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModButonu({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildUrunKarti(Map<String, dynamic> urun) {
    final String fiyatGosterimi;
    if (_nakitModu) {
      fiyatGosterimi = "${urun['fiyat_tl']} TL";
    } else {
      fiyatGosterimi = "${urun['fiyat_puan']} P + ${urun['indirimli_tl']} TL";
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: _buildUrunGorsel(urun['image']),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urun['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  fiyatGosterimi,
                  style: const TextStyle(
                    color: _primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _sepeteEkle(urun),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Sepete Ekle",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrunGorsel(String imagePath) {
    final bool isAsset = imagePath.startsWith('assets/');
    if (isAsset) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey,
          child: const Icon(Icons.image_not_supported, color: Colors.white),
        ),
      );
    }
    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey,
        child: const Icon(Icons.image_not_supported, color: Colors.white),
      ),
    );
  }
}

// Ödeme Ekranı Widget'ı
class OdemeEkrani extends StatefulWidget {
  final List<Map<String, dynamic>> sepet;
  final int kullaniciPuani;
  final Function(int) onOdemeTamamlandi;

  const OdemeEkrani({
    super.key,
    required this.sepet,
    required this.kullaniciPuani,
    required this.onOdemeTamamlandi,
  });

  @override
  State<OdemeEkrani> createState() => _OdemeEkraniState();
}

class _OdemeEkraniState extends State<OdemeEkrani> {
  final _formKey = GlobalKey<FormState>();
  final _kartNoController = TextEditingController();
  final _sktController = TextEditingController();
  final _cvcController = TextEditingController();
  bool _odemeYapiliyor = false;
  static const Color _primaryRed = Color(0xFFE41D2D);

  @override
  void dispose() {
    _kartNoController.dispose();
    _sktController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  int _harcananPuanHesapla() {
    int toplam = 0;
    for (var urun in widget.sepet) {
      if (urun['mod'] == 'puanli') {
        toplam += urun['fiyat_puan'] as int;
      }
    }
    return toplam;
  }

  String _toplamHesapla() {
    int toplamPuan = 0;
    int toplamTL = 0;

    for (var urun in widget.sepet) {
      if (urun['mod'] == 'nakit') {
        toplamTL += urun['fiyat_tl'] as int;
      } else {
        toplamPuan += urun['fiyat_puan'] as int;
        toplamTL += urun['indirimli_tl'] as int;
      }
    }

    if (toplamPuan > 0 && toplamTL > 0) {
      return "$toplamPuan P + $toplamTL TL";
    } else if (toplamPuan > 0) {
      return "$toplamPuan Puan";
    } else {
      return "$toplamTL TL";
    }
  }

  void _odemeTamamla() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _odemeYapiliyor = true);

    // Simüle edilmiş ödeme işlemi (2 saniye bekle)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final harcananPuan = _harcananPuanHesapla();
        widget.onOdemeTamamlandi(harcananPuan);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final harcananPuan = _harcananPuanHesapla();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
          const SizedBox(height: 16),
          const Text(
            "Ödeme",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sipariş Özeti
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Sipariş Özeti",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          ...widget.sepet.map((urun) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        urun['title'],
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    Text(
                                      urun['mod'] == 'nakit'
                                          ? "${urun['fiyat_tl']} TL"
                                          : "${urun['fiyat_puan']} P + ${urun['indirimli_tl']} TL",
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _primaryRed,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Toplam:",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                _toplamHesapla(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: _primaryRed,
                                ),
                              ),
                            ],
                          ),
                          if (harcananPuan > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                "Harcanacak Puan: $harcananPuan P",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Kart Bilgileri",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _kartNoController,
                      decoration: InputDecoration(
                        labelText: "Kart Numarası",
                        hintText: "1234 5678 9012 3456",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.credit_card),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Kart numarası gerekli";
                        }
                        if (value.replaceAll(' ', '').length < 16) {
                          return "Geçerli bir kart numarası girin";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _sktController,
                            decoration: InputDecoration(
                              labelText: "Son Kullanma Tarihi",
                              hintText: "MM/YY",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.calendar_today),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "SKT gerekli";
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _cvcController,
                            decoration: InputDecoration(
                              labelText: "CVC",
                              hintText: "123",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.lock),
                            ),
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "CVC gerekli";
                              }
                              if (value.length < 3) {
                                return "Geçerli bir CVC girin";
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _odemeYapiliyor ? null : _odemeTamamla,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _odemeYapiliyor
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        "Ödemeyi Tamamla",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
