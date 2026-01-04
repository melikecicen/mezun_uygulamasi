import 'package:flutter/material.dart';
import 'akis_sayfasi.dart'; // PostKarti bu dosyanın içinde olduğu için import ediyoruz

class PostDetaySayfasi extends StatelessWidget {
  final Map<String, dynamic> post;

  const PostDetaySayfasi({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Gönderi Detayı",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- İŞTE BURASI EKLENDİ ---
            // Akış sayfasındaki kartı aynen burada kullanıyoruz.
            // Böylece resim, beğeni, yorum ve SİLME özelliği burada da sorunsuz çalışıyor.
            PostKarti(post: post),

            // Altına biraz boşluk bırakalım ki rahat görünsün
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}