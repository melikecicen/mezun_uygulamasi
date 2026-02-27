# 🎓 Next Station | Mezun Uygulaması

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

**Next Station**, mezun öğrencilerin üniversite ile bağını koparmadan iletişimde kalmasını, duyuruları takip etmesini ve çeşitli etkileşimlerde bulunmasını sağlamak amacıyla geliştirilmiş modern bir mobil uygulamadır.

---

## 📌 Proje Amacı & Özellikler

Mezun bireylerin ve aktif öğrencilerin üniversite ekosistemiyle entegre kalmasını sağlayan temel özellikler şunlardır:

* 📢 **Duyuru Takibi:** Üniversite içi ve mezunlara özel güncel duyurulara anında erişim.
* 👤 **Profil Yönetimi:** Kullanıcı bilgilerini görüntüleme, güncelleme ve kişiselleştirme.
* 🛍️ **Ödül & Mağaza Sistemi:** Kullanıcıların uygulama içi eylemlerle **QR puan** toplayarak mağaza ortamında harcama yapabilmesi.
* ⚙️ **Tercih Yönetimi:** Gelişmiş ayarlar menüsü üzerinden uygulama deneyimini kişiselleştirme.

---

## 🛠️ Kullanılan Teknolojiler

Proje, güncel mobil geliştirme standartlarına uygun olarak inşa edilmiştir:

* **Framework:** Flutter
* **Dil:** Dart
* **Tasarım Dili:** Material Design
* **Mimari Yaklaşım:** Stateful Widget Mimarisi & Index Tabanlı Navigation
* **Backend / Veritabanı:** Supabase 

---

## 🧭 Uygulama Mimarisi

Uygulama, sürdürülebilirliği ve performansı artırmak adına tek bir `Scaffold` yapısı üzerine kurulmuştur. 

* **Bottom Navigation:** Alt navigasyon sekmeleri index mantığı ile çalışır.
* **Sayfa Yönetimi:** Aktif sayfalar `_pages[_currentIndex]` yapısı üzerinden yönetilerek gereksiz sayfa yüklemelerinin (re-render) önüne geçilmiştir.

---

## 📱 Uygulama Bölümleri

Uygulama temel olarak 5 ana modülden oluşmaktadır:

1.  🏠 **Ana Sayfa:** Özet akış ve güncel içerikler.
2.  🛍️ **Mağaza:** QR puanların kullanılabildiği ürün listeleme alanı.
3.  🔔 **Bildirimler:** Kişiselleştirilmiş uyarılar ve duyurular.
4.  👤 **Profil:** Kullanıcı paneli.
5.  ⚙️ **Ayarlar:** Uygulama tercihleri.

---

## 🎯 Proje Kapsamı ve Hedefler

Bu uygulama bir mezuniyet projesi kapsamında, yalnızca "çalışan bir uygulama" üretmek için değil; yüksek mühendislik standartlarına ulaşmak amacıyla geliştirilmiştir. Projenin temel teknik hedefleri:

- [x] Doğru ve ölçeklenebilir bir Navigation mimarisi kurmak.
- [x] State yönetimi süreçlerini optimize etmek ve hataları minimuma indirmek.
- [x] Performanslı, temiz (clean) ve sürdürülebilir bir kod yapısı oluşturmak.
- [x] Gerçek dünya senaryolarına tam uyumlu, profesyonel bir mobil uygulama tasarlamak.

---
*Bu proje, modern mobil uygulama geliştirme prensipleri referans alınarak geliştirilmektedir.*
