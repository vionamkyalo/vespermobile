import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:insyte_mobile/core/database/app_database.dart';
import 'package:insyte_mobile/core/sync/models/offline_queue_entry.dart';
import 'package:insyte_mobile/core/sync/repositories/offline_queue_repository.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late OfflineQueueRepository repository;

  Future<String> databasePath() async =>
      join(await databaseFactory.getDatabasesPath(), AppDatabase.dbName);

  Future<void> resetDatabase() async {
    await AppDatabase.instance.close();
    await databaseFactory.deleteDatabase(await databasePath());
  }

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('offline_queue_test');
    await databaseFactory.setDatabasesPath(tempDir.path);
  });

  setUp(() async {
    await resetDatabase();
    repository = OfflineQueueRepository();
  });

  tearDownAll(() async {
    await resetDatabase();
    await tempDir.delete(recursive: true);
  });

  Future<OfflineQueueEntry> addViolation(String id) => repository.add(
    recordType: RecordType.violationReport,
    recordId: id,
    payload: {'violation_id': id, 'description': 'No permit on board'},
  );

  Future<OfflineQueueEntry> reload(OfflineQueueEntry entry) async =>
      (await repository.findByRecord(entry.recordType, entry.recordId))!;

  Map<String, Object?> rawRow({
    String recordType = 'violation_report',
    String status = 'queued',
  }) => {
    'queue_id': 'queue-1',
    'record_type': recordType,
    'record_id': 'record-1',
    'payload': '{}',
    'status': status,
    'created_at': DateTime.now().toUtc().toIso8601String(),
  };

  group('offline_queue table', () {
    test('is created on a new install', () async {
      final db = await AppDatabase.instance.database;

      final tables = await db.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', AppDatabase.offlineQueueTable],
      );

      expect(tables, hasLength(1));
    });

    test('is added on upgrade from version 1, keeping saved forms', () async {
      final oldDb = await databaseFactory.openDatabase(
        await databasePath(),
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute('''
              CREATE TABLE ${AppDatabase.violationsTable} (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                client_uuid TEXT NOT NULL UNIQUE,
                alert_id TEXT,
                payload TEXT NOT NULL,
                is_synced INTEGER NOT NULL DEFAULT 0,
                retry_count INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                synced_at TEXT
              )
            ''');
          },
        ),
      );
      await oldDb.insert(AppDatabase.violationsTable, {
        'client_uuid': 'saved-before-upgrade',
        'payload': '{}',
        'created_at': DateTime.now().toIso8601String(),
      });
      await oldDb.close();

      final db = await AppDatabase.instance.database;

      final queueTable = await db.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', AppDatabase.offlineQueueTable],
      );
      final savedForms = await db.query(AppDatabase.violationsTable);

      expect(await db.getVersion(), AppDatabase.dbVersion);
      expect(queueTable, hasLength(1));
      expect(savedForms.single['client_uuid'], 'saved-before-upgrade');
    });

    test('rejects a record_type that is not allowed', () async {
      final db = await AppDatabase.instance.database;

      expect(
        () => db.insert(
          AppDatabase.offlineQueueTable,
          rawRow(recordType: 'banana'),
        ),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('rejects a status that is not allowed', () async {
      final db = await AppDatabase.instance.database;

      expect(
        () => db.insert(AppDatabase.offlineQueueTable, rawRow(status: 'lost')),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('add', () {
    test('saves a new entry as queued with no attempts', () async {
      final entry = await addViolation('violation-1');

      expect(entry.recordType, RecordType.violationReport);
      expect(entry.recordId, 'violation-1');
      expect(entry.status, QueueStatus.queued);
      expect(entry.attemptCount, 0);
      expect(entry.lastError, isNull);
      expect(entry.lastAttemptAt, isNull);
      expect(entry.syncedAt, isNull);
      expect(entry.payload, {
        'violation_id': 'violation-1',
        'description': 'No permit on board',
      });
    });

    test('does not queue the same record twice', () async {
      final first = await addViolation('violation-1');
      final second = await addViolation('violation-1');

      expect(second.queueId, first.queueId);
      expect(await repository.waitingCount(), 1);
    });

    test('accepts every record type', () async {
      for (final type in RecordType.values) {
        await repository.add(
          recordType: type,
          recordId: 'record-${type.value}',
          payload: {'type': type.value},
        );
      }

      expect(await repository.waitingCount(), RecordType.values.length);
    });
  });

  group('pending', () {
    test('returns entries oldest first', () async {
      await addViolation('first');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await addViolation('second');

      final pending = await repository.pending();

      expect(pending.map((entry) => entry.recordId), ['first', 'second']);
    });

    test('skips entries that are being sent', () async {
      final entry = await addViolation('violation-1');
      await repository.markSending(entry.queueId);

      expect(await repository.pending(), isEmpty);
    });

    test('includes failed entries that still have tries left', () async {
      final entry = await addViolation('violation-1');
      await repository.markSending(entry.queueId);
      await repository.markFailed(entry.queueId, 'No signal');

      final pending = await repository.pending();

      expect(pending.single.status, QueueStatus.failed);
    });

    test(
      'skips entries that ran out of tries, but still counts them',
      () async {
        final entry = await addViolation('violation-1');
        for (var i = 0; i < OfflineQueueRepository.maxAttempts; i++) {
          await repository.markSending(entry.queueId);
          await repository.markFailed(entry.queueId, 'Invalid data');
        }

        expect(await repository.pending(), isEmpty);
        expect(await repository.waitingCount(), 1);
      },
    );
  });

  group('status changes', () {
    test('markSending counts the try and records when it happened', () async {
      final entry = await addViolation('violation-1');

      await repository.markSending(entry.queueId);
      final updated = await reload(entry);

      expect(updated.status, QueueStatus.sending);
      expect(updated.attemptCount, 1);
      expect(updated.lastAttemptAt, isNotNull);
    });

    test('markFailed stores the reason', () async {
      final entry = await addViolation('violation-1');
      await repository.markSending(entry.queueId);

      await repository.markFailed(entry.queueId, 'No signal');
      final updated = await reload(entry);

      expect(updated.status, QueueStatus.failed);
      expect(updated.lastError, 'No signal');
    });

    test('confirm removes the entry', () async {
      final entry = await addViolation('violation-1');

      await repository.confirm(entry.queueId);

      expect(
        await repository.findByRecord(entry.recordType, entry.recordId),
        isNull,
      );
      expect(await repository.waitingCount(), 0);
    });

    test(
      'resetInterruptedSends puts stuck entries back in the queue',
      () async {
        final entry = await addViolation('violation-1');
        await repository.markSending(entry.queueId);

        final reset = await repository.resetInterruptedSends();
        final updated = await reload(entry);

        expect(reset, 1);
        expect(updated.status, QueueStatus.queued);
      },
    );

    test('retry gives an entry a fresh set of tries', () async {
      final entry = await addViolation('violation-1');
      await repository.markSending(entry.queueId);
      await repository.markFailed(entry.queueId, 'Invalid data');

      await repository.retry(entry.queueId);
      final updated = await reload(entry);

      expect(updated.status, QueueStatus.queued);
      expect(updated.attemptCount, 0);
      expect(updated.lastError, isNull);
    });
  });
}
