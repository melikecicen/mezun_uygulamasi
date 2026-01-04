import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class SohbetSayfasi extends StatefulWidget {
  final String aliciId;
  final String aliciAdi;

  const SohbetSayfasi({super.key, required this.aliciId, required this.aliciAdi});

  @override
  State<SohbetSayfasi> createState() => _SohbetSayfasiState();
}

class _SohbetSayfasiState extends State<SohbetSayfasi> {
  final _mesajController = TextEditingController();
  final _myId = Supabase.instance.client.auth.currentUser!.id;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  StreamSubscription<List<Map<String, dynamic>>>? _okunmamisDinleyici;

  bool _emojiGoster = false;
  static const Color _primaryRed = Color(0xFFE41D2D);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _emojiGoster = false);
      }
    });
    _okunmamisMesajlariTakipEt();
  }

  @override
  void dispose() {
    _okunmamisDinleyici?.cancel();
    _mesajController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _mesajGonder() async {
    final text = _mesajController.text.trim();
    if (text.isEmpty) return;

    try {
      await Supabase.instance.client.from('messages').insert({
        'sender_id': _myId,
        'receiver_id': widget.aliciId,
        'content': text,
        'is_read': false,
      });
      _mesajController.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mesaj gitmedi.")));
    }
  }

  // RESİM URL'Sİ KONTROLÜ
  bool _resimUrlMi(String? text) {
    if (text == null || text.isEmpty) return false;
    final lowerText = text.toLowerCase();
    return (lowerText.startsWith('http://') || lowerText.startsWith('https://')) &&
        (lowerText.contains('.jpg') || lowerText.contains('.jpeg') || 
         lowerText.contains('.png') || lowerText.contains('.gif') ||
         lowerText.contains('/posts/') || lowerText.contains('/storage/'));
  }

  // MESAJ İÇERİĞİNDEN RESİM URL'Sİ ÇIKARMA
  String? _resimUrlCikar(String content) {
    final lines = content.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (_resimUrlMi(trimmed)) {
        return trimmed;
      }
    }
    return null;
  }

  // PAYLAŞILAN GÖNDERİ Mİ KONTROLÜ
  bool _paylasilanGonderiMi(String content) {
    return content.startsWith('Bir gönderi paylaştı:');
  }

  // PAYLAŞILAN GÖNDERİDEN CAPTION ÇIKARMA
  String? _captionCikar(String content) {
    if (!_paylasilanGonderiMi(content)) return null;
    final lines = content.split('\n');
    // Format: "Bir gönderi paylaştı:\ncaption\nURL"
    // İkinci satır caption olabilir (eğer URL değilse)
    if (lines.length > 1) {
      final potentialCaption = lines[1].trim();
      // Eğer bu satır URL değilse, caption'dır
      if (!_resimUrlMi(potentialCaption) && potentialCaption.isNotEmpty) {
        return potentialCaption;
      }
    }
    return null;
  }

