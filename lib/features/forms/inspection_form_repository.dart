import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';

class FormZone {
  const FormZone({required this.id, required this.name});
  final String id;
  final String name;
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

  Future<FormLookups> load() async {
    try {
      final me = await _api.get('/users/me') as Map<String, dynamic>;
      final raw =
          await _api.get('/zones', query: {'active_only': 'true'})
              as List<dynamic>;
      final zones = [
        for (final z in raw)
          FormZone(
            id: (z as Map<String, dynamic>)['zone_id'] as String,
            name: z['name'] as String,
          ),
      ]..sort((a, b) => a.name.compareTo(b.name));
      final lookups = FormLookups(
        officerName: me['full_name'] as String,
        zones: zones,
      );
      await _save(lookups);
      return lookups;
    } on ApiException {
      final cached = await _read();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<void> _save(FormLookups l) async {
    try {
      await _storage.write(
        key: _cacheKey,
        value: jsonEncode({
          'officer_name': l.officerName,
          'zones': [
            for (final z in l.zones) {'id': z.id, 'name': z.name},
          ],
        }),
      );
    } catch (_) {}
  }

  Future<FormLookups?> _read() async {
    try {
      final text = await _storage.read(key: _cacheKey);
      if (text == null) return null;
      final map = jsonDecode(text) as Map<String, dynamic>;
      return FormLookups(
        officerName: map['officer_name'] as String,
        zones: [
          for (final z in map['zones'] as List<dynamic>)
            FormZone(
              id: (z as Map<String, dynamic>)['id'] as String,
              name: z['name'] as String,
            ),
        ],
      );
    } catch (_) {
      return null;
    }
  }
}