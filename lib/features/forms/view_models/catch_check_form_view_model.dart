import 'package:flutter/foundation.dart';

import '../models/catch_check_form.dart';

class CatchCheckFormViewModel extends ChangeNotifier {
  static const List<String> zoneOptions = [
    'Mlibizi',
    'Binga',
    'Sengwa',
    'Bumi',
    'Sanyati',
  ];

  String _zone = zoneOptions.first;
  bool _isSubmitting = false;
  String? _message;

  String get zone => _zone;
  bool get isSubmitting => _isSubmitting;
  String? get message => _message;

  void updateZone(String? value) {
    if (value == null) {
      return;
    }
    _zone = value;
    notifyListeners();
  }

  String? validateOfficer(String? value) =>
      (value ?? '').trim().isEmpty ? 'Enter the officer name.' : null;

  String? validateNights(String? value) {
    final number = int.tryParse((value ?? '').trim());
    if (number == null || number < 1 || number > 365) {
      return 'Enter the number of nights, 1 to 365.';
    }
    return null;
  }

  String? validateRigIdentifier(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Enter the rig identifier.';
    }
    if (text.length > 50) {
      return 'Use 50 characters or fewer.';
    }
    return null;
  }

  String? validateFishType(String? value) =>
      (value ?? '').trim().isEmpty ? 'Enter the type of fish.' : null;

  String? validateWeight(String? value) {
    final number = double.tryParse((value ?? '').trim());
    if (number == null || number < 0) {
      return 'Enter the weight in kg, 0 or more.';
    }
    return null;
  }

  Future<bool> submit({
    required String officer,
    required String nights,
    required String rigIdentifier,
    required String fishType,
    required String weightPerNight,
    required String notes,
  }) async {
    _isSubmitting = true;
    _message = null;
    notifyListeners();

    final form = CatchCheckForm(
      officer: officer.trim(),
      zone: _zone,
      rigNights: int.parse(nights.trim()),
      rigIdentifier: rigIdentifier.trim(),
      fishType: fishType.trim(),
      weightPerNightKg: double.parse(weightPerNight.trim()),
      notes: notes.trim(),
    );

    debugPrint('Catch check submitted: ${form.toJson()}');
    await Future<void>.delayed(const Duration(milliseconds: 500));

    _zone = zoneOptions.first;
    _isSubmitting = false;
    _message = 'Catch check saved.';
    notifyListeners();
    return true;
  }
}