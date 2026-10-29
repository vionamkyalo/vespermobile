import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../models/inspection_report.dart';
import '../reports_repository.dart';

class ReportsViewModel extends ChangeNotifier {
  ReportsViewModel(this._repo);
  final ReportsRepository _repo;

  bool _loading = false;
  String? _error;
  String _officerName = '';
  Map<String, String> _zones = {};
  List<InspectionReport> _inspections = [];

  bool get loading => _loading;
  String? get error => _error;
  String get officerName => _officerName;
  List<InspectionReport> get inspections => List.unmodifiable(_inspections);

  String zoneName(String id) => _zones[id] ?? 'Unknown zone';

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final me = await _repo.me();
      final (zones, inspections) =
          await (_repo.zoneNames(), _repo.inspections(me.id)).wait;
      _officerName = me.fullName;
      _zones = zones;
      _inspections = inspections;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Something went wrong. Please try again.';
    }

    _loading = false;
    notifyListeners();
  }
}