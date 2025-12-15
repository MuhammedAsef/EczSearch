#  EczSearch – Nöbetçi Eczane Bulma Uygulaması

EczSearch, Türkiye genelinde **nöbetçi eczaneleri** hızlı ve güvenilir şekilde bulmanızı sağlayan mobil bir uygulamadır.  
Kullanıcılar il/ilçe bazlı arama yapabilir veya **konumlarına en yakın nöbetçi eczaneleri** anında görüntüleyebilir.

Uygulama, performans ve güvenlik amacıyla **özel bir backend servis** üzerinden çalışır.

---

##  Özellikler

- **Konuma göre nöbetçi eczane bulma**
- **İl / ilçe bazlı arama**
- Eczane adres ve telefon bilgileri
- Yakındaki eczaneler için mesafe hesaplama
- Güvenli backend mimarisi
- Modern ve sade Flutter arayüzü

---

##  Mimari Yapı

### Mobil Uygulama
- **Flutter**
- Clean Architecture yaklaşımı
- Repository & DataSource katmanları

### Backend
- **FastAPI (Python)**
- Nginx Reverse Proxy
- HTTPS (Let’s Encrypt SSL)
- VPS üzerinde 7/24 çalışan servis


---

###  Güvenlik
- API anahtarları mobil uygulamada tutulmaz. Tüm istekler HTTPS üzerinden backend aracılığıyla yapılır.

---

###  Canlı Servis

**https://eczsearch.xyz/api/duty-pharmacies**

---

##  Geliştirici

**Muhammed Asef Kumandaveren**  
GitHub: https://github.com/MuhammedAsef

---














