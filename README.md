#  EczSearch – Nöbetçi Eczane Bulma Uygulaması

##  Projenin Amacı
EczSearch, kullanıcıların bulundukları konuma veya seçtikleri il/ilçeye göre **güncel nöbetçi eczaneleri** hızlı ve kolay şekilde bulmalarını sağlayan bir mobil uygulamadır. Özellikle acil durumlarda zaman kaybını önlemeyi amaçlar.

---

##  Bu Uygulama Kimin İşine Yarar?
- Acil durumda nöbetçi eczane arayan kullanıcılar  
- Yeni bir şehirde bulunan kişiler  
- Gece saatlerinde açık eczane bulmak isteyen herkes  

---

##  Hangi Problemi Çözer?
- Dağınık ve güncel olmayan nöbetçi eczane bilgisi sorununu çözer  
- Konuma en yakın eczaneyi otomatik olarak sıralar  
- Manuel arama ihtiyacını azaltır  

---

##  Nerede ve Nasıl Kullanılır?
- Android cihazlarda kullanılır  
- Konum izni verilirse yakındaki nöbetçi eczaneler otomatik listelenir  
- İstenirse il / ilçe seçilerek manuel arama yapılabilir  

---

##  Kullanılan Teknolojiler
- Flutter / Dart  
- SQLite (yerel veritabanı – cache amaçlı)  
- REST API  
- Google Mobile Ads  
- Geolocator & Geocoding  

---

##  Veritabanı Kullanımı
- Uygulama **SQLite** veritabanı kullanmaktadır.

**Kullanım amaçları:**
- Daha önce alınan eczane verilerini saklamak  
- İnternet yokken cache üzerinden veri göstermek  
- Offline kullanım ve performans sağlamak  

---

##  Uygulama Ekranları
- Ana ekran  
- Yakındaki nöbetçi eczaneler  
- İl / ilçe ile arama  
- Listeleme ekranı  
- QR kod ile paylaşım popup’ı  
- Ayarlar ekranı  

---

##  Google Play Store
 [Uygulamayı Google Play Store’dan indir](https://play.google.com/store/apps/details?id=com.muhammed.eczsearch)

---

##  YouTube Tanıtım Videosu
 [Youtube Video linki.](https://youtu.be/fOmeM8RoSps?si=ZAZEnvqbmXONKN7C)

---

##  Kurulum
```bash
flutter pub get
flutter run