// BASİTLEŞTİRİLMİŞ VE HATASIZ EMOJİ KONTROLÜ
  bool _sadeceEmojiMi(String text) {
    // 1. Eğer mesaj çok uzunsa kesinlikle yazı vardır, normal göster.
    if (text.length > 5) return false;

    // 2. İçinde harf veya rakam var mı diye bakıyoruz.
    // (Türkçe karakterler dahil a-z, A-Z, 0-9)
    bool harfVeyaRakamVar = RegExp(r'[a-zA-Z0-9ğüşıöçĞÜŞİÖÇ]').hasMatch(text);

    // 3. Eğer harf veya rakam YOKSA, demek ki sadece emoji (veya noktalama işareti) vardır.
    // O zaman KOCAMAN göster (True).
    return !harfVeyaRakamVar;
  }

  void _okunmamisMesajlariTakipEt() {
    _okunmamisDinleyici = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .listen((rows) async {
      final ids = rows
          .where((row) =>
              row['sender_id'] == widget.aliciId &&
              row['receiver_id'] == _myId &&
              !(row['is_read'] as bool? ?? false))
          .map<int?>((row) => row['id'] as int?)
          .whereType<int>()
          .toList(growable: false);
      if (ids.isEmpty) return;
      try {
        await Supabase.instance.client
            .from('messages')
            .update({'is_read': true})
            .inFilter('id', ids);
      } catch (_) {}
    });
  }
  @override
  Widget build(BuildContext context) {
    final mesajStream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((items) => items.where((msg) =>
    (msg['sender_id'] == _myId && msg['receiver_id'] == widget.aliciId) ||
        (msg['sender_id'] == widget.aliciId && msg['receiver_id'] == _myId)
    ).toList());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
        title: _AppBarProfilBilgisi(aliciId: widget.aliciId, aliciAdi: widget.aliciAdi),
      ),
      body: PopScope(
        canPop: !_emojiGoster,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_emojiGoster) {
            setState(() => _emojiGoster = false);
          }
        },
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: mesajStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _primaryRed));
                  final mesajlar = snapshot.data!;
                  if (mesajlar.isEmpty) return Center(child: Text("Henüz mesaj yok.\nİlk selamı sen ver! 👋", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400)));

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    itemCount: mesajlar.length,
                    itemBuilder: (context, index) {
                      final msg = mesajlar[index];
                      final benYazdim = msg['sender_id'] == _myId;
                      final icerik = msg['content'] as String;
                      final stickerGibi = _sadeceEmojiMi(icerik);
                      final resimUrl = _resimUrlCikar(icerik);
                      final paylasilanGonderi = _paylasilanGonderiMi(icerik);
                      final caption = _captionCikar(icerik);

                      // Resim içeren mesaj
                      if (resimUrl != null && !stickerGibi) {
                        return Align(
                          alignment: benYazdim ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: benYazdim ? _primaryRed : Colors.grey.shade200,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: benYazdim ? const Radius.circular(16) : const Radius.circular(4),
                                bottomRight: benYazdim ? const Radius.circular(4) : const Radius.circular(16),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (paylasilanGonderi)
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                                    child: Text(
                                      "Bir gönderi paylaştı:",
                                      style: TextStyle(
                                        color: benYazdim ? Colors.white.withOpacity(0.9) : Colors.black87,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: benYazdim ? const Radius.circular(16) : Radius.zero,
                                    bottomRight: benYazdim ? Radius.zero : const Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    resimUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 250,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      height: 200,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                    ),
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 200,
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(_primaryRed),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                if (caption != null && caption.isNotEmpty && paylasilanGonderi)
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                                    child: Text(
                                      caption,
                                      style: TextStyle(
                                        color: benYazdim ? Colors.white : Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Normal metin veya emoji mesajı
                      return Align(
                        alignment: benYazdim ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: stickerGibi 
                              ? const EdgeInsets.all(0) 
                              : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: stickerGibi
                              ? null
                              : BoxDecoration(
                                  color: benYazdim ? _primaryRed : Colors.grey.shade200,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: benYazdim ? const Radius.circular(16) : const Radius.circular(4),
                                    bottomRight: benYazdim ? const Radius.circular(4) : const Radius.circular(16),
                                  ),
                                ),
                          child: Text(
                            icerik,
                            style: TextStyle(
                              color: benYazdim ? Colors.white : Colors.black87,
                              fontSize: stickerGibi ? 40 : 15,
                              height: 1.3,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
                top: 8,
                left: 8,
                right: 8,
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        _emojiGoster ? Icons.keyboard : Icons.emoji_emotions_outlined,
                        color: Colors.grey.shade700,
                        size: 26,
                      ),
                      onPressed: () {
                        setState(() {
                          _emojiGoster = !_emojiGoster;
                          if (_emojiGoster) {
                            _focusNode.unfocus();
                          } else {
                            _focusNode.requestFocus();
                          }
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.attach_file,
                        color: Colors.grey.shade700,
                        size: 26,
                      ),
                      onPressed: () {
                        // Fotoğraf ekleme fonksiyonu şimdilik boş
                        // İleride eklenebilir
                      },
                    ),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 100),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _mesajController,
                          focusNode: _focusNode,
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: "Mesaj yaz...",
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: _primaryRed,
                        shape: BoxShape.circle,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _mesajGonder,
                          borderRadius: BorderRadius.circular(50),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- GÜNCELLENMİŞ (4.4.0 UYUMLU) EMOJİ KODU ---
            Offstage(
              offstage: !_emojiGoster,
              child: SizedBox(
                height: 250,
                child: EmojiPicker(
                  textEditingController: _mesajController,
                  config: Config(
                    height: 256,
                    checkPlatformCompatibility: true,
                    // GÖRÜNÜM AYARLARI (View Config)
                    emojiViewConfig: EmojiViewConfig(
                      backgroundColor: const Color(0xFFF2F2F2),
                      columns: 7,
                      emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                    ),
                    // KATEGORİ AYARLARI (Category Config)
                    categoryViewConfig: const CategoryViewConfig(
                      initCategory: Category.SMILEYS,
                      backgroundColor: Color(0xFFF2F2F2),
                      indicatorColor: _primaryRed,
                      iconColor: Colors.grey,
                      iconColorSelected: _primaryRed,
                      backspaceColor: _primaryRed,
                    ),
                    // ALT MENÜ AYARLARI (Bottom Bar)
                    bottomActionBarConfig: const BottomActionBarConfig(
                      enabled: false, // Alt barı kapattık, daha sade dursun
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// APP BAR İÇİN PROFİL BİLGİSİ WIDGET'I
class _AppBarProfilBilgisi extends StatelessWidget {
  final String aliciId;
  final String aliciAdi;

  const _AppBarProfilBilgisi({required this.aliciId, required this.aliciAdi});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Supabase.instance.client
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', aliciId)
          .maybeSingle()
          .then((value) => value ?? <String, dynamic>{}),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        final avatarUrl = data['avatar_url'] as String?;
        final name = (data['full_name'] as String?) ?? aliciAdi;

        return Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : const AssetImage('assets/images/mus.jpg') as ImageProvider,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}