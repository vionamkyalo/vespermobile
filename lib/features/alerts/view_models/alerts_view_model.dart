import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/location/location_service.dart';
import '../data/alerts_repository.dart';
import '../models/alerts.dart';

enum AlertsLoadState { loading, ready, error }

enum AlertsTab { assigned, allZones }

class AlertsViewModel extends ChangeNotifier {
  AlertsViewModel(this._repository, this._location);

  final AlertsRepository _repository;
  final LocationService _location;

  List<Alert> _alerts = const [];
  AlertsLoadState _state = AlertsLoadState.loading;
  AlertsTab _tab = AlertsTab.assigned;
  String? _error;
  OfficerPosition? _position;
  final Set<String> _acknowledging = {};

  AlertsLoadState get state => _state;
  AlertsTab get tab => _tab;
  String? get error => _error;

  Iterable<Alert> get _open => _alerts.where((a) => a.isOpen);

  List<Alert> get assignedAlerts =>
      _open.where((a) => a.awaitingAcknowledgement).toList();
  List<Alert> get visibleAlerts =>
      _tab == AlertsTab.assigned ? assignedAlerts : _open.toList();

  int get assignedCount => assignedAlerts.length;
  int get zoneCount => _open.map((a) => a.zoneId).toSet().length;

  bool isAcknowledging(String id) => _acknowledging.contains(id);

  void selectTab(AlertsTab tab) {
    if (_tab == tab) return;
    _tab = tab;
    notifyListeners();
  }

  Future<void> load({bool refresh = false}) async {
    if (!refresh) {
      _state = AlertsLoadState.loading;
      notifyListeners();
    }
    try {
      _alerts = _withDistances(await _repository.fetchMyAlerts());
      _error = null;
      _state = AlertsLoadState.ready;
    } on ApiException catch (e) {
      _fail(e.message, refresh);
    } catch (e) {
      debugPrint('Loading alerts failed: $e');
      _fail('Something went wrong. Please try again.', refresh);
    }
    notifyListeners();
    if (_state == AlertsLoadState.ready) unawaited(_updateDistances());
  }

  Future<String?> acknowledge(String id) async {
    if (!_acknowledging.add(id)) return null;
    notifyListeners();
    try {
      final position = await _location.currentPosition();
      await _repository.acknowledge(id, position);
      _alerts = [
        for (final a in _alerts)
          a.id == id
              ? a.copyWith(assignmentStatus: AssignmentStatus.acknowledged)
              : a,
      ];
      return null;
    } on LocationException catch (e) {
      return e.message;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _acknowledging.remove(id);
      notifyListeners();
    }
  }

  Future<void> _updateDistances() async {
    try {
      _position = await _location.currentPosition();
    } on LocationException {
      return;
    }
    _alerts = _withDistances(_alerts);
    notifyListeners();
  }

  List<Alert> _withDistances(List<Alert> alerts) {
    final p = _position;
    if (p == null) return alerts;
    return [
      for (final a in alerts) a.withDistanceFrom(p.latitude, p.longitude),
    ];
  }

  void _fail(String message, bool refresh) {
    if (refresh && _alerts.isNotEmpty) return;
    _error = message;
    _state = AlertsLoadState.error;
  }
}
