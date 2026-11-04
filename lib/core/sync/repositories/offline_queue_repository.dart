import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart';
import '../models/offline_queue_entry.dart';

class OfflineQueueRepository {
  OfflineQueueRepository({AppDatabase? database, Uuid? uuid})
    : _appDatabase = database ?? AppDatabase.instance,
      _uuid = uuid ?? const Uuid();

  static const int maxAttempts = 5;

  static const String _table = AppDatabase.offlineQueueTable;

  final AppDatabase _appDatabase;
  final Uuid _uuid;

  Future<Database> get _db => _appDatabase.database;

  Future<OfflineQueueEntry> add({
    required RecordType recordType,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    final db = await _db;
    final entry = OfflineQueueEntry(
      queueId: _uuid.v4(),
      recordType: recordType,
      recordId: recordId,
      payload: payload,
      status: QueueStatus.queued,
      createdAt: DateTime.now().toUtc(),
    );

    await db.insert(
      _table,
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    return (await findByRecord(recordType, recordId))!;
  }

  Future<OfflineQueueEntry?> findByRecord(
    RecordType recordType,
    String recordId,
  ) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'record_type = ? AND record_id = ?',
      whereArgs: [recordType.value, recordId],
      limit: 1,
    );
    return rows.isEmpty ? null : OfflineQueueEntry.fromMap(rows.first);
  }

  Future<List<OfflineQueueEntry>> pending() async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'status = ? OR (status = ? AND attempt_count < ?)',
      whereArgs: [
        QueueStatus.queued.value,
        QueueStatus.failed.value,
        maxAttempts,
      ],
      orderBy: 'created_at ASC',
    );
    return rows.map(OfflineQueueEntry.fromMap).toList();
  }

  Future<Set<String>> waitingRecordIds(RecordType recordType) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      columns: ['record_id'],
      where: 'record_type = ? AND status != ?',
      whereArgs: [recordType.value, QueueStatus.synced.value],
    );
    return rows.map((row) => row['record_id'] as String).toSet();
  }

  Future<List<OfflineQueueEntry>> waiting() async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'status != ?',
      whereArgs: [QueueStatus.synced.value],
      orderBy: 'created_at ASC',
    );
    return rows.map(OfflineQueueEntry.fromMap).toList();
  }

  Future<int> waitingCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM $_table WHERE status != ?',
      [QueueStatus.synced.value],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> markSending(String queueId) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE $_table '
      'SET status = ?, attempt_count = attempt_count + 1, last_attempt_at = ? '
      'WHERE queue_id = ?',
      [QueueStatus.sending.value, _now(), queueId],
    );
  }

  Future<void> markFailed(String queueId, String error) async {
    final db = await _db;
    await db.update(
      _table,
      {'status': QueueStatus.failed.value, 'last_error': error},
      where: 'queue_id = ?',
      whereArgs: [queueId],
    );
  }

  Future<void> markRejected(String queueId, String error) async {
    final db = await _db;
    await db.update(
      _table,
      {
        'status': QueueStatus.failed.value,
        'last_error': error,
        'attempt_count': maxAttempts,
      },
      where: 'queue_id = ?',
      whereArgs: [queueId],
    );
  }

  Future<int> remapZoneIds(Map<String, String> ids) async {
    if (ids.isEmpty) return 0;
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'record_type = ? AND status != ?',
      whereArgs: [RecordType.inspection.value, QueueStatus.synced.value],
    );
    var changed = 0;
    for (final row in rows) {
      final entry = OfflineQueueEntry.fromMap(row);
      final real = ids[entry.payload['zone_id']];
      if (real == null) continue;
      await db.update(
        _table,
        {
          'payload': jsonEncode({...entry.payload, 'zone_id': real}),
          'status': QueueStatus.queued.value,
          'attempt_count': 0,
          'last_error': null,
        },
        where: 'queue_id = ?',
        whereArgs: [entry.queueId],
      );
      changed++;
    }
    return changed;
  }

  Future<void> releaseUnsent(String queueId, String reason) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE $_table '
      'SET status = ?, attempt_count = MAX(attempt_count - 1, 0), '
      'last_error = ? '
      'WHERE queue_id = ?',
      [QueueStatus.queued.value, reason, queueId],
    );
  }

  Future<int> remapInspectionId(String phoneId, String serverId) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'record_type IN (?, ?) AND status != ?',
      whereArgs: [
        RecordType.violationReport.value,
        RecordType.catchCheck.value,
        QueueStatus.synced.value,
      ],
    );
    var changed = 0;
    for (final row in rows) {
      final entry = OfflineQueueEntry.fromMap(row);
      if (entry.payload['inspection_id'] != phoneId) continue;
      await db.update(
        _table,
        {
          'payload': jsonEncode({...entry.payload, 'inspection_id': serverId}),
          'status': QueueStatus.queued.value,
          'attempt_count': 0,
          'last_error': null,
        },
        where: 'queue_id = ?',
        whereArgs: [entry.queueId],
      );
      changed++;
    }
    return changed;
  }

  Future<void> confirm(String queueId) async {
    final db = await _db;
    await db.delete(_table, where: 'queue_id = ?', whereArgs: [queueId]);
  }

  Future<int> resetInterruptedSends() async {
    final db = await _db;
    return db.update(
      _table,
      {'status': QueueStatus.queued.value},
      where: 'status = ?',
      whereArgs: [QueueStatus.sending.value],
    );
  }

  Future<void> retry(String queueId) async {
    final db = await _db;
    await db.update(
      _table,
      {
        'status': QueueStatus.queued.value,
        'attempt_count': 0,
        'last_error': null,
      },
      where: 'queue_id = ?',
      whereArgs: [queueId],
    );
  }

  static String _now() => DateTime.now().toUtc().toIso8601String();
}
