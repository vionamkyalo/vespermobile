import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/api/api_client.dart';
import '../../../core/sync/models/offline_queue_entry.dart';
import '../../../core/sync/repositories/offline_queue_repository.dart';
import '../../../core/sync/services/sync_service.dart';
import '../models/catch_check_form.dart';

class InspectionChoice {
  const InspectionChoice({required this.id, required this.label});

  final String id;
  final String label;

  Map<String, dynamic> toJson() => {'id': id, 'label': label};

  factory InspectionChoice.fromJson(Map<String, dynamic> json) =>
      InspectionChoice(id: json['id'] as String, label: json['label'] as String);
}

class CatchCheckFormViewModel extends ChangeNotifier {
  CatchCheckFormViewModel({
    ApiClient? api,
    OfflineQueueRepository? queue,
    SyncService? sync,
    FlutterSecureStorage? storage,
    this.initialInspectionId,
  })  : _api = api,
        _queue = queue ?? OfflineQueueRepository(),
        _sync = sync,
        _storage = storage ?? const FlutterSecureStorage();

  static const _cacheKey = 'vesper.cache.catch_check_inspections';
  static const _maxShown = 30;

  final ApiClient? _api;
  final OfflineQueueRepository _queue;
  final SyncService? _sync;
  final FlutterSecureStorage _storage;

  final String? initialInspectionId;

  List<InspectionChoice> _inspections = const [];
  String? _inspectionId;
  int _waitingInspections = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _message;
  String? _error;

  List<InspectionChoice> get inspections => _inspections;
  List<String> get inspectionLabels =>
      _inspections.map((choice) => choice.label).toList();
  String? get inspectionLabel {
    for (final choice in _inspections) {
      if (choice.id == _inspectionId) return choice.label;
    }
    return null;
  }

  /// Inspections saved on this phone that have not reached the server yet.
  /// They have no server ID, so they cannot be picked until they sync.
  int get waitingInspections => _waitingInspections;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get message => _message;
  String? get error => _error;

  /// Shows the cached list straight away, then refreshes it from the server.
  Future<void> loadInspections() async {
    _isLoading = true;
    notifyListeners();

    _inspections = await _readCache();
    _waitingInspections = await _countWaiting();
    _pickDefault();
    _isLoading = false;
    notifyListeners();

    final fresh = await _fetchFromServer();
    if (fresh != null) {
      _inspections = fresh;
      _waitingInspections = await _countWaiting();
      _pickDefault();
      await _writeCache(fresh);
      notifyListeners();
    }
  }

  void _pickDefault() {
    if (_inspectionId != null &&
        _inspections.any((c) => c.id == _inspectionId)) {
      return;
    }
    final wanted = initialInspectionId;
    if (wanted != null && _inspections.any((c) => c.id == wanted)) {
      _inspectionId = wanted;
    } else {
      _inspectionId = _inspections.isNotEmpty ? _inspections.first.id : null;
    }
  }

  Future<int> _countWaiting() async {
    try {
      final entries = await _queue.pending();
      return entries.where((e) => e.recordType == RecordType.inspection).length;
    } catch (_) {
      return 0;
    }
  }

  Future<List<InspectionChoice>?> _fetchFromServer() async {
    final api = _api;
    if (api == null) return null;
    try {
      final body = await api.get('/inspections');
      final rows = body is List
          ? body
          : body is Map
              ? (body['items'] ?? body['results'] ?? body['data'] ?? const [])
                  as List
              : const [];

      final parsed = <({InspectionChoice choice, DateTime? at})>[];
      for (final row in rows) {
        if (row is! Map) continue;
        final id = (row['inspection_id'] ?? row['id'])?.toString();
        if (id == null || id.isEmpty) continue;
        final at = DateTime.tryParse('${row['inspected_at']}');
        final rigs = (row['rigs_observed'] as num?)?.toInt();
        final zone = row['zone'];
        final zoneName = (row['zone_name'] ??
                (zone is Map ? zone['name'] : null) ??
                '')
            .toString();
        parsed.add((
          choice: InspectionChoice(
            id: id,
            label: _label(id, at, rigs, zoneName),
          ),
          at: at,
        ));
      }
      parsed.sort((a, b) {
        if (a.at == null || b.at == null) return 0;
        return b.at!.compareTo(a.at!);
      });
      return [for (final p in parsed.take(_maxShown)) p.choice];
    } catch (e) {
      debugPrint('Could not load inspections from the server: $e');
      return null;
    }
  }

