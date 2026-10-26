import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:insyte_mobile/core/database/app_database.dart';
import 'package:insyte_mobile/core/sync/models/offline_queue_entry.dart';
import 'package:insyte_mobile/core/sync/repositories/offline_queue_repository.dart';
import 'package:insyte_mobile/core/sync/services/sync_service.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late OfflineQueueRepository repository;
  late List<http.Request> requests;

  Future<void> resetDatabase() async {
    await AppDatabase.instance.close();
    await databaseFactory.deleteDatabase(
      join(await databaseFactory.getDatabasesPath(), AppDatabase.dbName),
    );
  }

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_service_test');
    await databaseFactory.setDatabasesPath(tempDir.path);
  });

  setUp(() async {
    await resetDatabase();
    repository = OfflineQueueRepository();
    requests = [];
  });

  tearDownAll(() async {
    await resetDatabase();
    await tempDir.delete(recursive: true);
  });

  SyncService serviceAnswering(
    Future<http.Response> Function(http.Request request) answer, {
    Stream<List<ConnectivityResult>>? connectivityChanges,
  }) {
    return SyncService(
      repository: repository,
      baseUrl: 'http://api.test',
      client: MockClient((request) async {
        requests.add(request);
        return answer(request);
      }),
      headers: () => {'X-Test-User-ID': 'officer-1'},
      connectivityChanges: connectivityChanges ?? const Stream.empty(),
    );
  }

  Future<http.Response> created(http.Request _) async =>
      http.Response('{}', 201);

  Future<OfflineQueueEntry> queue(
    RecordType type,
    String id, {
    String? inspectionId,
  }) async {
    final entry = await repository.add(
      recordType: type,
      recordId: id,
      payload: {
        'id': id,
        if (inspectionId != null) 'inspection_id': inspectionId,
      },
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return entry;
  }

  Future<OfflineQueueEntry?> reload(OfflineQueueEntry entry) =>
      repository.findByRecord(entry.recordType, entry.recordId);

  test(
    'sends a queued entry and removes it once the server confirms',
    () async {
      await queue(
        RecordType.violationReport,
        'v1',
        inspectionId: 'i-on-server',
      );

      final result = await serviceAnswering(created).syncNow();
      final request = requests.single;

      expect(result.sent, 1);
      expect(result.waiting, 0);
      expect(request.method, 'POST');
      expect(request.url.toString(), 'http://api.test/violation-reports');
      expect(request.headers['X-Test-User-ID'], 'officer-1');
      expect(request.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(request.body), {
        'id': 'v1',
        'inspection_id': 'i-on-server',
      });
    },
  );

  test('sends entries oldest first, each to its own endpoint', () async {
    await queue(RecordType.inspection, 'i1');
    await queue(RecordType.violationReport, 'v1', inspectionId: 'i1');
    await queue(RecordType.catchCheck, 'c1', inspectionId: 'i1');

    await serviceAnswering(created).syncNow();

    expect(requests.map((request) => request.url.path), [
      '/inspections/',
      '/violation-reports',
      '/catch-checks',
    ]);
  });

  test(
    'treats an inspection the server already has (409) as confirmed',
    () async {
      await queue(RecordType.inspection, 'i1');

      final result = await serviceAnswering(
        (_) async => http.Response('{"detail":"already exists"}', 409),
      ).syncNow();

      expect(result.sent, 1);
      expect(result.waiting, 0);
    },
  );

  test('treats a 409 for a violation report as a real conflict', () async {
    final entry = await queue(
      RecordType.violationReport,
      'v1',
      inspectionId: 'i-on-server',
    );

    final result = await serviceAnswering(
      (_) async => http.Response('{"detail":"already uses this id"}', 409),
    ).syncNow();

    expect(result.failed, 1);
    expect((await reload(entry))!.status, QueueStatus.failed);
  });

  test('stores the reason when data is rejected and carries on', () async {
    final rejected = await queue(
      RecordType.violationReport,
      'v1',
      inspectionId: 'i-a',
    );
    await queue(RecordType.violationReport, 'v2', inspectionId: 'i-b');

    final result = await serviceAnswering((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      return body['id'] == 'v1'
          ? http.Response('{"detail":"rig_identifier is required"}', 422)
          : http.Response('{}', 201);
    }).syncNow();

    final failed = (await reload(rejected))!;
    expect(result.sent, 1);
    expect(result.failed, 1);
    expect(failed.status, QueueStatus.failed);
    expect(failed.lastError, contains('422'));
    expect(failed.lastError, contains('rig_identifier is required'));
  });

  test('stops and keeps entries when the server cannot be reached', () async {
    final first = await queue(
      RecordType.violationReport,
      'v1',
      inspectionId: 'i-a',
    );
    final second = await queue(
      RecordType.violationReport,
      'v2',
      inspectionId: 'i-b',
    );

    final result = await serviceAnswering(
      (_) async => throw http.ClientException('No signal'),
    ).syncNow();

    final untouched = (await reload(second))!;
    expect(result.offline, isTrue);
    expect(requests, hasLength(1));
    expect((await reload(first))!.status, QueueStatus.failed);
    expect(untouched.status, QueueStatus.queued);
    expect(untouched.attemptCount, 0);
  });

  test('stops after a server error, so the rest are tried later', () async {
    await queue(RecordType.violationReport, 'v1', inspectionId: 'i-a');
    final second = await queue(
      RecordType.violationReport,
      'v2',
      inspectionId: 'i-b',
    );

    await serviceAnswering((_) async => http.Response('oops', 500)).syncNow();

    expect(requests, hasLength(1));
    expect((await reload(second))!.status, QueueStatus.queued);
  });

  test('holds back reports until their inspection is confirmed', () async {
    await queue(RecordType.inspection, 'i1');
    final violation = await queue(
      RecordType.violationReport,
      'v1',
      inspectionId: 'i1',
    );
    final catchCheck = await queue(
      RecordType.catchCheck,
      'c1',
      inspectionId: 'i1',
    );

    await serviceAnswering(
      (_) async => http.Response('{"detail":"invalid"}', 422),
    ).syncNow();

    expect(requests.map((request) => request.url.path), ['/inspections/']);
    expect((await reload(violation))!.attemptCount, 0);
    expect((await reload(catchCheck))!.attemptCount, 0);
  });

  test('leaves record types without an endpoint in the queue', () async {
    final location = await queue(RecordType.location, 'loc-1');

    final result = await serviceAnswering(created).syncNow();

    expect(requests, isEmpty);
    expect(result.waiting, 1);
    expect((await reload(location))!.status, QueueStatus.queued);
  });

  test('start recovers interrupted sends and syncs them', () async {
    final entry = await queue(
      RecordType.violationReport,
      'v1',
      inspectionId: 'i-on-server',
    );
    await repository.markSending(entry.queueId);
    final service = serviceAnswering(created);

    await service.start();
    final result = await service.syncNow();

    expect(requests, hasLength(1));
    expect(result.waiting, 0);
    await service.dispose();
  });

  test('syncs when the connection comes back', () async {
    final connection = StreamController<List<ConnectivityResult>>();
    final service = serviceAnswering(
      created,
      connectivityChanges: connection.stream,
    );
    await service.start();
    await service.syncNow();

    await queue(RecordType.violationReport, 'v1', inspectionId: 'i-on-server');
    connection.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);
    final result = await service.syncNow();

    expect(requests, hasLength(1));
    expect(result.waiting, 0);
    await service.dispose();
    await connection.close();
  });
}
