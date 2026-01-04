import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DuyuruEkleSayfasi extends StatefulWidget {
  const DuyuruEkleSayfasi({super.key});

  @override
  State<DuyuruEkleSayfasi> createState() => _DuyuruEkleSayfasiState();
}

class _DuyuruEkleSayfasiState extends State<DuyuruEkleSayfasi> {
  final _baslikController = TextEditingController();
  final _icerikController = TextEditingController();
  final _linkController = TextEditingController();

  String _secilenTip = 'general'; // general, alert, event
  bool _yukleniyor = false;

  static const Color _primaryRed = Color(0xFFE41D2D);

  Future<void> _duyuruPaylas() async {
    if (_baslikController.text.isEmpty || _icerikController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Başlık ve İçerik zorunludur!")));
      return;
    }

    setState(() => _yukleniyor = true);

    try {
      await Supabase.instance.client.from('announcements').insert({
        'title': _baslikController.text.trim(),
        'content': _icerikController.text.trim(),
        'link': _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
        'type': _secilenTip,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Duyuru Yayınlandı!")));
        Navigator.pop(context); // İş bitince sayfayı kapat
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: Yetkiniz yok veya bir sorun oluştu.")));
      }
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yeni Duyuru Ekle", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Duyuru Tipi", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildChoiceChip('Genel', 'general', Icons.campaign),
                const SizedBox(width: 10),
                _buildChoiceChip('Acil', 'alert', Icons.warning),
                const SizedBox(width: 10),
                _buildChoiceChip('Etkinlik', 'event', Icons.event),
              ],
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _baslikController,
              decoration: const InputDecoration(labelText: "Başlık", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _icerikController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: "Duyuru İçeriği", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: "Link (Opsiyonel - Google Form vb.)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _yukleniyor ? null : _duyuruPaylas,
                style: ElevatedButton.styleFrom(backgroundColor: _primaryRed),
                child: _yukleniyor
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("YAYINLA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, String value, IconData icon) {
    final isSelected = _secilenTip == value;
    return ChoiceChip(
      label: Row(children: [Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.black), const SizedBox(width: 5), Text(label)]),
      selected: isSelected,
      selectedColor: _primaryRed,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      onSelected: (selected) {
        if (selected) setState(() => _secilenTip = value);
      },
    );
  }
}