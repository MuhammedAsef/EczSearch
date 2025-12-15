import 'package:geolocator/geolocator.dart';
import '../../infrastructure/pharmacy/datasources/collectapi_pharmacy_remote_ds.dart';

class NearbyPharmacyService {
  static Future<List<Map<String, dynamic>>> getNearby() async {
    
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final double userLat = pos.latitude;
    final double userLng = pos.longitude;

    
    final remote = CollectApiPharmacyRemoteDataSource();

    final all = await remote.getAllPharmacies();

    
    final withCoords = all.where((p) {
      return p['latitude'] != null && p['longitude'] != null;
    }).toList();

    
    for (var p in withCoords) {
      final double lat = double.tryParse(p['latitude'].toString()) ?? 0;
      final double lng = double.tryParse(p['longitude'].toString()) ?? 0;

      final double dist = Geolocator.distanceBetween(
        userLat, userLng, lat, lng,
      );

      p['distance'] = dist;
    }

    withCoords.sort((a, b) => a['distance'].compareTo(b['distance']));

    return withCoords;
  }
}
