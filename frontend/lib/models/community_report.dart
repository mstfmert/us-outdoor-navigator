/// Kullanıcı tarafından oluşturulan saha raporu
enum ReportType { bearSighting, roadClosed, fireHazard, other }

class CommunityReport {
  final String id;
  final double latitude;
  final double longitude;
  final ReportType type;
  final String description;
  final DateTime timestamp;

  const CommunityReport({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.description = '',
    required this.timestamp,
  });

  String get emoji => switch (type) {
    ReportType.bearSighting => '🐻',
    ReportType.roadClosed => '🚫',
    ReportType.fireHazard => '🔥',
    ReportType.other => '⚠️',
  };

  String get label => switch (type) {
    ReportType.bearSighting => 'Bear Sighting',
    ReportType.roadClosed => 'Road Closed',
    ReportType.fireHazard => 'Fire Hazard',
    ReportType.other => 'Alert',
  };

  factory CommunityReport.fromJson(Map<String, dynamic> json) {
    return CommunityReport(
      id: json['id']?.toString() ?? '',
      latitude: (json['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['lon'] as num?)?.toDouble() ?? 0.0,
      type: _typeFromString(json['report_type'] ?? ''),
      description: json['description'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'lat': latitude,
    'lon': longitude,
    'report_type': _typeToString(type),
    'description': description,
    'timestamp': timestamp.toIso8601String(),
  };

  static ReportType _typeFromString(String s) => switch (s) {
    'bear_sighting' => ReportType.bearSighting,
    'road_closed' => ReportType.roadClosed,
    'fire_hazard' => ReportType.fireHazard,
    _ => ReportType.other,
  };

  static String _typeToString(ReportType t) => switch (t) {
    ReportType.bearSighting => 'bear_sighting',
    ReportType.roadClosed => 'road_closed',
    ReportType.fireHazard => 'fire_hazard',
    ReportType.other => 'other',
  };
}
