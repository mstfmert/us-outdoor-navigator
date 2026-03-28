class Location {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;

  Location({
    required this.latitude,
    required this.longitude,
    this.address,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'lat': latitude,
    'lon': longitude,
    'address': address,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    latitude: json['lat']?.toDouble() ?? 0.0,
    longitude: json['lon']?.toDouble() ?? 0.0,
    address: json['address'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}