import 'package:geolocator/geolocator.dart';
import '../../infrastructure/pharmacy/datasources/collectapi_pharmacy_remote_ds.dart';

class NearbyPharmacyService {
  static Future<List<Map<String, dynamic>>> getNearby() async {
    // 1) Konumu al
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final double userLat = pos.latitude;
    final double userLng = pos.longitude;

    // 2) Tüm eczaneleri CollectAPI'den alıyoruz.
    // CollectAPI’de “/health/pharmacyList” endpoint’i var.
    final remote = CollectApiPharmacyRemoteDataSource();

    final all = await remote.getAllPharmacies();  // bunu birazdan ekleyeceğiz

    // 3) Koordinatı olanları filtrele
    final withCoords = all.where((p) {
      return p['latitude'] != null && p['longitude'] != null;
    }).toList();

    // 4) Mesafe hesapla ve ekle
    for (var p in withCoords) {
      final double lat = double.tryParse(p['latitude'].toString()) ?? 0;
      final double lng = double.tryParse(p['longitude'].toString()) ?? 0;

      final double dist = Geolocator.distanceBetween(
        userLat, userLng, lat, lng,
      );

      p['distance'] = dist; // metre cinsinden
    }

    // 5) En yakından uzağa sırala
    withCoords.sort((a, b) => a['distance'].compareTo(b['distance']));

    return withCoords;
  }
}
