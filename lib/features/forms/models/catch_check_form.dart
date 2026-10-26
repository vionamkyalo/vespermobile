class CatchCheckForm {
  const CatchCheckForm({
    required this.officer,
    required this.zone,
    required this.rigNights,
    required this.rigIdentifier,
    required this.fishType,
    required this.weightPerNightKg,
    required this.notes,
  });

  final String officer;
  final String zone;
  final int rigNights;
  final String rigIdentifier;
  final String fishType;
  final double weightPerNightKg;
  final String notes;

  double get totalWeightKg => double.parse((weightPerNightKg * rigNights).toStringAsFixed(2));

  Map<String, dynamic> toJson() => {
        'officer': officer,
        'zone': zone,
        'rig_identifier': rigIdentifier,
        'rig_nights': rigNights,
        'catch_weight_kg': totalWeightKg,
        'fish_type': fishType,
        'notes': notes,
      };
}