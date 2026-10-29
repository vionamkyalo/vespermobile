import '../../core/api/api_client.dart';
import 'models/inspection_report.dart';

class ReportsRepository {
  ReportsRepository(this._api);
  final ApiClient _api;

  Future<ReportsOfficer> me() async {
    final data = await _api.get('/users/me') as Map<String, dynamic>;
    return ReportsOfficer(
      id: data['user_id'] as String,
      fullName: data['full_name'] as String,
    );
  }

  /// zone_id -> zone name
  Future<Map<String, String>> zoneNames() async {
    final data = await _api.get('/zones') as List;
    return {
      for (final z in data.cast<Map<String, dynamic>>())
        z['zone_id'] as String: z['name'] as String,
    };
  }

  Future<List<InspectionReport>> inspections(String officerId) async {
    final data = await _api.get(
      '/inspections',
      query: {'officer_id': officerId, 'limit': '100'},
    ) as List;
    return data
        .cast<Map<String, dynamic>>()
        .map(InspectionReport.fromJson)
        .toList();
  }
}