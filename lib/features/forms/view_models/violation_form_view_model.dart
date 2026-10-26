import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/models/offline_queue_entry.dart';
import '../../../core/sync/repositories/offline_queue_repository.dart';
import '../models/violation_form.dart';

class ViolationFormViewModel extends ChangeNotifier {
  ViolationFormViewModel({
    this.inspectionId,
    OfflineQueueRepository? queue,
    this.onQueued,
  }) : _queue = queue ?? OfflineQueueRepository();

  final String? inspectionId;
  final OfflineQueueRepository _queue;
  final VoidCallback? onQueued;

  static const List<String> zoneOptions = ['Open', 'Closed'];

  static const Map<String, String> violationTypeOptions = {
    'Unregistered rig': 'unregistered_rig',
    'Missing permit': 'missing_permit',
    'Fishing in closed area': 'fishing_in_closed_area',
    'Fishing during closure': 'fishing_during_closure',
    'Rig cap exceeded': 'rig_cap_exceeded',
    'Unauthorized gear': 'unauthorized_gear',
  };

  String _officer = '';
  String _zone = zoneOptions.first;
  String _violationType = violationTypeOptions.keys.first;
  String _violationsFound = '';
  String _rigsObserved = '';
  String _notes = '';

  bool _submitAttempted = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  String get zone => _zone;
  String get violationType => _violationType;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  void updateOfficer(String value) {
    _officer = value;
    notifyListeners();
  }

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

  String? get _officerProblem =>
      _officer.trim().isEmpty ? 'Enter the officer name.' : null;

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

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final form = ViolationForm(
        officer: _officer.trim(),
        zone: _zone,
        violationsFound: _violationsFound.trim(),
        rigsObserved: int.parse(_rigsObserved.trim()),
        notes: _notes.trim(),
      );

      await _queue.add(
        recordType: RecordType.violationReport,
        recordId: const Uuid().v4(),
        payload: form.toApiPayload(
          inspectionId: inspectionId,
          violationType: violationTypeOptions[_violationType]!,
          recordedAt: DateTime.now(),
        ),
      );

      onQueued?.call();
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

  void _reset() {
    _officer = '';
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
