import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'eczsearch.db');

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pharmacy (
        id TEXT PRIMARY KEY,
        name TEXT,
        phone TEXT,
        address TEXT,
        lat REAL,
        lng REAL,
        city TEXT,
        district TEXT,
        is_duty INTEGER,
        updated_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE cache_index (
        city TEXT,
        district TEXT,
        fetched_at INTEGER,
        PRIMARY KEY (city, district)
      )
    ''');
  }
}
