import '../datasources/collectapi_pharmacy_remote_ds.dart';
import '../datasources/pharmacy_local_ds.dart';

class PharmacyRepository {
  final CollectApiPharmacyRemoteDataSource remote;
  final PharmacyLocalDataSource local;

  PharmacyRepository({
    required this.remote,
    required this.local,
  });

  
  Future<List<Map<String, dynamic>>> getDutyPharmacies({
    required String city,
    required String district,
  }) async {
    final cached = await local.getPharmacies(
      city: city,
      district: district,
      dutyOnly: true,
      maxAgeMinutes: 30,
    );
    if (cached.isNotEmpty) return cached;

    
    final remoteList = await remote.getDutyPharmacies(
      city: city,
      district: district,
    );

    
    await local.savePharmacies(
      remoteList,
      city: city,
      district: district,
      isDuty: true,
    );

    return remoteList;
  }
}
