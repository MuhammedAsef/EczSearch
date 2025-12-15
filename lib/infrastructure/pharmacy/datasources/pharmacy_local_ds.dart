import 'package:sqflite/sqflite.dart';
import '../../../core/db/app_database.dart';

class PharmacyLocalDataSource {
  Future<Database> get _db async => AppDatabase.instance.database;

  Future<List<Map<String, dynamic>>> getPharmacies({
    required String city,
    required String district,
    bool dutyOnly = true,
    int maxAgeMinutes = 30,
  }) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final threshold = now - (maxAgeMinutes * 60 * 1000);

    final where = StringBuffer('city = ? AND district = ? AND updated_at > ?');
    final args = [city.toUpperCase(), district.toUpperCase(), threshold];

    if (dutyOnly) {
      where.write(' AND is_duty = 1');
    }

    final rows = await db.query(
      'pharmacy',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'name ASC',
    );

    return rows;
  }

  Future<void> savePharmacies(
    List<Map<String, dynamic>> pharmacies, {
    required String city,
    required String district,
    required bool isDuty,
  }) async {
    final db = await _db;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final p in pharmacies) {
      final name = (p['name'] ?? '').toString();
      final phone = (p['phone'] ?? '').toString();
      final address = (p['address'] ?? '').toString();

      final lat = _toDouble(p['lat'] ?? p['latitude']);
      final lng = _toDouble(p['lng'] ?? p['longitude']);

      final id = '${city.toUpperCase()}|${district.toUpperCase()}|$name'
          .toLowerCase();

      batch.insert(
        'pharmacy',
        {
          'id': id,
          'name': name,
          'phone': phone,
          'address': address,
          'lat': lat,
          'lng': lng,
          'city': city.toUpperCase(),
          'district': district.toUpperCase(),
          'is_duty': isDuty ? 1 : 0,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    batch.insert(
      'cache_index',
      {
        'city': city.toUpperCase(),
        'district': district.toUpperCase(),
        'fetched_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await batch.commit(noResult: true);
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
