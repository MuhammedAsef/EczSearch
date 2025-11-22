// lib/infrastructure/pharmacy/datasources/collectapi_pharmacy_remote_ds.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/config/collectapi_config.dart';

class CollectApiPharmacyRemoteDataSource {
  static const String _base = 'https://api.collectapi.com';
  static const String _path = '/health/dutyPharmacy';

  /// Şehir / ilçe bazlı nöbetçi eczane listesini getirir.
  ///
  /// Dönen her map’in ortak alanları:
  /// - name
  /// - address
  /// - phone
  /// - city  (UPPERCASE)
  /// - district (UPPERCASE)
  /// - lat (double? — yoksa null)
  /// - lng (double? — yoksa null)
  Future<List<Map<String, dynamic>>> getDutyPharmacies({
    required String city,
    required String district,
  }) async {
    // İstek URI’si
    final uri = Uri.parse(
      '$_base$_path?il=${Uri.encodeComponent(city)}&ilce=${Uri.encodeComponent(district)}',
    );

    // HTTP GET
    final res = await http.get(
      uri,
      headers: {
        'content-type': 'application/json',
        'authorization': collectApiKey, // örn: 'apikey your_token'
      },
    );

    if (res.statusCode != 200) {
      throw Exception('CollectAPI HTTP hatası (status: ${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('CollectAPI beklenmeyen cevap formatı');
    }

    if (decoded['success'] != true) {
      throw Exception('CollectAPI success=false döndü');
    }

    final rawList = decoded['result'];
    if (rawList is! List) {
      // result null ya da liste değilse boş dönüp üst katmanda handle edelim
      return <Map<String, dynamic>>[];
    }

    // Yardımcı dönüştürücüler
    String? _s(dynamic v) => v == null ? null : v.toString();
    double? _d(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return rawList.map<Map<String, dynamic>>((rawItem) {
      final raw = rawItem as Map<String, dynamic>;

      final name = _s(raw['name']) ?? 'Eczane';
      final address = _s(raw['address']) ?? '';
      // Bazı örneklerde phone / phoneNumber gelebiliyor
      final phone = _s(raw['phone']) ?? _s(raw['phoneNumber']) ?? '';

      // API'den gelen alanlar ile fallback:
      final c = (_s(raw['il']) ?? _s(raw['city']) ?? city).toUpperCase();
      final d = (_s(raw['ilce']) ??
              _s(raw['dist']) ??
              _s(raw['district']) ??
              district)
          .toUpperCase();

      double? lat;
      double? lng;

      // 1) latitude / longitude alanları varsa onları kullan
      if (raw['latitude'] != null && raw['longitude'] != null) {
        lat = _d(raw['latitude']);
        lng = _d(raw['longitude']);
      }
      // 2) Yoksa loc: "lat,lng" / "lng,lat" gibi string gelebilir
      else if (raw['loc'] is String) {
        final parts =
            (raw['loc'] as String).split(',').map((e) => e.trim()).toList();
        if (parts.length == 2) {
          // Çoğu örnekte CollectAPI loc'u "lat,lon" diye veriyor
          final p0 = double.tryParse(parts[0]);
          final p1 = double.tryParse(parts[1]);
          if (p0 != null && p1 != null) {
            lat = p0;
            lng = p1;
          }
        }
      }

      return {
        'name': name,
        'address': address,
        'phone': phone,
        'city': c,
        'district': d,
        'lat': lat,
        'lng': lng,
      };
    }).toList();
  }
}
