// lib/infrastructure/pharmacy/datasources/collectapi_pharmacy_remote_ds.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:http/http.dart' as http;

class CollectApiPharmacyRemoteDataSource {
  static const String _base = 'https://eczsearch.xyz';
  static const String _path = '/api/duty-pharmacies';

  Future<List<Map<String, dynamic>>> getDutyPharmacies({
    required String city,
    required String district,
  }) async {
    final uri = Uri.parse(
      '$_base$_path?city=${Uri.encodeComponent(city)}'
      '&district=${Uri.encodeComponent(district)}',
    );

    http.Response res;
    try {
      res = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw Exception('Sunucuya bağlanılamadı. İnternet bağlantını kontrol et.');
    } on HttpException {
      throw Exception('Sunucuya bağlanırken bir HTTP hatası oluştu.');
    } on FormatException {
      throw Exception('Sunucudan alınan veri okunamadı.');
    } on TimeoutException {
      throw Exception('İstek zaman aşımına uğradı. Biraz sonra tekrar dene.');
    }

    if (res.statusCode != 200) {
      throw Exception('Backend HTTP hatası (status: ${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Backend beklenmeyen cevap formatı');
    }

    final rawList = decoded['pharmacies'];
    if (rawList is! List) {
      return <Map<String, dynamic>>[];
    }

    String? _s(dynamic v) => v == null ? null : v.toString();
    double? _d(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final backendCity = (decoded['city'] as String? ?? city).toUpperCase();
    final backendDistrict =
        (decoded['district'] as String? ?? district).toUpperCase();

    return rawList.map<Map<String, dynamic>>((rawItem) {
      final raw = rawItem as Map<String, dynamic>;

      final name = _s(raw['name']) ?? 'Eczane';
      final address = _s(raw['address']) ?? '';
      final phone = _s(raw['phone']) ?? _s(raw['phoneNumber']) ?? '';

      double? lat;
      double? lng;

      if (raw['latitude'] != null && raw['longitude'] != null) {
        lat = _d(raw['latitude']);
        lng = _d(raw['longitude']);
      } else if (raw['loc'] is String) {
        final parts =
            (raw['loc'] as String).split(',').map((e) => e.trim()).toList();
        if (parts.length == 2) {
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
        'city': backendCity,
        'district': backendDistrict,
        'lat': lat,
        'lng': lng,
      };
    }).toList();
  }
}
