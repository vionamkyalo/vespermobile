import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const String dbName = 'vesper_mobile.db';
  static const int dbVersion = 2;

  static const String violationsTable = 'violation_forms';
  static const String inspectionsTable = 'inspection_forms';
  static const String catchChecksTable = 'catch_check_forms';
  static const String offlineQueueTable = 'offline_queue';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), dbName);
    return openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
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

    await _createOfflineQueue(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createOfflineQueue(db);
    }
  }

  Future<void> _createOfflineQueue(Database db) async {
    await db.execute('''
      CREATE TABLE $offlineQueueTable (
        queue_id TEXT PRIMARY KEY,
        record_type TEXT NOT NULL
          CHECK (record_type IN ('inspection', 'violation_report', 'catch_check', 'location')),
        record_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'queued'
          CHECK (status IN ('queued', 'sending', 'synced', 'failed')),
        attempt_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        created_at TEXT NOT NULL,
        last_attempt_at TEXT,
        synced_at TEXT,
        UNIQUE (record_type, record_id)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_${offlineQueueTable}_status '
      'ON $offlineQueueTable(status, created_at)',
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
