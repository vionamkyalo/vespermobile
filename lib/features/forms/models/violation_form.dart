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
}
