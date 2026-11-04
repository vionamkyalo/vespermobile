import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class OfficerPosition {
  const OfficerPosition({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final DateTime recordedAt;

  Map<String, dynamic> toJson({String? alertId}) => {
    'alert_id': ?alertId,
    'latitude': latitude,
    'longitude': longitude,
    'accuracy_m': ?accuracyMeters,
    'recorded_at': recordedAt.toUtc().toIso8601String(),
  };
}

class LocationException implements Exception {
  const LocationException(this.message);

  final String message;
}

class LocationService {
  Future<OfficerPosition> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
        'Location is switched off. Turn it on to continue.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location access is needed. Allow it in your phone or browser settings.',
      );
    }

    const timeLimit = Duration(seconds: 20);
    final settings =
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            forceLocationManager: true,
            timeLimit: timeLimit,
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: timeLimit,
          );

    try {
      final fix = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );
      return OfficerPosition(
        latitude: fix.latitude,
        longitude: fix.longitude,
        accuracyMeters: fix.accuracy,
        recordedAt: fix.timestamp,
      );
    } catch (_) {
      throw const LocationException(
        'Could not get a GPS fix. Move to open sky and try again.',
      );
    }
  }
}