  static String _label(String id, DateTime? at, int? rigs, String zone) {
    final when = at?.toLocal();
    final time = when == null
        ? ''
        : '${_two(when.day)}/${_two(when.month)} ${_two(when.hour)}:${_two(when.minute)}';
    final shortId = id.length >= 4 ? id.substring(0, 4) : id;
    final parts = [
      if (zone.isNotEmpty) zone,
      if (time.isNotEmpty) time,
      if (rigs != null) '$rigs rigs',
    ];
    return '${parts.isEmpty ? 'Inspection' : parts.join(' • ')} ($shortId)';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  Future<List<InspectionChoice>> _readCache() async {
    try {
      final text = await _storage.read(key: _cacheKey);
      if (text == null) return const [];
      return [
        for (final item in jsonDecode(text) as List<dynamic>)
          InspectionChoice.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeCache(List<InspectionChoice> choices) async {
    try {
      await _storage.write(
        key: _cacheKey,
        value: jsonEncode([for (final c in choices) c.toJson()]),
      );
    } catch (e) {
      debugPrint('Could not cache inspections: $e');
    }
  }

  void selectInspectionLabel(String? label) {
    if (label == null) return;
    for (final choice in _inspections) {
      if (choice.label == label) {
        _inspectionId = choice.id;
        notifyListeners();
        return;
      }
    }
  }

  String? validateNights(String? value) {
    final number = int.tryParse((value ?? '').trim());
    if (number == null || number < 1 || number > 365) {
      return 'Enter the number of nights, 1 to 365.';
    }
    return null;
  }

  String? validateRigIdentifier(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Enter the rig identifier.';
    if (text.length > 50) return 'Use 50 characters or fewer.';
    return null;
  }

  String? validateFishType(String? value) {
    if ((value ?? '').trim().length > 100) return 'Use 100 characters or fewer.';
    return null;
  }

  String? validateWeight(String? value) {
    final number = double.tryParse((value ?? '').trim());
    if (number == null || number < 0) {
      return 'Enter the weight in kg, 0 or more.';
    }
    return null;
  }

  String? validateNotes(String? value) {
    if ((value ?? '').trim().length > 2000) {
      return 'Use 2000 characters or fewer.';
    }
    return null;
  }

  Future<bool> submit({
    required String nights,
    required String rigIdentifier,
    required String fishType,
    required String weightPerNight,
    required String notes,
  }) async {
    final inspectionId = _inspectionId;
    if (inspectionId == null) {
      _error = 'Pick an inspection first. A catch check is added to an inspection.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _message = null;
    _error = null;
    notifyListeners();

    try {
      final form = CatchCheckForm(
        inspectionId: inspectionId,
        rigNights: int.parse(nights.trim()),
        rigIdentifier: rigIdentifier.trim(),
        fishType: fishType.trim(),
        weightPerNightKg: double.parse(weightPerNight.trim()),
        notes: notes.trim(),
      );
      await _queue.add(
        recordType: RecordType.catchCheck,
        recordId: form.catchId,
        payload: form.toJson(),
      );
      final sync = _sync;
      if (sync != null) unawaited(sync.syncNow());
      _message = 'Catch check saved. It will be sent when you are online.';
      return true;
    } catch (e) {
      debugPrint('Could not save catch check: $e');
      _error = 'Could not save the catch check. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
