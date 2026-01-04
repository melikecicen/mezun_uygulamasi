import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DuyurularSayfasi extends StatefulWidget {
  const DuyurularSayfasi({super.key});

  @override
  State<DuyurularSayfasi> createState() => _DuyurularSayfasiState();
}

class _DuyurularSayfasiState extends State<DuyurularSayfasi>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _eventStream = Supabase.instance.client
      .from('announcements')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);

  final _surveyStream = Supabase.instance.client
      .from('surveys')
      .stream(primaryKey: ['id'])
      .eq("is_active", true)
      .order('id', ascending: false);

  bool _isAdmin = false;
  static const Color _primaryRed = Color(0xFFE41D2D);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _adminKontrol();
  }

  Future<void> _adminKontrol() async {
    final userEmail = Supabase.instance.client.auth.currentUser?.email;
    if (userEmail == null) return;

    final data = await Supabase.instance.client
        .from('admins')
        .select()
        .eq('email', userEmail)
        .maybeSingle();

    if (mounted && data != null) {
      setState(() => _isAdmin = true);
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: TabBar(
        controller: _tabController,
        labelColor: _primaryRed,
        unselectedLabelColor: Colors.black,
        indicatorColor: _primaryRed,
        tabs: const [
          Tab(text: "ETKİNLİKLER"),
          Tab(text: "ANKET & FORMLAR"),
        ],
      ),

      floatingActionButton: _isAdmin && _tabController.index == 1
          ? FloatingActionButton(
        backgroundColor: _primaryRed,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {},
      )
          : null,

      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildEtkinlikler(),
          _buildAnketler(),
        ],
      ),
    );
  }

  // --------------------------
  // 1) ETKİNLİKLER
  // --------------------------
  Widget _buildEtkinlikler() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _eventStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: _primaryRed));
        }

        final data = snapshot.data!;
        if (data.isEmpty) {
          return const Center(child: Text("Henüz etkinlik bulunmuyor."));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          separatorBuilder: (c, i) => const Divider(),
          itemBuilder: (c, index) {
            final item = data[index];

            Color color;
            IconData icon;

            switch (item["type"]) {
              case "event":
                color = Colors.blue;
                icon = Icons.event;
                break;
              case "alert":
                color = Colors.orange;
                icon = Icons.warning;
                break;
              case "club":
                color = Colors.green;
                icon = Icons.groups;
                break;
              default:
                color = _primaryRed;
                icon = Icons.campaign;
            }

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color),
              ),
              title: Text(
                item['title'] ?? "",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(item['content'] ?? ""),
              trailing: item['link'] != null
                  ? IconButton(
                icon: const Icon(Icons.link, color: _primaryRed),
                onPressed: () => _openLink(item['link']),
              )
                  : null,
            );
          },
        );
      },
    );
  }

  // --------------------------
  // 2) ANKET & FORMLAR
  // --------------------------
  Widget _buildAnketler() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _surveyStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: _primaryRed));
        }

        final data = snapshot.data!;
        if (data.isEmpty) {
          return const Center(child: Text("Henüz aktif bir anket bulunmuyor."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Anketi doldurarak ${item['reward_points']} puan kazanabilirsiniz.",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () => _openLink(item['form_url']),
                      child: const Text("Ankete Katıl"),

                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
