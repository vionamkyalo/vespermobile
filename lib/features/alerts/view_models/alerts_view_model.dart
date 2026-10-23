import 'package:flutter/foundation.dart';

import '../models/alerts.dart';

class AlertsViewModel extends ChangeNotifier {
  AlertsViewModel({List<Alert>? alerts}) : _alerts = alerts ?? _sampleAlerts();

  final List<Alert> _alerts;
  bool _showAllZones = false;

  List<Alert> get alerts => List.unmodifiable(_alerts);
  bool get showAllZones => _showAllZones;
  int get assignedCount => _alerts.where((alert) => !alert.isAcknowledged).length;
  int get allZonesCount => 7;

  List<Alert> get visibleAlerts => List.unmodifiable(_alerts);

  void showAssigned() {
    if (_showAllZones) {
      _showAllZones = false;
      notifyListeners();
    }
  }

  void selectAllZones() {
    if (!_showAllZones) {
      _showAllZones = true;
      notifyListeners();
    }
  }

  void acknowledgeAlert(String id) {
    final index = _alerts.indexWhere((alert) => alert.id == id);
    if (index == -1 || _alerts[index].isAcknowledged) return;
    _alerts[index] = _alerts[index].copyWith(assignmentStatus: 'acknowledged');
    notifyListeners();
  }

  static List<Alert> _sampleAlerts() {
    final now = DateTime(2026, 10, 22, 12, 39);
    return [
      Alert(
        id: 'alert-1', zoneName: 'Binga cluster 2', distanceKm: 2.1,
        confidence: 0.91, createdAt: now, assignmentStatus: 'assigned',
      ),
      Alert(
        id: 'alert-2', zoneName: 'Binga cluster 2', distanceKm: 2.1,
        confidence: 0.91, createdAt: now, assignmentStatus: 'acknowledged',
      ),
      Alert(
        id: 'alert-3', zoneName: 'Binga cluster 2', distanceKm: 2.1,
        confidence: 0.91, createdAt: now, assignmentStatus: 'assigned',
      ),
    ];
  }
}