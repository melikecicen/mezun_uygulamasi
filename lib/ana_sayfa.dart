import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Sayfaları import ediyoruz
import 'sayfalar/akis_sayfasi.dart';
import 'sayfalar/kampus_isbirligi.dart';
import 'sayfalar/magaza_sayfasi.dart'; // Mağazayı buraya ekledik
import 'sayfalar/duyurular_sayfasi.dart';
import 'sayfalar/profil_sayfasi.dart';
import 'sayfalar/arama_sayfasi.dart';
import 'sayfalar/ayarlar_sayfasi.dart';
import 'sayfalar/paylasim_sayfasi.dart';
import 'sayfalar/mesaj_kutusu.dart';

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  int _seciliIndeks = 0;
  static const Color _primaryRed = Color(0xFFE41D2D);
  static const Color _textDark = Color(0xFF1A1A1A);
  late final String _myId;
  late final Stream<int> _unreadCountStream;
  late final List<Widget> _sayfalar;

  // Başlık Yönetimi
  String _baslikGetir() {
    switch (_seciliIndeks) {
      case 0: return "MAUN Sosyal";
      case 1: return "Kampüs İşbirliği";
      case 2: return ""; // Mağaza kendi başlığına sahip olduğu için burayı boş bırakıyoruz
      case 3: return "Duyurular";
      case 4: return "Profilim";
      default: return "";
    }
  }

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _myId = user?.id ?? '';
    _unreadCountStream = _myId.isEmpty
        ? Stream<int>.value(0)
        : Supabase.instance.client
            .from('messages')
            .stream(primaryKey: ['id'])
            .map((rows) => rows
                .where((row) =>
                    row['receiver_id'] == _myId &&
                    !(row['is_read'] as bool? ?? false))
                .length);
    _sayfalar = [
      const AkisSayfasi(),        // 0
      const KampusIsbirligi(),    // 1
      MagazaSayfasi(key: magazaKey),      // 2 (Yeni eklenen)
      const DuyurularSayfasi(),   // 3
      const ProfilSayfasi(),      // 4
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Eğer Mağaza sayfasındaysak (index 2), AnaSayfa'nın Appbar'ını gizleyelim.
    // Çünkü Mağaza sayfasının içinde zaten kendi Appbar'ı var. Çift başlık olmasın.
    final bool appbarGoster = _seciliIndeks != 2;

    return Scaffold(
      backgroundColor: Colors.white,

      // APPBAR (Sadece Mağaza dışındaki sayfalarda görünür)
      appBar: appbarGoster ? AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Text(
          _baslikGetir(),
          style: TextStyle(
            color: _seciliIndeks == 0 ? _primaryRed : _textDark,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            fontSize: 24,
          ),
        ),
        actions: [
          _buildActionButton(Icons.search, "Ara", () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AramaSayfasi()));
          }),
          _buildMessageButton(),

          // Paylaş butonu sadece Akış'ta (Index 0)
          if (_seciliIndeks == 0)
            _buildActionButton(Icons.add_box_outlined, "Paylaş", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PaylasimSayfasi()));
            }),

          // Ayarlar butonu sadece Profil'de (Index 4)
          if (_seciliIndeks == 4)
            _buildActionButton(Icons.settings_outlined, "Ayarlar", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AyarlarSayfasi()));
            }),

          const SizedBox(width: 8),
        ],
      ) : null, // Mağaza sayfasındaysak AppBar null olur (görünmez)

      body: _sayfalar[_seciliIndeks],

      // ALT MENÜ (5 BUTONLU)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
            ]
        ),
        child: NavigationBar(
          selectedIndex: _seciliIndeks,
          onDestinationSelected: (index) {
            if (index == 2) {
              magazaKey.currentState?.refreshPoints();
            }
            setState(() => _seciliIndeks = index);
          },
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: _primaryRed.withOpacity(0.1),
          height: 70,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: _primaryRed),
              label: 'Akış',
            ),
            NavigationDestination(
              icon: Icon(Icons.handshake_outlined),
              selectedIcon: Icon(Icons.handshake, color: _primaryRed),
              label: 'İşbirliği',
            ),
            // --- ORTADAKİ MAĞAZA İKONU ---
            NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag, color: _primaryRed),
              label: 'Mağaza',
            ),
            // -----------------------------
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications_rounded, color: _primaryRed),
              label: 'Duyuru',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded, color: _primaryRed),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: Colors.black87, size: 26),
      tooltip: tooltip,
      onPressed: onPressed,
      splashRadius: 24,
    );
  }

  Widget _buildMessageButton() {
    return StreamBuilder<int>(
      stream: _unreadCountStream,
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildActionButton(Icons.maps_ugc_rounded, "Mesajlar", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MesajKutusu()),
                );
              }),
              if (unread > 0)
                Positioned(
                  right: 6,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: _primaryRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unread > 99 ? '99+' : unread.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}