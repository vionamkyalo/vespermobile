class Alert {
  const Alert({
    required this.id,
    required this.zoneName,
    required this.distanceKm,
    required this.confidence,
    required this.createdAt,
    required this.assignmentStatus,
    this.status = 'assigned',
  });

  final String id;
  final String zoneName;
  final double distanceKm;
  final double confidence;
  final DateTime createdAt;
  final String assignmentStatus;
  final String status;

  bool get isAcknowledged => assignmentStatus == 'acknowledged';

  Alert copyWith({String? assignmentStatus}) => Alert(
        id: id,
        zoneName: zoneName,
        distanceKm: distanceKm,
        confidence: confidence,
        createdAt: createdAt,
        assignmentStatus: assignmentStatus ?? this.assignmentStatus,
        status: status,
      );

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
        id: json['alert_id'] as String,
        zoneName: json['zone_name'] as String? ?? 'Unknown zone',
        distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        assignmentStatus: json['assignment_status'] as String? ?? 'unassigned',
        status: json['status'] as String? ?? 'new',
      );
}