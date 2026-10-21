import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const String dbName = 'vesper_mobile.db';
  static const int dbVersion = 1;

  static const String violationsTable = 'violation_forms';
  static const String inspectionsTable = 'inspection_forms';
  static const String catchChecksTable = 'catch_check_forms';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), dbName);
    return openDatabase(path, version: dbVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    for (final table in [violationsTable, inspectionsTable, catchChecksTable]) {
      await db.execute('''
        CREATE TABLE $table (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          client_uuid TEXT NOT NULL UNIQUE,
          alert_id TEXT,
          payload TEXT NOT NULL,
          is_synced INTEGER NOT NULL DEFAULT 0 CHECK (is_synced IN (0, 1)),
          retry_count INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          synced_at TEXT
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_${table}_is_synced ON $table(is_synced)',
      );
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
