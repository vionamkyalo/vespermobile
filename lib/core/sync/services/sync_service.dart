import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../models/offline_queue_entry.dart';
import '../repositories/offline_queue_repository.dart';

class SyncResult {
  const SyncResult({
    this.sent = 0,
    this.failed = 0,
    this.waiting = 0,
    this.offline = false,
  });

  final int sent;

  final int failed;

  final int waiting;
  final bool offline;
}

enum SyncEventKind { synced, failed }

class SyncEvent {
  const SyncEvent(this.kind, this.entry, [this.message = '']);
  final SyncEventKind kind;
  final OfflineQueueEntry entry;
  final String message;
}

class SyncService {
  SyncService({
    required this._repository,
    required this.baseUrl,
    http.Client? client,
    Map<String, String> Function()? headers,
    this.asyncHeaders,
    this.refreshSession,
    this._connectivityChanges,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _headers = headers ?? _noHeaders;

  static const Map<RecordType, String> endpoints = {
    RecordType.inspection: '/inspections',
    RecordType.violationReport: '/violation-reports',
    RecordType.catchCheck: '/catch-checks',
  };

  final String baseUrl;
  final Duration timeout;
  final Future<Map<String, String>> Function()? asyncHeaders;

  final Future<bool> Function()? refreshSession;

  final OfflineQueueRepository _repository;
  final http.Client _client;
  final bool _ownsClient;
  final Map<String, String> Function() _headers;
  final Stream<List<ConnectivityResult>>? _connectivityChanges;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Future<SyncResult>? _running;

  final _events = StreamController<SyncEvent>.broadcast();

  Stream<SyncEvent> get events => _events.stream;

  static Map<String, String> _noHeaders() => const {};

  Future<void> start() async {
    await _repository.resetInterruptedSends();

    _subscription ??=
        (_connectivityChanges ?? Connectivity().onConnectivityChanged).listen((
          results,
        ) {
          if (results.any((result) => result != ConnectivityResult.none)) {
            unawaited(syncNow());
          }
        });

    unawaited(syncNow());
  }

  Future<SyncResult> syncNow() =>
      _running ??= _run().whenComplete(() => _running = null);

  Future<SyncResult> _run() async {
    var sent = 0;
    var failed = 0;

    final unconfirmedInspections = await _repository.waitingRecordIds(
      RecordType.inspection,
    );

    for (final entry in await _repository.pending()) {
      final path = endpoints[entry.recordType];
      if (path == null) continue;
      if (_waitsForInspection(entry, unconfirmedInspections)) continue;
      final zoneId = entry.payload['zone_id'];
      if (zoneId is String && zoneId.startsWith('local:')) continue;

      await _repository.markSending(entry.queueId);

      http.Response response;
      try {
        response = await _post(path, entry);
        if (response.statusCode == 401 && refreshSession != null) {
          if (await refreshSession!()) {
            response = await _post(path, entry);
          }
        }
      } on Exception catch (error) {
        await _repository.markFailed(
          entry.queueId,
          'Could not reach the server: $error',
        );
        if (entry.attemptCount + 1 >= OfflineQueueRepository.maxAttempts) {
          _emitFailed(entry, 'Could not reach the server.');
        }
        return SyncResult(
          sent: sent,
          failed: failed + 1,
          waiting: await _repository.waitingCount(),
          offline: true,
        );
      }

      if (_isConfirmed(entry, response.statusCode)) {
        await _repository.confirm(entry.queueId);
        if (entry.recordType == RecordType.inspection) {
          unconfirmedInspections.remove(entry.recordId);
        }
        sent++;
        if (!_events.isClosed) {
          _events.add(SyncEvent(SyncEventKind.synced, entry));
        }
      } else {
        final reason = _reason(response);
        final code = response.statusCode;
        if (code >= 400 && code < 500) {
          await _repository.markRejected(entry.queueId, reason);
          _emitFailed(entry, reason);
        } else {
          await _repository.markFailed(entry.queueId, reason);
          if (entry.attemptCount + 1 >= OfflineQueueRepository.maxAttempts) {
            _emitFailed(entry, reason);
          }
        }
        failed++;
        if (response.statusCode >= 500) break;
      }
    }

    return SyncResult(
      sent: sent,
      failed: failed,
      waiting: await _repository.waitingCount(),
    );
  }

  bool _waitsForInspection(
    OfflineQueueEntry entry,
    Set<String> unconfirmedInspections,
  ) {
    if (entry.recordType != RecordType.violationReport &&
        entry.recordType != RecordType.catchCheck) {
      return false;
    }
    final inspectionId = entry.payload['inspection_id'];
    return inspectionId is String &&
        unconfirmedInspections.contains(inspectionId);
  }

  Future<http.Response> _post(String path, OfflineQueueEntry entry) async {
    final extra = asyncHeaders == null ? _headers() : await asyncHeaders!();
    return _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            ...extra,
          },
          body: jsonEncode(entry.payload),
        )
        .timeout(timeout);
  }

  static bool _isConfirmed(OfflineQueueEntry entry, int statusCode) {
    if (statusCode == 200 || statusCode == 201) return true;
    return entry.recordType == RecordType.inspection && statusCode == 409;
  }

  void _emitFailed(OfflineQueueEntry entry, String reason) {
    if (!_events.isClosed) {
      _events.add(SyncEvent(SyncEventKind.failed, entry, reason));
    }
  }

  static String _reason(http.Response response) {
    var detail = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        final value = decoded['detail'];
        detail = value is String ? value : jsonEncode(value);
      }
    } on FormatException {}
    return 'Server answered ${response.statusCode}: $detail';
  }

  Future<void> dispose() async {
    await _events.close();
    await _subscription?.cancel();
    _subscription = null;
    if (_ownsClient) _client.close();
  }
}