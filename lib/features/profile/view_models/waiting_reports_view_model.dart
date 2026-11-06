import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/sync/models/offline_queue_entry.dart';
import '../../../core/sync/repositories/offline_queue_repository.dart';
import '../../../core/sync/services/sync_service.dart';

class WaitingReportsViewModel extends ChangeNotifier {
  WaitingReportsViewModel({required this._sync, OfflineQueueRepository? queue})
    : _queue = queue ?? OfflineQueueRepository() {
    _subscription = _sync.events.listen((_) => load());
    unawaited(load());
  }

  final SyncService _sync;
  final OfflineQueueRepository _queue;
  StreamSubscription<SyncEvent>? _subscription;

  List<OfflineQueueEntry> _entries = const [];
  bool _loading = true;
  bool _sending = false;
  String? _message;
  bool _disposed = false;

  List<OfflineQueueEntry> get entries => _entries;
  bool get loading => _loading;
  bool get sending => _sending;
  String? get message => _message;

  static const Map<RecordType, String> _typeLabels = {
    RecordType.inspection: 'Inspection',
    RecordType.violationReport: 'Violation report',
    RecordType.catchCheck: 'Catch check',
  };

  String typeLabel(OfflineQueueEntry entry) =>
      _typeLabels[entry.recordType] ?? 'Report';

  bool isRejected(OfflineQueueEntry entry) =>
      entry.status == QueueStatus.failed &&
      entry.attemptCount >= OfflineQueueRepository.maxAttempts;

  String statusLabel(OfflineQueueEntry entry) {
    if (isRejected(entry)) return 'Not accepted by the server';
    if (entry.status == QueueStatus.failed) return 'Will try again';
    if (entry.status == QueueStatus.sending) return 'Sending…';
    return 'Waiting to send';
  }

  String savedAt(OfflineQueueEntry entry) {
    final time = entry.createdAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'Saved ${two(time.day)}/${two(time.month)} at '
        '${two(time.hour)}:${two(time.minute)}';
  }

  Future<void> load() async {
    try {
      _entries = await _queue.waiting();
    } catch (e) {
      debugPrint('Could not load waiting reports: $e');
      _message = 'Could not load the reports on this phone.';
    }
    _loading = false;
    _notify();
  }

  Future<void> sendNow() async {
    if (_sending) return;
    _sending = true;
    _message = null;
    _notify();
    try {
      _message = _summary(await _sync.syncNow());
    } catch (e) {
      debugPrint('Send now failed: $e');
      _message = 'Could not send right now. Please try again.';
    }
    _sending = false;
    await load();
  }

  Future<void> retry(OfflineQueueEntry entry) async {
    await _queue.retry(entry.queueId);
    await sendNow();
  }

  static String _summary(SyncResult result) {
    if (result.offline) {
      return "Can't reach the server. Your reports stay on this phone and "
          'are sent automatically when you are back online.';
    }
    if (result.waiting == 0) return 'Everything has been sent.';
    if (result.sent > 0) {
      return result.sent == 1
          ? '1 report was sent.'
          : '${result.sent} reports were sent.';
    }
    return 'Nothing could be sent yet.';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
