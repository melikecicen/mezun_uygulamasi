import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'akis_sayfasi.dart';

class KampusIsbirligi extends StatefulWidget {
  const KampusIsbirligi({super.key});

  @override
  State<KampusIsbirligi> createState() => _KampusIsbirligiState();
}

class _KampusIsbirligiState extends State<KampusIsbirligi> {
  final _supabase = Supabase.instance.client;
  static const Color _primaryRed = Color(0xFFE41D2D);

  final Map<String, Map<String, dynamic>> _kategoriler = {
    'yazilim': {'label': 'Yazılım & Teknoloji', 'icon': Icons.code, 'color': Colors.blue},
    'tasarim': {'label': 'Tasarım & Sanat', 'icon': Icons.brush, 'color': Colors.purple},
    'ozel_ders': {'label': 'Özel Ders & Eğitim', 'icon': Icons.school, 'color': Colors.orange},
    'kitap_not': {'label': 'Ders Notu & Kitap', 'icon': Icons.menu_book, 'color': Colors.teal},
    'sosyal': {'label': 'Sosyal Sorumluluk', 'icon': Icons.volunteer_activism, 'color': Colors.red},
  };

  late Stream<List<Map<String, dynamic>>> _ilanStream;

  @override
  void initState() {
    super.initState();
    _verileriGetir();
  }

  void _verileriGetir() {
    _ilanStream = _supabase.from('collab_posts').stream(primaryKey: ['id']).eq('is_active', true).order('created_at', ascending: false);
  }

