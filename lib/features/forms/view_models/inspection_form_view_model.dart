import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/sync/models/offline_queue_entry.dart';
import '../../../core/sync/repositories/offline_queue_repository.dart';
import '../../../core/sync/services/sync_service.dart';
import '../inspection_form_repository.dart';

enum InspectionType {
  site('site', 'Site'),
  landingSite('landing_site', 'Landing site'),
  zone('zone', 'Zone');

  const InspectionType(this.api, this.label);
  final String api;
  final String label;
}

enum InspectionOutcome {
  activityConsistent('activity_consistent', 'Activity consistent'),
  noActivity('no_activity', 'No activity'),
  noFishingLight('no_fishing_light', 'No fishing light'),
  unableToVerify('unable_to_verify', 'Unable to verify');

  const InspectionOutcome(this.api, this.label);
  final String api;
  final String label;
}

enum SubmitStatus { sent, savedOffline, rejected }

class SubmitResult {
  const SubmitResult(this.status, this.message);
  final SubmitStatus status;
  final String message;
}

class InspectionFormViewModel extends ChangeNotifier {
  InspectionFormViewModel({
    required this._repository,
    required this._queue,
    required this._sync,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final InspectionFormRepository _repository;
  final OfflineQueueRepository _queue;
  final SyncService _sync;
  final Uuid _uuid;

  bool _loading = true;
  String? _loadError;
  String _officerName = '';
  List<FormZone> _zones = const [];
  bool _locating = false;
  String? _locationError;
  bool _submitting = false;

  bool get loading => _loading;
  String? get loadError => _loadError;
  String get officerName => _officerName;
  List<FormZone> get zones => _zones;
  bool get locating => _locating;
  String? get locationError => _locationError;
  bool get submitting => _submitting;

  Future<void> load() async {
    _loading = true;
    _loadError = null;
    notifyListeners();
    try {
      final l = await _repository.load();
      _officerName = l.officerName;
      _zones = l.zones;
    } on ApiException catch (e) {
      _loadError = e.isNetwork
          ? 'Could not load zones. Connect to the internet once to download them.'
          : e.message;
    } catch (_) {
      _loadError = 'Something went wrong loading the form.';
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> locate() async {
    _locating = true;
    _locationError = null;
    notifyListeners();
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _locationError =
            'Location permission denied. Type the coordinates instead.';
        return null;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        _locationError =
            'Location is switched off. Turn it on or type the coordinates.';
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return formatCoordinates(pos.latitude, pos.longitude);
    } catch (_) {
      _locationError = 'Could not get your location. Type the coordinates.';
      return null;
    } finally {
      _locating = false;
      notifyListeners();
    }
  }

  static String formatCoordinates(double lat, double lng) =>
      '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';

  static ({double lat, double lng})? parseCoordinates(String text) {
    final parts = text.trim().split(RegExp(r'[,\s]+'));
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return (lat: lat, lng: lng);
  }

  static double _round6(double v) => double.parse(v.toStringAsFixed(6));

  Future<SubmitResult> submit({
    required String zoneName,
    required InspectionType type,
    required InspectionOutcome outcome,
    required int rigs,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    final zone = _zones.firstWhere((z) => z.name == zoneName);
    final id = _uuid.v4();
    final trimmed = notes?.trim() ?? '';
    final payload = <String, dynamic>{
      'zone_id': zone.id,
      'inspection_type': type.api,
      'outcome': outcome.api,
      'rigs_observed': rigs,
      'latitude': _round6(latitude),
      'longitude': _round6(longitude),
      if (trimmed.isNotEmpty) 'notes': trimmed,
      'inspected_at': DateTime.now().toUtc().toIso8601String(),
    };

    _submitting = true;
    notifyListeners();
    try {
      await _queue.add(
        recordType: RecordType.inspection,
        recordId: id,
        payload: payload,
      );

      await _sync.syncNow();
      var entry = await _queue.findByRecord(RecordType.inspection, id);
      if (entry != null && entry.status == QueueStatus.queued) {
        await _sync.syncNow();
        entry = await _queue.findByRecord(RecordType.inspection, id);
      }

      if (entry == null) {
        return const SubmitResult(
          SubmitStatus.sent,
          'Inspection submitted',
        );
      }

      final error = entry.lastError ?? '';
      if (error.contains('answered 400') || error.contains('answered 422')) {
        await _queue.confirm(entry.queueId); // invalid: don't retry forever
        final short = error.length > 160 ? '${error.substring(0, 160)}…' : error;
        return SubmitResult(
          SubmitStatus.rejected,
          'The server rejected this inspection. $short',
        );
      }
      return const SubmitResult(
        SubmitStatus.savedOffline,
        'Saved on this phone. It will be sent when you are back online.',
      );
    } catch (e) {
      debugPrint('Inspection save failed: $e');
      return const SubmitResult(
        SubmitStatus.rejected,
        'Could not save the inspection on this phone. Please try again.',
      );
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}