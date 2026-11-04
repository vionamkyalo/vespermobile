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

class ViolationRecord {
  const ViolationRecord({
    required this.id,
    required this.inspectionId,
    required this.violationType,
    required this.rigIdentifier,
    required this.description,
    required this.reviewStatus,
    required this.recordedAt,
  });

  final String id;
  final String inspectionId;
  final String violationType;
  final String rigIdentifier;
  final String description;
  final String reviewStatus;
  final DateTime recordedAt;

  factory ViolationRecord.fromJson(Map<String, dynamic> j) => ViolationRecord(
    id: j['violation_id'] as String,
    inspectionId: j['inspection_id'] as String,
    violationType: j['violation_type'] as String,
    rigIdentifier: j['rig_identifier'] as String,
    description: j['description'] as String,
    reviewStatus: j['review_status'] as String,
    recordedAt: DateTime.parse(j['recorded_at'] as String),
  );
}

class CatchCheckRecord {
  const CatchCheckRecord({
    required this.id,
    required this.inspectionId,
    required this.rigIdentifier,
    required this.rigNights,
    required this.typeOfFish,
    required this.catchWeightKg,
    required this.notes,
    required this.checkedAt,
  });

  final String id;
  final String inspectionId;
  final String rigIdentifier;
  final int rigNights;
  final String? typeOfFish;
  final double catchWeightKg;
  final String? notes;
  final DateTime checkedAt;

  factory CatchCheckRecord.fromJson(Map<String, dynamic> j) => CatchCheckRecord(
    id: j['catch_id'] as String,
    inspectionId: j['inspection_id'] as String,
    rigIdentifier: j['rig_identifier'] as String,
    rigNights: j['rig_nights'] as int,
    typeOfFish: j['type_of_fish'] as String?,
    catchWeightKg: (j['catch_weight_kg'] as num).toDouble(),
    notes: j['notes'] as String?,
    checkedAt: DateTime.parse(j['checked_at'] as String),
  );
}

class ReportsOfficer {
  const ReportsOfficer({required this.id, required this.fullName});
  final String id;
  final String fullName;
}

String labelOf(String apiValue) {
  final text = apiValue.replaceAll('_', ' ');
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}
