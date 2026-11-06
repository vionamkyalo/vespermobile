import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/models/offline_queue_entry.dart';
import '../../../core/sync/repositories/offline_queue_repository.dart';
import '../../../core/sync/services/sync_service.dart';
import '../inspection_form_repository.dart';

enum InspectionType {
  site('site', 'Site'),
  zone('zone', 'Zone'),
  landingSite('landing_site', 'Landing Site');

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
  String _officerName = '';
  List<FormZone> _zones = const [];
  bool _locating = false;
  String? _locationError;
  bool _submitting = false;
  String? _lastInspectionId;

  bool get loading => _loading;
  String get officerName => _officerName;
  List<FormZone> get zones => _zones;
  bool get locating => _locating;
  String? get locationError => _locationError;
  bool get submitting => _submitting;
  String? get lastInspectionId => _lastInspectionId;

  Future<void> load() async {
    _apply(await _repository.loadLocal());
    _loading = false;
    notifyListeners();

    final fresh = await _repository.refresh();
    if (fresh != null) {
      _apply(fresh);
      notifyListeners();
      final ids = <String, String>{
        for (final z in fresh.zones)
          if (!z.isLocalOnly && z.name.toLowerCase().endsWith(' basin'))
            'local:${z.name.toLowerCase().replaceAll(' basin', '')}': z.id,
      };
      if (await _queue.remapZoneIds(ids) > 0) unawaited(_sync.syncNow());
    }
  }

  void _apply(FormLookups l) {
    if (l.officerName.isNotEmpty) _officerName = l.officerName;
    if (l.zones.isNotEmpty) _zones = l.zones;
  }

  FormZone? zoneNamed(String? name) {
    for (final z in _zones) {
      if (z.name == name) return z;
    }
    return null;
  }

  FormZone? zoneAtPoint(double lat, double lng) => zoneAt(_zones, lat, lng);

  Future<({double lat, double lng})?> locate() async {
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
        _locationError = 'Location permission denied. Using the zone location.';
        return null;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        _locationError = 'Location is switched off. Using the zone location.';
        return null;
      }

      final settings =
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              forceLocationManager: true,
              timeLimit: const Duration(seconds: 20),
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 20),
            );

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(locationSettings: settings);
      } catch (_) {
        if (!kIsWeb) pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) {
        _locationError = 'No GPS fix yet. Using the zone location.';
        return null;
      }
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      _locationError = 'Could not get your location. Using the zone location.';
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
      _lastInspectionId = id;
      if (zone.isLocalOnly) {
        return SubmitResult(
          SubmitStatus.savedOffline,
          'Saved on this phone. It will be sent once ${zone.name} is added to the server.',
        );
      }

      await _sync.syncNow();
      var entry = await _queue.findByRecord(RecordType.inspection, id);
      if (entry != null && entry.status == QueueStatus.queued) {
        await _sync.syncNow();
        entry = await _queue.findByRecord(RecordType.inspection, id);
      }

      if (entry == null) {
        return const SubmitResult(SubmitStatus.sent, 'Inspection submitted');
      }

      final error = entry.lastError ?? '';
      if (error.contains('answered 4')) {
        return const SubmitResult(SubmitStatus.rejected, '');
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
