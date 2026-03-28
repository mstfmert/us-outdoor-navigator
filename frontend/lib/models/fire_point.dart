class FirePoint {
  final String id;
  final double latitude;
  final double longitude;
  final double intensity; // Kelvin
  final double confidence;
  final double distance; // miles to user
  final DateTime detectedTime;

  FirePoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.intensity,
    required this.confidence,
    this.distance = 0.0,
    DateTime? detectedTime,
  }) : detectedTime = detectedTime ?? DateTime.now();

  String get dangerLevel {
    if (intensity > 400) return 'HIGH';
    if (intensity > 300) return 'MEDIUM';
    return 'LOW';
  }

  String get distanceDisplay {
    if (distance == 0) return 'Distance unknown';
    return '${distance.toStringAsFixed(1)} mi away';
  }

  String get confidenceDisplay {
    if (confidence > 80) return 'High confidence';
    if (confidence > 50) return 'Medium confidence';
    return 'Low confidence';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'lat': latitude,
    'lon': longitude,
    'intensity': intensity,
    'confidence': confidence,
    'distance': distance,
    'detected_time': detectedTime.toIso8601String(),
  };

  factory FirePoint.fromJson(Map<String, dynamic> json) => FirePoint(
    id: json['id']?.toString() ?? '',
    latitude: json['lat']?.toDouble() ?? 0.0,
    longitude: json['lon']?.toDouble() ?? 0.0,
    intensity: json['intensity']?.toDouble() ?? 0.0,
    confidence: json['confidence']?.toDouble() ?? 0.0,
    distance: json['distance']?.toDouble() ?? 0.0,
    detectedTime: json['detected_time'] != null 
      ? DateTime.parse(json['detected_time']) 
      : null,
  );
}