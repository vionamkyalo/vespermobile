class InspectionReport {
  const InspectionReport({
    required this.id,
    required this.zoneId,
    required this.type,
    required this.outcome,
    required this.rigsObserved,
    required this.notes,
    required this.inspectedAt,
  });

  final String id;
  final String zoneId;
  final String type;
  final String outcome;
  final int rigsObserved;
  final String? notes;
  final DateTime inspectedAt;

  factory InspectionReport.fromJson(Map<String, dynamic> j) => InspectionReport(
    id: j['inspection_id'] as String,
    zoneId: j['zone_id'] as String,
    type: j['inspection_type'] as String,
    outcome: j['outcome'] as String,
    rigsObserved: j['rigs_observed'] as int,
    notes: j['notes'] as String?,
    inspectedAt: DateTime.parse(j['inspected_at'] as String),
  );
}

class ReportsOfficer {
  const ReportsOfficer({required this.id, required this.fullName});
  final String id;
  final String fullName;
}

/// "landing_site" -> "Landing site"
String labelOf(String apiValue) {
  final text = apiValue.replaceAll('_', ' ');
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}
