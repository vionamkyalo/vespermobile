import 'dart:convert';

enum RecordType {
  inspection('inspection'),
  violationReport('violation_report'),
  catchCheck('catch_check'),
  location('location');

  const RecordType(this.value);

  final String value;

  static RecordType fromValue(String value) =>
      RecordType.values.firstWhere((type) => type.value == value);
}

enum QueueStatus {
  queued('queued'),
  sending('sending'),
  synced('synced'),
  failed('failed');

  const QueueStatus(this.value);

  final String value;

  static QueueStatus fromValue(String value) =>
      QueueStatus.values.firstWhere((status) => status.value == value);
}

class OfflineQueueEntry {
  const OfflineQueueEntry({
    required this.queueId,
    required this.recordType,
    required this.recordId,
    required this.payload,
    required this.status,
    required this.createdAt,
    this.attemptCount = 0,
    this.lastError,
    this.lastAttemptAt,
    this.syncedAt,
  });

  final String queueId;
  final RecordType recordType;

  final String recordId;
  final Map<String, dynamic> payload;

  final QueueStatus status;
  final int attemptCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final DateTime? syncedAt;

  factory OfflineQueueEntry.fromMap(Map<String, Object?> row) {
    return OfflineQueueEntry(
      queueId: row['queue_id'] as String,
      recordType: RecordType.fromValue(row['record_type'] as String),
      recordId: row['record_id'] as String,
      payload: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
      status: QueueStatus.fromValue(row['status'] as String),
      attemptCount: row['attempt_count'] as int,
      lastError: row['last_error'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      lastAttemptAt: _parseDate(row['last_attempt_at']),
      syncedAt: _parseDate(row['synced_at']),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'queue_id': queueId,
      'record_type': recordType.value,
      'record_id': recordId,
      'payload': jsonEncode(payload),
      'status': status.value,
      'attempt_count': attemptCount,
      'last_error': lastError,
      'created_at': createdAt.toUtc().toIso8601String(),
      'last_attempt_at': lastAttemptAt?.toUtc().toIso8601String(),
      'synced_at': syncedAt?.toUtc().toIso8601String(),
    };
  }

  static DateTime? _parseDate(Object? value) =>
      value == null ? null : DateTime.parse(value as String);
}
