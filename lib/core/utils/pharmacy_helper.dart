// lib/core/utils/pharmacy_helper.dart
import 'package:geolocator/geolocator.dart';

class PharmacyHelper {
  static Map<String, dynamic>? findNearestPharmacy(
      List<Map<String, dynamic>> pharmacies, Position userPosition) {
    double minDistance = double.infinity;
    Map<String, dynamic>? nearest;

    for (var pharmacy in pharmacies) {
      double lat = 0.0;
      double lon = 0.0;

      // 🔧 loc formatı: "39.973773,32.827203"
      if (pharmacy['loc'] != null && pharmacy['loc'].toString().contains(',')) {
        final parts = pharmacy['loc'].toString().split(',');
        if (parts.length == 2) {
          lat = double.tryParse(parts[0].trim()) ?? 0.0;
          lon = double.tryParse(parts[1].trim()) ?? 0.0;
        }
      } else {
        // Fallback: bazı durumlarda ayrı alanlar olabilir
        lat = double.tryParse(pharmacy['latitude']?.toString() ?? '') ?? 0.0;
        lon = double.tryParse(pharmacy['longitude']?.toString() ?? '') ?? 0.0;
      }

      // Eğer koordinat geçersizse atla
      if (lat == 0.0 && lon == 0.0) continue;

      final distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        lat,
        lon,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearest = pharmacy;
      }
    }

    return nearest;
  }
}
