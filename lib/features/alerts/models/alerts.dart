import 'dart:math' as math;

enum AssignmentStatus {
  assigned,
  acknowledged,
  reported,
  reassigned,
  failed;

  static AssignmentStatus? parse(String? value) {
    for (final status in values) {
      if (status.name == value) return status;
    }
    return null;
  }
}

class Alert {
  const Alert({
    required this.id,
    required this.zoneId,
    required this.zoneName,
    required this.confidence,
    required this.priority,
    required this.summary,
    required this.centroidLatitude,
    required this.centroidLongitude,
    required this.status,
    required this.assignmentStatus,
    required this.createdAt,
    this.distanceKm,
  });

  final String id;
  final String zoneId;
  final String zoneName;

  final double confidence;

  final String priority;
  final String summary;
  final double centroidLatitude;
  final double centroidLongitude;

  final String status;
  final AssignmentStatus? assignmentStatus;
  final DateTime createdAt;

  final double? distanceKm;

  bool get isOpen => status == 'new' || status == 'in_progress';
  bool get isAcknowledged => assignmentStatus == AssignmentStatus.acknowledged;
  bool get awaitingAcknowledgement =>
      assignmentStatus == AssignmentStatus.assigned;

  Alert copyWith({AssignmentStatus? assignmentStatus, double? distanceKm}) =>
      Alert(
        id: id,
        zoneId: zoneId,
        zoneName: zoneName,
        confidence: confidence,
        priority: priority,
        summary: summary,
        centroidLatitude: centroidLatitude,
        centroidLongitude: centroidLongitude,
        status: status,
        assignmentStatus: assignmentStatus ?? this.assignmentStatus,
        createdAt: createdAt,
        distanceKm: distanceKm ?? this.distanceKm,
      );

  Alert withDistanceFrom(double latitude, double longitude) => copyWith(
    distanceKm: _haversineKm(
      latitude,
      longitude,
      centroidLatitude,
      centroidLongitude,
    ),
  );

  factory Alert.fromJson(Map<String, dynamic> json) {
    final zoneId = json['zone_id'] as String;
    return Alert(
      id: json['alert_id'] as String,
      zoneId: zoneId,
      zoneName:
          json['zone_name'] as String? ?? 'Zone ${zoneId.substring(0, 8)}',
      confidence: (json['confidence'] as num).toDouble(),
      priority: json['priority'] as String? ?? 'low',
      summary: json['summary'] as String? ?? '',
      centroidLatitude: (json['centroid_latitude'] as num).toDouble(),
      centroidLongitude: (json['centroid_longitude'] as num).toDouble(),
      status: json['status'] as String? ?? 'new',
      assignmentStatus: AssignmentStatus.parse(
        json['assignment_status'] as String?,
      ),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }
}

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0088;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * earthRadiusKm * math.asin(math.min(1.0, math.sqrt(a)));
}
