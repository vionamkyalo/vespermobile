import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/models/offline_queue_entry.dart';
import '../../../core/sync/repositories/offline_queue_repository.dart';
import '../../../core/sync/services/connection_monitor.dart';
import '../../../core/sync/services/sync_service.dart';
import '../models/violation_form.dart';

enum SubmitOutcome { sent, savedOnPhone, rejected }

class ViolationFormViewModel extends ChangeNotifier {
  ViolationFormViewModel({
    required this.officerName,
    this.inspectionId,
    this.resolveInspectionId,
    OfflineQueueRepository? queue,
    this.syncNow,
    Stream<ConnectionEvent>? connectionEvents,
    bool startsOffline = false,
  }) : _queue = queue ?? OfflineQueueRepository(),
       initialNotice = startsOffline ? _offlineMessage : null {
    _connectionSubscription = connectionEvents?.listen(
      (event) => _announce(_messageFor(event)),
    );
  }
  final String officerName;
  final String? inspectionId;
  final String Function(String phoneId)? resolveInspectionId;

  final OfflineQueueRepository _queue;
  final Future<SyncResult> Function()? syncNow;
  final String? initialNotice;

  final _notices = StreamController<String>.broadcast();
  StreamSubscription<ConnectionEvent>? _connectionSubscription;
  Stream<String> get notices => _notices.stream;

  static const String _offlineMessage =
      "You're offline. Reports you submit are saved on this phone and "
      "sent automatically when you're back online.";

  static const List<String> zoneOptions = ['Open', 'Closed'];
  static const Map<String, String> violationTypeOptions = {
    'Unregistered rig': 'unregistered_rig',
    'Missing permit': 'missing_permit',
    'Fishing in closed area': 'fishing_in_closed_area',
    'Fishing during closure': 'fishing_during_closure',
    'Rig cap exceeded': 'rig_cap_exceeded',
    'Unauthorized gear': 'unauthorized_gear',
  };

  String _zone = zoneOptions.first;
  String _violationType = violationTypeOptions.keys.first;
  String _violationsFound = '';
  String _rigsObserved = '';
  String _notes = '';

  bool _submitAttempted = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  SubmitOutcome? _lastOutcome;
  String? _rejectionReason;

  String get zone => _zone;
  String get violationType => _violationType;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  SubmitOutcome? get lastOutcome => _lastOutcome;
  String? get rejectionReason => _rejectionReason;

  void updateZone(String? value) {
    if (value == null) return;
    _zone = value;
    notifyListeners();
  }

  void updateViolationType(String? value) {
    if (value == null) return;
    _violationType = value;
    notifyListeners();
  }

  void updateViolationsFound(String value) {
    _violationsFound = value;
    notifyListeners();
  }

  void updateRigsObserved(String value) {
    _rigsObserved = value;
    notifyListeners();
  }

  void updateNotes(String value) {
    _notes = value;
    notifyListeners();
  }

  String? get officerError {
    if (!_submitAttempted) return null;
    return _officerProblem;
  }

  String? get violationsFoundError {
    if (!_submitAttempted) return null;
    return _violationsFoundProblem;
  }

  String? get rigsObservedError {
    if (!_submitAttempted) return null;
    return _rigsObservedProblem;
  }

  String? get _officerProblem => officerName.trim().isEmpty
      ? 'Could not find the signed-in officer. Please sign in again.'
      : null;

  String? get _violationsFoundProblem =>
      _violationsFound.trim().isEmpty ? 'Describe the violations found.' : null;

  String? get _rigsObservedProblem {
    final text = _rigsObserved.trim();
    if (text.isEmpty) return 'Enter the number of rigs observed.';

    final number = int.tryParse(text);
    if (number == null || number < 0) return 'Enter a whole number, 0 or more.';

    return null;
  }

  bool get _isValid =>
      _officerProblem == null &&
      _violationsFoundProblem == null &&
      _rigsObservedProblem == null;
  Future<bool> submit() async {
    if (_isSubmitting) return false;
    _submitAttempted = true;

    if (!_isValid) {
      notifyListeners();
      return false;
    }

    final phoneInspectionId = inspectionId;
    if (phoneInspectionId == null) {
      _errorMessage = 'Submit an inspection first, then record its violations.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _rejectionReason = null;
    notifyListeners();

    try {
      final form = ViolationForm(
        officer: officerName.trim(),
        zone: _zone,
        violationsFound: _violationsFound.trim(),
        rigsObserved: int.parse(_rigsObserved.trim()),
        notes: _notes.trim(),
      );

      final recordId = const Uuid().v4();

      await _queue.add(
        recordType: RecordType.violationReport,
        recordId: recordId,
        payload: form.toApiPayload(
          inspectionId:
              resolveInspectionId?.call(phoneInspectionId) ?? phoneInspectionId,
          violationType: violationTypeOptions[_violationType]!,
          recordedAt: DateTime.now(),
        ),
      );

      _lastOutcome = await _trySend(recordId);
      _reset();
      return true;
    } catch (e) {
      debugPrint('Failed to queue violation report: $e');
      _errorMessage = 'Could not save the report. Please try again.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<SubmitOutcome> _trySend(String recordId) async {
    final sync = syncNow;
    if (sync == null) return SubmitOutcome.savedOnPhone;

    try {
      await sync();
      var entry = await _queue.findByRecord(
        RecordType.violationReport,
        recordId,
      );
      if (entry == null) return SubmitOutcome.sent;
      if (entry.status == QueueStatus.queued && entry.lastError == null) {
        await sync();
        entry = await _queue.findByRecord(RecordType.violationReport, recordId);
        if (entry == null) return SubmitOutcome.sent;
      }

      if (entry.status == QueueStatus.failed) {
        _rejectionReason = entry.lastError;
        return SubmitOutcome.rejected;
      }
    } catch (e) {
      debugPrint('Sync after submit failed: $e');
    }

    return SubmitOutcome.savedOnPhone;
  }

  String _messageFor(ConnectionEvent event) {
    switch (event.change) {
      case ConnectionChange.wentOffline:
        return _offlineMessage;
      case ConnectionChange.backOnline:
        final parts = <String>["You're back online."];
        if (event.sent > 0) {
          parts.add(
            event.sent == 1
                ? '1 report was sent to the server.'
                : '${event.sent} reports were sent to the server.',
          );
        }
        if (event.rejected > 0) {
          parts.add(
            event.rejected == 1
                ? '1 report was not accepted by the server and is kept '
                      'on this phone.'
                : '${event.rejected} reports were not accepted by the '
                      'server and are kept on this phone.',
          );
        }
        if (event.serverUnreachable) {
          parts.add(
            "The server can't be reached right now. Waiting reports stay on "
            'this phone and are sent automatically.',
          );
        }
        return parts.join(' ');
    }
  }

  void _announce(String message) {
    if (!_notices.isClosed) _notices.add(message);
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _notices.close();
    super.dispose();
  }

  void _reset() {
    _zone = zoneOptions.first;
    _violationType = violationTypeOptions.keys.first;
    _violationsFound = '';
    _rigsObserved = '';
    _notes = '';
    _submitAttempted = false;
    _isSubmitting = false;
    _errorMessage = null;
    notifyListeners();
  }
}
