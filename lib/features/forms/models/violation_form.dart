class ViolationForm {
  const ViolationForm({
    required this.officer,
    required this.zone,
    required this.violationsFound,
    required this.rigsObserved,
    this.notes = '',
  });

  final String officer;
  final String zone;
  final String violationsFound;
  final int rigsObserved;
  final String notes;

  Map<String, dynamic> toJson() => {
    'officer': officer,
    'zone': zone,
    'violations_found': violationsFound,
    'rigs_observed': rigsObserved,
    'notes': notes,
  };

  Map<String, dynamic> toApiPayload({
    String? inspectionId,
    required String violationType,
    required DateTime recordedAt,
  }) => {
    if (inspectionId != null) 'inspection_id': inspectionId,
    'violation_type': violationType,
    'rig_identifier': rigsObserved.toString(),
    'description': [
      'Officer: $officer',
      'Zone: $zone',
      'Violations: $violationsFound',
      if (notes.isNotEmpty) 'Notes: $notes',
    ].join('\n'),
    'recorded_at': recordedAt.toUtc().toIso8601String(),
  };
}
