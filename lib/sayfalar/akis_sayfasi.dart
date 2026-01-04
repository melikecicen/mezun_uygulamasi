import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AkisSayfasi extends StatefulWidget {
  const AkisSayfasi({super.key});

  @override
  State<AkisSayfasi> createState() => _AkisSayfasiState();
}

class _AkisSayfasiState extends State<AkisSayfasi> {
  final _supabase = Supabase.instance.client;
  late Stream<List<Map<String, dynamic>>> _postsStream;
  late Stream<List<Map<String, dynamic>>> _storiesStream;
  final ImagePicker _picker = ImagePicker();
  static const Color _primaryRed = Color(0xFFE41D2D);

  @override
  void initState() {
    super.initState();
    _postsStream = _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    _storiesStream = _supabase
        .from('stories')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _postsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _primaryRed));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _bosDurumEkrani();
          }

          final posts = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: posts.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildStories();
              }
              final post = posts[index - 1];
              return PostKarti(post: post);
            },
          );
        },
      ),
    );
  }

  Widget _bosDurumEkrani() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feed_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Henüz gönderi yok.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _hikayeEkle() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final XFile? picked =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    try {
      final file = File(picked.path);
      final ext = picked.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = '${user.id}/$fileName';

      await _supabase.storage.from('stories').upload(path, file);

      final url = _supabase.storage.from('stories').getPublicUrl(path);
      await _supabase.from('stories').insert({
        'user_id': user.id,
        'image_url': url,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hikaye yüklendi.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hikaye yüklenemedi.")),
        );
      }
    }
  }

  Widget _buildStories() {
    final myId = _supabase.auth.currentUser?.id;

    return Container(
      height: 115,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _storiesStream,
        builder: (context, snapshot) {
          final stories = snapshot.data ?? [];

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            itemCount: 1 + stories.length,
            itemBuilder: (context, index) {
              // Index 0: kendi hikayem + ekleme butonu
              if (index == 0) {
                return FutureBuilder<Map<String, dynamic>>(
                  future: myId == null
                      ? Future.value(<String, dynamic>{})
                      : _supabase
                      .from('profiles')
                      .select('full_name, avatar_url')
                      .eq('id', myId)
                      .maybeSingle()
                      .then((value) => value ?? <String, dynamic>{}),
                  builder: (context, snap) {
                    final data = snap.data ?? {};
                    final avatarUrl = data['avatar_url'] as String?;
                    final name = (data['full_name'] as String?) ?? "Hikayem";

                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: _hikayeEkle,
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: avatarUrl != null
                                        ? NetworkImage(avatarUrl)
                                        : const AssetImage(
                                        'assets/images/mus.jpg')
                                    as ImageProvider,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: _primaryRed,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }

              // Diğer kullanıcıların hikayeleri
              final story = stories[index - 1];
              final userId = story['user_id'] as String;

              return FutureBuilder<Map<String, dynamic>>(
                future: _supabase
                    .from('profiles')
                    .select('full_name')
                    .eq('id', userId)
                    .maybeSingle()
                    .then((value) => value ?? <String, dynamic>{}),
                builder: (context, snap) {
                  final data = snap.data ?? {};
                  final name = (data['full_name'] as String?) ?? "MAUN Üyesi";

                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            backgroundColor: Colors.black,
                            insetPadding: EdgeInsets.zero,
                            child: Stack(
                              children: [
                                Center(
                                  child: Image.network(
                                    story['image_url'] as String,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  top: 30,
                                  right: 20,
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFFE41D2D), Color(0xFFFFCC00)],
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: NetworkImage(
                                  story['image_url'] as String,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class PostKarti extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostKarti({super.key, required this.post});

  @override
  State<PostKarti> createState() => _PostKartiState();
}

class _PostKartiState extends State<PostKarti> {
  bool _begendi = false;
  int _begeniSayisi = 0;
  bool _silindi = false;
  final String _myUserId =
      Supabase.instance.client.auth.currentUser?.id ?? "";
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _begeniDurumunuGetir();
  }

  Future<void> _begeniDurumunuGetir() async {
    if (_myUserId.isEmpty) return;
    try {
      final count = await _supabase
          .from('likes')
          .select()
          .eq('post_id', widget.post['id'])
          .count(CountOption.exact);

      final me = await _supabase
          .from('likes')
          .select()
          .eq('post_id', widget.post['id'])
          .eq('user_id', _myUserId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _begeniSayisi = count.count;
          _begendi = me != null;
        });
      }
    } catch (_) {}
  }

  Future<void> _begeniIslemi() async {
    setState(() {
      _begendi = !_begendi;
      _begeniSayisi += _begendi ? 1 : -1;
    });
    try {
      if (_begendi) {
        await _supabase.from('likes').insert({
          'user_id': _myUserId,
          'post_id': widget.post['id'],
        });
      } else {
        await _supabase
            .from('likes')
            .delete()
            .eq('user_id', _myUserId)
            .eq('post_id', widget.post['id']);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _begendi = !_begendi;
          _begeniSayisi += _begendi ? 1 : -1;
        });
      }
    }
  }

  Future<void> _postuSil() async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Gönderiyi Sil"),
        content:
        const Text("Bu gönderiyi silmek istediğine emin misin?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Sil",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (onay != true) return;

    try {
      final imageUrl = widget.post['image_url'] as String;
      if (imageUrl.contains('/posts/')) {
        final path = imageUrl.split('/posts/').last.split('?').first;
        await _supabase.storage.from('posts').remove([path]);
      }
      await _supabase
          .from('posts')
          .delete()
          .eq('id', widget.post['id']);

      if (mounted) {
        setState(() {
          _silindi = true; // LOKAL LİSTEDEN SİL
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gönderi silindi.")),
        );

        // Detay sayfasındaysak geri dön
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Silinemedi.")),
        );
      }
    }
  }

  void _yorumlariAc() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: YorumPenceresi(postId: widget.post['id']),
      ),
    );
  }

  void _gonderiyiPaylas() {
    if (_myUserId.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _supabase
              .from('profiles')
              .select('id, full_name, avatar_url')
              .neq('id', _myUserId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final users = snapshot.data!;
            if (users.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text("Gönderilecek kullanıcı yok.")),
              );
            }

            return SafeArea(
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
                  const SizedBox(height: 12),
                  const Text(
                    "Gönderiyi Paylaş",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: users.length,
                      separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final id = user['id'] as String;
                        final name =
                            (user['full_name'] as String?) ?? "Kullanıcı";
                        final avatarUrl =
                        user['avatar_url'] as String?;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : const AssetImage('assets/images/mus.jpg')
                            as ImageProvider,
                          ),
                          title: Text(name),
                          onTap: () async {
                            try {
                              final caption =
                                  (widget.post['caption'] as String?) ?? "";
                              final imageUrl =
                              widget.post['image_url'] as String;

                              final content =
                                  "Bir gönderi paylaştı:\n$caption\n$imageUrl";

                              await _supabase.from('messages').insert({
                                'sender_id': _myUserId,
                                'receiver_id': id,
                                'content': content,
                                'is_read': false,
                              });

                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "Gönderi $name ile paylaşıldı."),
                                  ),
                                );
                              }
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Gönderi paylaşılırken hata oluştu.")),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_silindi) {
      // SİLİNDİKTEN SONRA HİÇBİR ŞEY ÇİZME
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: ProfilBilgisi(userId: widget.post['user_id']),
                ),
                if (widget.post['user_id'] == _myUserId)
                  InkWell(
                    onTap: _postuSil,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.more_horiz, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onDoubleTap: _begeniIslemi,
            child: Container(
              color: Colors.grey.shade100,
              constraints: const BoxConstraints(maxHeight: 450),
              width: double.infinity,
              child: Image.network(
                widget.post['image_url'],
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const SizedBox(
                  height: 250,
                  child: Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _begendi ? Icons.favorite : Icons.favorite_border,
                    color: _begendi ? const Color(0xFFE41D2D) : Colors.black87,
                    size: 28,
                  ),
                  onPressed: _begeniIslemi,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 26,
                    color: Colors.black87,
                  ),
                  onPressed: _yorumlariAc,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.send_outlined,
                    size: 24,
                    color: Colors.black87,
                  ),
                  onPressed: _gonderiyiPaylas,
                ),
                const Spacer(),
                // Bookmark ikonu tamamen kaldırıldı
              ],
            ),
          ),
          Padding(
            padding:
            const EdgeInsets.only(left: 14, right: 14, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_begeniSayisi > 0)
                  Text(
                    "$_begeniSayisi beğenme",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 6),
                if (widget.post['caption'] != null &&
                    widget.post['caption'] != "")
                  Text(
                    widget.post['caption'],
                    style:
                    const TextStyle(color: Colors.black87),
                  ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _yorumlariAc,
                  child: Text(
                    "Yorumları gör...",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
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
}

// PROFİL BİLGİSİ (SADELEŞTİRİLMİŞ: OKUL İSMİ YOK)
class ProfilBilgisi extends StatelessWidget {
  final String userId;
  const ProfilBilgisi({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: Supabase.instance.client
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', userId)
          .maybeSingle(),
      builder: (context, snapshot) {
        String name;
        String? avatarUrl;

        if (snapshot.connectionState == ConnectionState.waiting) {
          name = "...";
        } else if (snapshot.hasError || snapshot.data == null) {
          name = "İsimsiz";
        } else {
          final data = snapshot.data!;
          final fullName = (data['full_name'] as String?)?.trim();
          name = (fullName != null && fullName.isNotEmpty) ? fullName : "İsimsiz";
          final url = data['avatar_url'];
          if (url is String && url.isNotEmpty) {
            avatarUrl = url;
          }
        }

        final String? url = avatarUrl;
        final ImageProvider avatarImage = url != null
            ? NetworkImage(url)
            : const AssetImage('assets/images/mus.jpg');

        return Row(
          children: [
            Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: avatarImage,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
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

class YorumPenceresi extends StatefulWidget {
  final int postId;
  const YorumPenceresi({super.key, required this.postId});
  @override
  State<YorumPenceresi> createState() => _YorumPenceresiState();
}

class _YorumPenceresiState extends State<YorumPenceresi> {
  final _yorumController = TextEditingController();
  final _supabase = Supabase.instance.client;
  static const Color _primaryRed = Color(0xFFE41D2D);

  // @mention özellikleri
  List<Map<String, dynamic>> _kullaniciOnerileri = [];
  bool _mentionAktif = false;
  int _mentionBaslangic = -1;

  @override
  void initState() {
    super.initState();
    _yorumController.addListener(_yorumMetniDinle);
  }

  @override
  void dispose() {
    _yorumController.removeListener(_yorumMetniDinle);
    _yorumController.dispose();
    super.dispose();
  }

  // @mention için metin dinleyicisi
  void _yorumMetniDinle() {
    final text = _yorumController.text;
    final selection = _yorumController.selection;
    final cursorPos = selection.baseOffset;

    if (cursorPos == -1 || cursorPos > text.length) {
      if (_mentionAktif) {
        setState(() {
          _mentionAktif = false;
          _kullaniciOnerileri = [];
        });
      }
      return;
    }

    // @ işaretini arayalım
    int atIndex = -1;
    for (int i = cursorPos - 1; i >= 0; i--) {
      if (text[i] == '@') {
        atIndex = i;
        break;
      }
      if (text[i] == ' ' || text[i] == '\n') {
        break;
      }
    }

    if (atIndex != -1 && (atIndex == cursorPos - 1 || 
        (cursorPos > atIndex && !text.substring(atIndex + 1, cursorPos).contains(' ')))) {
      final searchText = text.substring(atIndex + 1, cursorPos);
      setState(() {
        _mentionAktif = true;
        _mentionBaslangic = atIndex;
      });
      _kullanicilariGetir(searchText);
    } else {
      if (_mentionAktif) {
        setState(() {
          _mentionAktif = false;
          _kullaniciOnerileri = [];
        });
      }
    }
  }

  // Kullanıcıları getir (mention için)
  Future<void> _kullanicilariGetir(String arama) async {
    try {
      final myUserId = _supabase.auth.currentUser?.id;
      if (myUserId == null) return;

      final List<Map<String, dynamic>> data;
      
      if (arama.isNotEmpty) {
        data = await _supabase
            .from('profiles')
            .select('id, full_name, avatar_url')
            .neq('id', myUserId)
            .ilike('full_name', '%$arama%');
      } else {
        data = await _supabase
            .from('profiles')
            .select('id, full_name, avatar_url')
            .neq('id', myUserId)
            .limit(10);
      }

      if (mounted) {
        setState(() {
          _kullaniciOnerileri = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (_) {
      // Hata durumunda sessizce devam et
    }
  }

  // Kullanıcı seçildiğinde mention'ı tamamla
  void _kullaniciSec(Map<String, dynamic> kullanici) {
    final text = _yorumController.text;
    final userName = kullanici['full_name'] as String? ?? "Kullanıcı";
    final before = text.substring(0, _mentionBaslangic);
    final after = text.substring(_yorumController.selection.baseOffset);
    final newText = '$before@$userName $after';

    _yorumController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: _mentionBaslangic + userName.length + 2, // +2: @ ve boşluk
      ),
    );

    setState(() {
      _mentionAktif = false;
      _kullaniciOnerileri = [];
    });
  }

  Future<void> _yorumGonder() async {
    final text = _yorumController.text.trim();
    if (text.isEmpty) return;
    try {
      await _supabase.from('comments').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'post_id': widget.postId,
        'content': text,
      });
      _yorumController.clear();
      setState(() {
        _mentionAktif = false;
        _kullaniciOnerileri = [];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hata.")),
        );
      }
    }
  }

  Future<void> _yorumSil(int commentId) async {
    try {
      await _supabase.from('comments').delete().eq('id', commentId);
      // StreamBuilder otomatik güncelleyecek
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Yorum silinemedi.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _supabase.auth.currentUser?.id;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
          const Text(
            "Yorumlar",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('comments')
                  .stream(primaryKey: ['id'])
                  .eq('post_id', widget.postId)
                  .order('created_at'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return const Center(child: Text("Yorum yok."));
                }
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isMyComment =
                        comment['user_id'] == currentUserId;
                    return ListTile(
                      title: ProfilBilgisi(userId: comment['user_id']),
                      subtitle: Text(comment['content']),
                      trailing: isMyComment
                          ? IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _yorumSil(comment['id']),
                      )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          // @mention öneri listesi
          if (_mentionAktif && _kullaniciOnerileri.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _kullaniciOnerileri.length,
                itemBuilder: (context, index) {
                  final kullanici = _kullaniciOnerileri[index];
                  final name = kullanici['full_name'] as String? ?? "Kullanıcı";
                  final avatarUrl = kullanici['avatar_url'] as String?;

                  return InkWell(
                    onTap: () => _kullaniciSec(kullanici),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : const AssetImage('assets/images/mus.jpg')
                            as ImageProvider,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          // Modern yorum yazma alanı
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _yorumController,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: "Yorum yaz...",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, top: 12),
                          child: Text(
                            "@",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 30,
                        ),
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
                      onTap: _yorumGonder,
                      borderRadius: BorderRadius.circular(50),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
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
}