  void _ilanEklePenceresi() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'yazilim';

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Yeni İlan Oluştur", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _kategoriler.entries.map((entry) {
                final isSelected = selectedCategory == entry.key;
                return Padding(padding: const EdgeInsets.only(right: 8.0), child: ChoiceChip(label: Row(children: [Icon(entry.value['icon'], size: 16, color: isSelected?Colors.white:Colors.black), const SizedBox(width: 5), Text(entry.value['label'])]), selected: isSelected, selectedColor: entry.value['color'], labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black), onSelected: (val) => setStateModal(() => selectedCategory = entry.key)));
              }).toList())),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: "Başlık",
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                    prefixIcon: Icon(Icons.short_text, color: _primaryRed, size: 22),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Açıklama",
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                    prefixIcon: Icon(Icons.notes, color: _primaryRed, size: 22),
                    prefixIconConstraints: const BoxConstraints(minWidth: 50),
                    alignLabelWithHint: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () async {
                if (titleController.text.isEmpty) return;
                await _supabase.from('collab_posts').insert({'owner_id': _supabase.auth.currentUser!.id, 'category': selectedCategory, 'title': titleController.text.trim(), 'description': descController.text.trim(), 'is_active': true});
                setState(() { _verileriGetir(); });
                if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İlan yayınlandı! 🚀"))); }
              }, style: ElevatedButton.styleFrom(backgroundColor: _primaryRed, foregroundColor: Colors.white), child: const Text("YAYINLA", style: TextStyle(fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
      ),
    );
  }

  void _ilanDuzenlePenceresi(Map<String, dynamic> post) {
    final titleController = TextEditingController(text: post['title']);
    final descController = TextEditingController(text: post['description']);
    String selectedCategory = post['category'] ?? 'yazilim';

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("İlanı Düzenle", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 20),
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _kategoriler.entries.map((entry) {
                final isSelected = selectedCategory == entry.key;
                return Padding(padding: const EdgeInsets.only(right: 8.0), child: ChoiceChip(label: Row(children: [Icon(entry.value['icon'], size: 16, color: isSelected?Colors.white:Colors.black), const SizedBox(width: 5), Text(entry.value['label'])]), selected: isSelected, selectedColor: entry.value['color'], labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black), onSelected: (val) => setStateModal(() => selectedCategory = entry.key)));
              }).toList())),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: "Başlık",
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                    prefixIcon: Icon(Icons.short_text, color: _primaryRed, size: 22),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Detaylar",
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                    prefixIcon: Icon(Icons.notes, color: _primaryRed, size: 22),
                    prefixIconConstraints: const BoxConstraints(minWidth: 50),
                    alignLabelWithHint: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () async {
                await _supabase.from('collab_posts').update({'title': titleController.text.trim(), 'description': descController.text.trim(), 'category': selectedCategory}).eq('id', post['id']);
                if(mounted) { setState(() { _verileriGetir(); }); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İlan güncellendi! ✅"))); }
              }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white), child: const Text("GÜNCELLE"))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _basvur(int postId) async {
    final myId = _supabase.auth.currentUser!.id;
    
    // Mükerrer başvuru kontrolü
    try {
      final check = await _supabase
          .from('collab_requests')
          .select()
          .eq('post_id', postId)
          .eq('applicant_id', myId)
          .maybeSingle();
      
      if (check != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Zaten başvurdun."))
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Kontrol hatası: ${e.toString()}"),
            duration: const Duration(seconds: 4),
          )
        );
      }
      return;
    }
    
    // Başvuru ekleme
    try {
      await _supabase.from('collab_requests').insert({
        'post_id': postId,
        'applicant_id': myId,
        'status': 'pending',
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Başvuruldu! 🚀"))
        );
      }
    } catch (e) {
      // Detaylı hata mesajı göster
      String errorMessage = "Hata oluştu.";
      
      if (e is PostgrestException) {
        errorMessage = "Veritabanı hatası: ${e.message}";
        if (e.details != null) {
          final detailsStr = e.details.toString();
          if (detailsStr.isNotEmpty) {
            errorMessage += "\nDetay: $detailsStr";
          }
        }
        if (e.hint != null) {
          final hintStr = e.hint.toString();
          if (hintStr.isNotEmpty) {
            errorMessage += "\nİpucu: $hintStr";
          }
        }
      } else {
        errorMessage = "Hata: ${e.toString()}";
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red.shade700,
          )
        );
      }
      
      // Debug için console'a da yazdır
      debugPrint("Başvuru hatası: $e");
      if (e is PostgrestException) {
        debugPrint("PostgrestException - Code: ${e.code}, Message: ${e.message}");
        debugPrint("Details: ${e.details}, Hint: ${e.hint}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(onPressed: _ilanEklePenceresi, backgroundColor: _primaryRed, icon: const Icon(Icons.add, color: Colors.white), label: const Text("İlan Ver", style: TextStyle(color: Colors.white))),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _ilanStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _primaryRed));
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) return const Center(child: Text("Henüz aktif ilan yok.", style: TextStyle(color: Colors.grey)));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final categoryKey = post['category'] ?? 'yazilim';
              final categoryData = _kategoriler[categoryKey] ?? _kategoriler['yazilim']!;
              final bool isMyPost = post['owner_id'] == _supabase.auth.currentUser!.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: (categoryData['color'] as Color).withOpacity(0.1), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                      child: Row(children: [
                        Icon(categoryData['icon'], size: 18, color: categoryData['color']), const SizedBox(width: 8), Text(categoryData['label'], style: TextStyle(color: categoryData['color'], fontWeight: FontWeight.bold, fontSize: 12)), const Spacer(),
                        if (!isMyPost) PopupMenuButton<String>(onSelected: (v) {}, itemBuilder: (c) => [const PopupMenuItem(value: 'sikayet', child: Row(children: [Icon(Icons.flag, color: Colors.red), SizedBox(width: 10), Text('Şikayet Et')]))], child: const Icon(Icons.more_vert, color: Colors.grey, size: 20)),
                        if (isMyPost) Row(children: [GestureDetector(onTap: () => _ilanDuzenlePenceresi(post), child: const Icon(Icons.edit, size: 20, color: Colors.blue)), const SizedBox(width: 15), GestureDetector(onTap: () async { await _supabase.from('collab_posts').delete().eq('id', post['id']); setState(() { _verileriGetir(); }); }, child: const Icon(Icons.delete_outline, size: 20, color: Colors.red))]),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(post['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 8), Text(post['description'], style: TextStyle(color: Colors.grey.shade700, height: 1.4)), const SizedBox(height: 16), const Divider(),
                        Row(children: [
                          Expanded(child: ProfilBilgisi(userId: post['owner_id'])),
                          if (!isMyPost) ElevatedButton(onPressed: () => _basvur(post['id']), style: ElevatedButton.styleFrom(backgroundColor: categoryData['color'], foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text("Başvur"))
                          else const Chip(label: Text("Senin İlanın", style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.grey)
                        ]),
                      ]),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}