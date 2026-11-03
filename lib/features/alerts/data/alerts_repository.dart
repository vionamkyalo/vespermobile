import '../../../core/api/api_client.dart';
import '../../../core/location/location_service.dart';
import '../models/alerts.dart';
import 'package:flutter/foundation.dart';

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
        Alert.fromJson({
          'zone_name': zoneNames[item['zone_id']] ?? '',
          ...item
        }),
    ];
  }

    Future<void> acknowledge(String alertId, OfficerPosition position) async {
    await _api.post('/api/alert-assignments/acknowledge/$alertId');
  }




     Future<Map<String, String>> _zoneNames() async {
    try {
     
      final response = await _api.get('/api/zones');
      List<dynamic> zoneList = [];

      if (response is List) {
        zoneList = response;
      } else if (response is Map && response.containsKey('items')) {
        zoneList = response['items'] as List;
      } else if (response is Map && response.containsKey('data')) {
        zoneList = response['data'] as List;
      }

      return {
        for (final z in zoneList.cast<Map<String, dynamic>>())
          z['zone_id'] as String: z['name'] as String,
      };
    } catch (e) {
      debugPrint('❌ CRITICAL ZONE FETCH ERROR: $e');
      return const {};
    }
  }
}