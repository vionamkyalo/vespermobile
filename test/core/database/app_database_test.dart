import 'package:flutter_test/flutter_test.dart';
import 'package:insyte_mobile/core/database/app_database.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const tables = [
    AppDatabase.violationsTable,
    AppDatabase.inspectionsTable,
    AppDatabase.catchChecksTable,
  ];

  const expectedColumns = {
    'id',
    'client_uuid',
    'alert_id',
    'payload',
    'sync_status',
    'retry_count',
    'created_at',
    'synced_at',
  };

  Future<void> resetDatabase() async {
    await AppDatabase.instance.close();
    final path = join(
      await databaseFactory.getDatabasesPath(),
      AppDatabase.dbName,
    );
    await databaseFactory.deleteDatabase(path);
  }

  Map<String, Object?> sampleRow(String uuid) => {
    'client_uuid': uuid,
    'alert_id': 'alert-1',
    'payload': '{"field":"value"}',
    'created_at': DateTime.now().toIso8601String(),
  };

  setUp(resetDatabase);
  tearDownAll(resetDatabase);

  group('AppDatabase', () {
    test('returns the same instance every time', () {
      expect(identical(AppDatabase.instance, AppDatabase.instance), isTrue);
    });

    test('returns the same open database on repeated access', () async {
      final first = await AppDatabase.instance.database;
      final second = await AppDatabase.instance.database;
      expect(identical(first, second), isTrue);
      expect(first.isOpen, isTrue);
    });

    test('creates the three form tables on first open', () async {
      final db = await AppDatabase.instance.database;
      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final names = rows.map((row) => row['name']).toList();
      expect(names, containsAll(tables));
    });

    test('each table has the expected columns', () async {
      final db = await AppDatabase.instance.database;
      for (final table in tables) {
        final info = await db.rawQuery('PRAGMA table_info($table)');
        final columns = info.map((row) => row['name'] as String).toSet();
        expect(columns, expectedColumns, reason: table);
      }
    });

    test('creates a sync_status index on each table', () async {
      final db = await AppDatabase.instance.database;
      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index'",
      );
      final names = rows.map((row) => row['name']).toList();
      for (final table in tables) {
        expect(names, contains('idx_${table}_sync_status'));
      }
    });

    test('applies default sync values on insert', () async {
      final db = await AppDatabase.instance.database;
      for (final table in tables) {
        await db.insert(table, sampleRow('uuid-$table'));
        final rows = await db.query(table);
        expect(rows, hasLength(1));
        expect(rows.first['sync_status'], 'pending');
        expect(rows.first['retry_count'], 0);
        expect(rows.first['synced_at'], isNull);
      }
    });

    test('stores and returns the payload unchanged', () async {
      final db = await AppDatabase.instance.database;
      for (final table in tables) {
        await db.insert(table, sampleRow('payload-$table'));
        final rows = await db.query(table);
        expect(rows.first['payload'], '{"field":"value"}');
      }
    });

    test('allows alert_id to be null', () async {
      final db = await AppDatabase.instance.database;
      final row = sampleRow('no-alert')..['alert_id'] = null;
      await db.insert(AppDatabase.violationsTable, row);
      final rows = await db.query(AppDatabase.violationsTable);
      expect(rows.first['alert_id'], isNull);
    });

    test('rejects a duplicate client_uuid in the same table', () async {
      final db = await AppDatabase.instance.database;
      await db.insert(AppDatabase.inspectionsTable, sampleRow('dup'));
      expect(
        () => db.insert(AppDatabase.inspectionsTable, sampleRow('dup')),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('rejects a row without a payload', () async {
      final db = await AppDatabase.instance.database;
      final row = sampleRow('no-payload')..remove('payload');
      expect(
        () => db.insert(AppDatabase.catchChecksTable, row),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('keeps data after close and reopen', () async {
      final db = await AppDatabase.instance.database;
      await db.insert(AppDatabase.violationsTable, sampleRow('persist'));
      await AppDatabase.instance.close();

      final reopened = await AppDatabase.instance.database;
      final rows = await reopened.query(AppDatabase.violationsTable);
      expect(rows, hasLength(1));
      expect(rows.first['client_uuid'], 'persist');
    });

    test('close marks the old connection as closed', () async {
      final db = await AppDatabase.instance.database;
      await AppDatabase.instance.close();
      expect(db.isOpen, isFalse);
    });
  });
}
