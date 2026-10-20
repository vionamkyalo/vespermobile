import 'package:flutter/foundation.dart';

import '../models/violation_form.dart';

class ViolationFormViewModel extends ChangeNotifier {
  static const List<String> zoneOptions = ['Open', 'Closed'];

  String _officer = '';
  String _zone = zoneOptions.first;
  String _violationsFound = '';
  String _rigsObserved = '';
  String _notes = '';

  bool _submitAttempted = false;
  bool _isSubmitting = false;

  String get zone => _zone;
  bool get isSubmitting => _isSubmitting;

  void updateOfficer(String value) {
    _officer = value;
    notifyListeners();
  }

  void updateZone(String? value) {
    if (value == null) return;
    _zone = value;
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
    _submitAttempted = true;

    if (!_isValid) {
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    notifyListeners();

    final form = ViolationForm(
      officer: _officer.trim(),
      zone: _zone,
      violationsFound: _violationsFound.trim(),
      rigsObserved: int.parse(_rigsObserved.trim()),
      notes: _notes.trim(),
    );

    debugPrint('Violation form submitted: ${form.toJson()}');
    await Future<void>.delayed(const Duration(milliseconds: 500));

    _reset();
    return true;
  }

  void _reset() {
    _officer = '';
    _zone = zoneOptions.first;
    _violationsFound = '';
    _rigsObserved = '';
    _notes = '';
    _submitAttempted = false;
    _isSubmitting = false;
    notifyListeners();
  }
}
