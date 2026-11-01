import 'package:uuid/uuid.dart';

class CatchCheckForm {
  CatchCheckForm({
    String? catchId,
    required this.inspectionId,
    required this.rigNights,
    required this.rigIdentifier,
    required this.fishType,
    required this.weightPerNightKg,
    required this.notes,
    DateTime? checkedAt,
  }) : catchId = catchId ?? const Uuid().v4(),
       checkedAt = checkedAt ?? DateTime.now();

  final String catchId;
  final String inspectionId;
  final int rigNights;
  final String rigIdentifier;
  final String fishType;
  final double weightPerNightKg;
  final String notes;
  final DateTime checkedAt;

  double get totalWeightKg =>
      double.parse((weightPerNightKg * rigNights).toStringAsFixed(2));

  Map<String, dynamic> toJson() => {
    'catch_id': catchId,
    'inspection_id': inspectionId,
    'rig_identifier': rigIdentifier,
    'rig_nights': rigNights,
    if (fishType.isNotEmpty) 'type_of_fish': fishType,
    'catch_weight_kg': totalWeightKg,
    if (notes.isNotEmpty) 'notes': notes,
    'checked_at': checkedAt.toUtc().toIso8601String(),
  };
}
