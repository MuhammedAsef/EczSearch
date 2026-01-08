// lib/infrastructure/pharmacy/datasources/collectapi_pharmacy_remote_ds.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CollectApiPharmacyRemoteDataSource {
  static const String _host = 'eczsearch.xyz';
  static const String _path = '/api/duty-pharmacies';

  Future<List<Map<String, dynamic>>> getDutyPharmacies({
    required String city,
    required String district,
  }) async {
    final uri = Uri.https(_host, _path, {
      'city': city,
      'district': district,
    });

    http.Response res;
    try {
      print('REQUEST => $uri');

      res = await http
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      print('STATUS  => ${res.statusCode}');
      print('BODY    => ${res.body}');
    } on SocketException {
      throw Exception('Sunucuya bağlanılamadı. İnternet bağlantını kontrol et.');
    } on TimeoutException {
      throw Exception('İstek zaman aşımına uğradı. Biraz sonra tekrar dene.');
    } on HandshakeException catch (e) {
      throw Exception('SSL el sıkışma hatası: $e');
    } catch (e) {
      throw Exception('İstek atılırken beklenmeyen hata: $e');
    }

    if (res.statusCode != 200) {
      throw Exception(
        'Backend HTTP hatası (status: ${res.statusCode}) - ${res.body}',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } catch (e) {
      throw Exception('Sunucudan gelen JSON okunamadı: $e');
    }

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
      if (rawItem is! Map<String, dynamic>) {
        return {
          'name': 'Eczane',
          'address': '',
          'phone': '',
          'city': backendCity,
          'district': backendDistrict,
          'lat': null,
          'lng': null,
        };
      }

      final name = _s(rawItem['name']) ?? 'Eczane';
      final address = _s(rawItem['address']) ?? '';
      final phone = _s(rawItem['phone']) ?? _s(rawItem['phoneNumber']) ?? '';

      double? lat;
      double? lng;

      if (rawItem['latitude'] != null && rawItem['longitude'] != null) {
        lat = _d(rawItem['latitude']);
        lng = _d(rawItem['longitude']);
      } else if (rawItem['loc'] is String) {
        final parts =
            (rawItem['loc'] as String).split(',').map((e) => e.trim()).toList();
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
