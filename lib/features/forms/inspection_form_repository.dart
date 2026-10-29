import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/api/api_client.dart';
import 'data/zone_seed.dart';

class FormZone {
  const FormZone({
    required this.id,
    required this.name,
    this.boundary = const [],
  });

  final String id;
  final String name;

  bool get isLocalOnly => id.startsWith('local:');

  final List<List<double>> boundary;

  ({double lat, double lng})? get center {
    var pts = boundary;
    if (pts.length > 1 &&
        pts.first[0] == pts.last[0] &&
        pts.first[1] == pts.last[1]) {
      pts = pts.sublist(0, pts.length - 1);
    }
    if (pts.isEmpty) return null;
    var lat = 0.0, lng = 0.0;
    for (final p in pts) {
      lng += p[0];
      lat += p[1];
    }
    return (lat: lat / pts.length, lng: lng / pts.length);
  }

  bool contains(double lat, double lng) {
    if (boundary.length < 3) return false;
    var inside = false;
    for (var i = 0, j = boundary.length - 1; i < boundary.length; j = i++) {
      final xi = boundary[i][0], yi = boundary[i][1];
      final xj = boundary[j][0], yj = boundary[j][1];
      final crosses = (yi > lat) != (yj > lat) &&
          lng < (xj - xi) * (lat - yi) / (yj - yi) + xi;
      if (crosses) inside = !inside;
    }
    return inside;
  }

  factory FormZone.fromApi(Map<String, dynamic> z) {
    final geo = z['boundary'] as Map<String, dynamic>?;
    final rings =
        geo?['type'] == 'Polygon' ? geo!['coordinates'] as List? : null;
    return FormZone(
      id: z['zone_id'] as String,
      name: z['name'] as String,
      boundary: _ring(rings != null && rings.isNotEmpty ? rings.first : null),
    );
  }

  factory FormZone.fromCache(Map<String, dynamic> z) => FormZone(
        id: z['id'] as String,
        name: z['name'] as String,
        boundary: _ring(z['boundary']),
      );

  Map<String, dynamic> toCache() =>
      {'id': id, 'name': name, 'boundary': boundary};

  static List<List<double>> _ring(Object? raw) => [
        if (raw is List)
          for (final p in raw)
            [((p as List)[0] as num).toDouble(), (p[1] as num).toDouble()],
      ];
}

FormZone? zoneAt(List<FormZone> zones, double lat, double lng) {
  for (final z in zones) {
    if (z.contains(lat, lng)) return z;
  }
  return null;
}

class FormLookups {
  const FormLookups({required this.officerName, required this.zones});
  final String officerName;
  final List<FormZone> zones;
}

class InspectionFormRepository {
  InspectionFormRepository(this._api, [FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _cacheKey = 'vesper.cache.inspection_lookups';

  final ApiClient _api;
  final FlutterSecureStorage _storage;

  Future<FormLookups> loadLocal() async {
    final cached = await _read();
    return FormLookups(
      officerName: (cached?.officerName.isNotEmpty ?? false)
          ? cached!.officerName
          : await _signedInName(),
      zones: _merge(cached?.zones ?? const []),
    );
  }

  Future<String> _signedInName() async {
    try {
      return await _storage.read(key: 'vesper.signed_in_officer_name') ?? '';
    } catch (_) {
      return '';
    }
  }

  static List<FormZone> _merge(List<FormZone> server) {
    final byName = <String, FormZone>{
      for (final z in kZoneSeed) z.name.toLowerCase(): z,
    };
    for (final z in server) {
      byName[z.name.toLowerCase()] = z;
    }
    return byName.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<FormLookups?> refresh() async {
    try {
      final me = await _api.get('/users/me') as Map<String, dynamic>;
      final raw = await _api.get('/zones', query: {'active_only': 'true'})
          as List<dynamic>;
      final zones = [
        for (final z in raw) FormZone.fromApi(z as Map<String, dynamic>),
      ]..sort((a, b) => a.name.compareTo(b.name));
      final fresh = FormLookups(
        officerName: me['full_name'] as String,
        zones: _merge(zones),
      );
      await _save(fresh);
      return fresh;
    } catch (e) {
      debugPrint('Form data refresh skipped: $e');
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      await _storage.delete(key: _cacheKey);
    } catch (_) {}
  }

  Future<void> _save(FormLookups l) async {
    try {
      await _storage.write(
        key: _cacheKey,
        value: jsonEncode({
          'officer_name': l.officerName,
          'zones': [for (final z in l.zones) z.toCache()],
        }),
      );
    } catch (e) {
      debugPrint('Could not save form data: $e');
    }
  }

  Future<FormLookups?> _read() async {
    try {
      final text = await _storage.read(key: _cacheKey);
      if (text == null) return null;
      final map = jsonDecode(text) as Map<String, dynamic>;
      final zones = [
        for (final z in map['zones'] as List<dynamic>)
          FormZone.fromCache(z as Map<String, dynamic>),
      ];
      if (zones.isEmpty) return null;
      return FormLookups(
        officerName: map['officer_name'] as String,
        zones: zones,
      );
    } catch (_) {
      return null;
    }
  }
}