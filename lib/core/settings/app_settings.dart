import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama dili
enum AppLanguage { tr, en }

/// Tema + Dil + Konum (il/ilçe) ayarları
/// Singleton + ChangeNotifier: AppSettings.I ile eriş
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings I = AppSettings._();

  // ---- Tema ----
  /// Sistem/ışık/koyu (Flutter'ın kendi ThemeMode'u)
  ThemeMode themeMode = ThemeMode.system;

  // ---- Dil/Locale ----
  AppLanguage _language = AppLanguage.tr;
  Locale _locale = const Locale('tr');

  AppLanguage get language => _language;
  Locale get locale => _locale;

  // ---- Konum (İl / İlçe) ----
  String? _city; // İl
  String? _district; // İlçe

  String? get selectedCity => _city;
  String? get selectedDistrict => _district;

  /// Açılışta çağır (main.dart içinde runApp'tan önce await et)
  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();

    // Dil
    final langCode = sp.getString('lang') ?? 'tr';
    if (langCode == 'en') {
      _language = AppLanguage.en;
      _locale = const Locale('en');
    } else {
      _language = AppLanguage.tr;
      _locale = const Locale('tr');
    }

    // Tema (system/light/dark)
    final themeStr = sp.getString('theme') ?? 'system';
    switch (themeStr) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }

    // Konum (il/ilçe)
    _city = sp.getString('city');
    _district = sp.getString('district');

    // İlk yüklemede de UI güncellensin
    notifyListeners();
  }

  /// Temayı ayarla ve kaydet (system/light/dark)
  Future<void> setTheme(ThemeMode mode) async {
    themeMode = mode;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('theme', switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    });
    notifyListeners();
  }

  /// Dili ayarla ve kaydet
  Future<void> setLanguage(AppLanguage lang) async {
    _language = lang;
    _locale = (lang == AppLanguage.en) ? const Locale('en') : const Locale('tr');
    final sp = await SharedPreferences.getInstance();
    await sp.setString('lang', lang == AppLanguage.en ? 'en' : 'tr');
    notifyListeners();
  }

  /// Konumu ayarla ve kaydet
  Future<void> setLocation({required String city, required String district}) async {
    _city = city;
    _district = district;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('city', city);
    await sp.setString('district', district);
    notifyListeners();
  }

  /// Konumu temizle (opsiyonel)
  Future<void> clearLocation() async {
    _city = null;
    _district = null;
    final sp = await SharedPreferences.getInstance();
    await sp.remove('city');
    await sp.remove('district');
    notifyListeners();
  }

  /// Basit çeviri yardımcı fonksiyonu
  String t(String key) {
    const tr = {
      // Genel
      'settings': 'Ayarlar',
      'theme': 'Tema',
      'light': 'Açık',
      'dark': 'Koyu',
      'language': 'Dil',
      'save': 'Kaydedildi',
      'city': 'İl',
      'district': 'İlçe',
      'find': 'Bul',
      'dutyPharmacies': 'Nöbetçi Eczaneler',

      // Tabs
      'tabNearby': 'Yakınımdaki',
      'tabSearch': 'Ara',

      // HomeScreen
      'findPharmacyTitle': 'Nöbetçi Eczane Bul',
      'findPharmacySubtitle':
          'İl ve ilçeni seç, sana en yakın nöbetçi eczaneleri bulalım',
      'cityDistrictSelection': 'İl / İlçe Seçimi',
      'pleaseSelectCityDistrict': 'Lütfen il ve ilçe seçin.',
      'noInternetCache':
          'İnternet bağlantısı bulunamadı. Önbellekteki veriler gösterilecek.',
      'noDutyFound': 'Bu bölgede nöbetçi eczane bulunamadı.',
      'noCacheCheckConnection':
          'Önbellekte veri bulunamadı. Lütfen internet bağlantınızı kontrol edin.',
      'nearestHint':
          'İpucu: Liste ekranında sağ üstteki hedef ikonuna basarak en yakın eczaneyi haritada açabilirsin.',
      'listInfo':
          'Liste ekranında sağ üstteki hedef ikonuna basarak en yakın eczaneyi doğrudan haritada açabilirsiniz.',

      // Yakınımdaki sekmesi
      'nearbyTitle': 'Yakınımdaki nöbetçi eczaneler',
      'nearbySubtitle':
          'Konumuna en yakın nöbetçi eczaneler burada listelenir.',
      'nearbyEmpty': 'Yakınında nöbetçi eczane bulunamadı.',
      'nearbyError':
          'Yakınındaki eczaneler yüklenirken bir hata oluştu.',
      'nearbyRetry': 'Tekrar dene',

      // PharmacyListScreen
      'nearestOpenTooltip': 'En yakın eczaneyi haritada aç',
      'address': 'Adres',
      'phone': 'Telefon',
      'call': 'Ara',
      'viewOnMap': 'Haritada Gör',
      'openWithGoogleMaps': 'Google Haritalar ile aç',
      'openWithYandexMaps': 'Yandex Haritalar ile aç',
      'openWithAppleMaps': 'Apple Haritalar ile aç',
      'openFailed': 'Açılamadı',
      'needLocationPermission':
          'Konum izni gerekli. Lütfen ayarlardan verin.',
      'noCoordUsedNearbySearch':
          'Listede koordinat yoktu, yakınınızdaki eczaneler açıldı.',
      'calcNearestFailed': 'En yakın eczane hesaplanamadı.',
      'nearestPharmacyPrefix': 'En yakın eczane: ',
    };

    const en = {
      // General
      'settings': 'Settings',
      'theme': 'Theme',
      'light': 'Light',
      'dark': 'Dark',
      'language': 'Language',
      'save': 'Saved',
      'city': 'City',
      'district': 'District',
      'find': 'Search',
      'dutyPharmacies': 'On-Duty Pharmacies',

      // Tabs
      'tabNearby': 'Nearby',
      'tabSearch': 'Search',

      // HomeScreen
      'findPharmacyTitle': 'Find On-Duty Pharmacy',
      'findPharmacySubtitle':
          'Select your city & district and we’ll find the nearest on-duty pharmacies.',
      'cityDistrictSelection': 'City / District Selection',
      'pleaseSelectCityDistrict': 'Please select city and district.',
      'noInternetCache':
          'No internet connection. Cached data will be shown.',
      'noDutyFound': 'No on-duty pharmacy found in this area.',
      'noCacheCheckConnection':
          'No cached data found. Please check your internet connection.',
      'nearestHint':
          'Tip: On the list screen, tap the target icon at the top-right to open the nearest pharmacy on the map.',
      'listInfo':
          'On the list screen, tap the target icon at the top-right to open the nearest pharmacy directly on the map.',

      // Nearby tab
      'nearbyTitle': 'Nearby on-duty pharmacies',
      'nearbySubtitle':
          'On-duty pharmacies closest to your location are listed here.',
      'nearbyEmpty': 'No on-duty pharmacies found near you.',
      'nearbyError':
          'An error occurred while loading nearby pharmacies.',
      'nearbyRetry': 'Retry',

      // PharmacyListScreen
      'nearestOpenTooltip': 'Open nearest pharmacy on map',
      'address': 'Address',
      'phone': 'Phone',
      'call': 'Call',
      'viewOnMap': 'Open on Map',
      'openWithGoogleMaps': 'Open with Google Maps',
      'openWithYandexMaps': 'Open with Yandex Maps',
      'openWithAppleMaps': 'Open with Apple Maps',
      'openFailed': 'Failed to open',
      'needLocationPermission':
          'Location permission is required. Please enable it in settings.',
      'noCoordUsedNearbySearch':
          'No coordinates in the list, opened pharmacies near your location.',
      'calcNearestFailed': 'Could not determine the nearest pharmacy.',
      'nearestPharmacyPrefix': 'Nearest pharmacy: ',
    };

    final map = _language == AppLanguage.en ? en : tr;
    return map[key] ?? key;
  }
}
