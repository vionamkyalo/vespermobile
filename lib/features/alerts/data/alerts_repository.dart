import '../../../core/api/api_client.dart';
import '../../../core/location/location_service.dart';
import '../models/alerts.dart';

class AlertsRepository {
  AlertsRepository(this._api);

  final ApiClient _api;

  static const _alertsPath = '/api/alerts';
  static const _positionsPath = '/api/officer-assignments';

  Future<List<Alert>> fetchMyAlerts() async {
    final zoneNames = await _zoneNames();
    final page = await _api.get(
      '$_alertsPath/assigned/me',
      query: {'limit': '100'},
    ) as Map<String, dynamic>;
    return [
      for (final item in (page['items'] as List).cast<Map<String, dynamic>>())
        Alert.fromJson({'zone_name': zoneNames[item['zone_id']], ...item}),
    ];
  }

  Future<void> acknowledge(String alertId, OfficerPosition position) async {
    await _api.post(_positionsPath, body: position.toJson(alertId: alertId));
    await _api.patch('$_alertsPath/$alertId/acknowledge');
  }

  Future<Map<String, String>> _zoneNames() async {
    try {
      final zones = await _api.get('/zones') as List;
      return {
        for (final z in zones.cast<Map<String, dynamic>>())
          z['zone_id'] as String: z['name'] as String,
      };
    } catch (_) {
      return const {};
    }
  }
}
