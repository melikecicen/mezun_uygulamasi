import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sohbet_sayfasi.dart';

class MesajKutusu extends StatefulWidget {
  const MesajKutusu({super.key});

  @override
  State<MesajKutusu> createState() => _MesajKutusuState();
}

class _MesajKutusuState extends State<MesajKutusu> {
  final _myId = Supabase.instance.client.auth.currentUser!.id;
  bool _yukleniyor = true;
  static const Color _primaryRed = Color(0xFFE41D2D);

  List<_SohbetOzet> _sohbetler = [];

  @override
  void initState() {
    super.initState();
    _sohbetleriGetir();
  }

  Future<void> _sohbetleriGetir() async {
    setState(() => _yukleniyor = true);
    try {
      final supabase = Supabase.instance.client;
      final mesajlar = await supabase
          .from('messages')
          .select('sender_id, receiver_id, content, created_at, is_read')
          .or('sender_id.eq.$_myId,receiver_id.eq.$_myId')
          .order('created_at', ascending: false);

      final Map<String, Map<String, dynamic>> ozetMap = {};
      final List<String> siraliKullaniciIdleri = [];

      for (final msg in mesajlar) {
        final otherId =
            msg['sender_id'] == _myId ? msg['receiver_id'] as String : msg['sender_id'] as String;
        if (ozetMap.containsKey(otherId)) continue;

        final createdAtRaw = msg['created_at'];
        DateTime? createdAt;
        if (createdAtRaw is String) {
          createdAt = DateTime.tryParse(createdAtRaw);
        } else if (createdAtRaw is DateTime) {
          createdAt = createdAtRaw;
        }

        ozetMap[otherId] = {
          'content': (msg['content'] as String?) ?? '',
          'createdAt': createdAt ?? DateTime.now(),
          'unread': msg['receiver_id'] == _myId && !(msg['is_read'] as bool? ?? false),
        };
        siraliKullaniciIdleri.add(otherId);
      }

      Map<String, Map<String, dynamic>> profilMap = {};
      if (siraliKullaniciIdleri.isNotEmpty) {
        final profiller = await supabase
            .from('profiles')
            .select('id, full_name, avatar_url')
            .inFilter('id', siraliKullaniciIdleri);
        profilMap = {
          for (final kayit in profiller.cast<Map<String, dynamic>>())
            kayit['id'] as String: kayit,
        };
      }

      final sohbetler = siraliKullaniciIdleri.map((id) {
        final ozet = ozetMap[id]!;
        final profil = profilMap[id];
        final ad = (profil?['full_name'] as String?)?.trim();
        final avatar = profil?['avatar_url'] as String?;

        return _SohbetOzet(
          userId: id,
          fullName: (ad != null && ad.isNotEmpty) ? ad : "İsimsiz",
          avatarUrl: (avatar != null && avatar.isNotEmpty) ? avatar : null,
          lastMessage: ozet['content'] as String,
          lastMessageTime: ozet['createdAt'] as DateTime,
          hasUnread: ozet['unread'] as bool,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _sohbetler = sohbetler;
          _yukleniyor = false;
        });
      }
    } catch (e) {
      debugPrint("Sohbet geçmişi hatası: $e");
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mesajlar",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: _primaryRed))
          : _sohbetler.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text(
                        "Henüz kimseyle konuşmadın.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: _primaryRed,
                  onRefresh: _sohbetleriGetir,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _sohbetler.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 80),
                    itemBuilder: (context, index) {
                      final sohbet = _sohbetler[index];
                      return ListTile(
                        onTap: () => _sohbeteGit(sohbet),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: _Avatar(
                          avatarUrl: sohbet.avatarUrl,
                          fullName: sohbet.fullName,
                        ),
                        title: Text(
                          sohbet.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          _mesajOnizleme(sohbet.lastMessage),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                sohbet.hasUnread ? FontWeight.w700 : FontWeight.w400,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _zamanFormatla(sohbet.lastMessageTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: sohbet.hasUnread
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            if (sohbet.hasUnread)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: _primaryRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Future<void> _sohbeteGit(_SohbetOzet sohbet) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SohbetSayfasi(
          aliciId: sohbet.userId,
          aliciAdi: sohbet.fullName,
        ),
      ),
    );
    if (mounted) _sohbetleriGetir();
  }

  static String _mesajOnizleme(String content) {
    if (_fotoMesajiMi(content)) return "📷 Fotoğraf gönderdi";
    if (content.trim().isEmpty) return "Mesaj içeriği yok";
    if (content.startsWith('Bir gönderi paylaştı:')) return "🔁 Gönderi paylaştı";
    return content;
  }

  static String _zamanFormatla(DateTime tarih) {
    final now = DateTime.now();
    final bugun = DateTime(now.year, now.month, now.day);
    final tarihGun = DateTime(tarih.year, tarih.month, tarih.day);
    final fark = bugun.difference(tarihGun).inDays;

    if (fark == 0) {
      final saat = tarih.hour.toString().padLeft(2, '0');
      final dakika = tarih.minute.toString().padLeft(2, '0');
      return "$saat:$dakika";
    }
    if (fark == 1) return "Dün";
    if (fark < 7 && fark > 1) {
      const gunler = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];
      return gunler[tarih.weekday % 7];
    }
    final gun = tarih.day.toString().padLeft(2, '0');
    final ay = tarih.month.toString().padLeft(2, '0');
    return "$gun.$ay";
  }

  static bool _fotoMesajiMi(String content) {
    final lower = content.toLowerCase();
    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.gif') ||
        lower.contains('/posts/');
  }
}

class _SohbetOzet {
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool hasUnread;

  _SohbetOzet({
    required this.userId,
    required this.fullName,
    required this.avatarUrl,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.hasUnread,
  });
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String fullName;
  const _Avatar({required this.avatarUrl, required this.fullName});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    }

    final initials = _basHarfleriAl(fullName);
    final renk = _avatarRengi(fullName);
    return CircleAvatar(
      radius: 26,
      backgroundColor: renk.withOpacity(0.15),
      child: Text(
        initials,
        style: TextStyle(
          color: renk,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static String _basHarfleriAl(String name) {
    final parts = name.trim().split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return "?";
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  static Color _avatarRengi(String name) {
    const colors = [
      Color(0xFFE41D2D),
      Color(0xFF1E88E5),
      Color(0xFFF4511E),
      Color(0xFF8E24AA),
      Color(0xFF00897B),
      Color(0xFF6D4C41),
    ];
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }
}