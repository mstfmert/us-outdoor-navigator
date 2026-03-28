class Campground {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double pricePerNight;
  final double maxRvLength; // feet
  final List<String> amenities;
  final bool hasWater;
  final double distanceToUser; // miles
  final double nearestFuelMiles;
  final String fuelStationName;

  Campground({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.pricePerNight,
    required this.maxRvLength,
    this.amenities = const [],
    this.hasWater = false,
    this.distanceToUser = 0.0,
    this.nearestFuelMiles = 0.0,
    this.fuelStationName = '',
  });

  bool get isFree => pricePerNight == 0;

  String get priceDisplay {
    if (isFree) return 'FREE';
    return '\$$pricePerNight/night';
  }

  String get rvLengthDisplay {
    if (maxRvLength == 0) return 'No RV limit';
    return 'Max RV: ${maxRvLength}ft';
  }

  String get fuelInfo {
    if (nearestFuelMiles == 0) return 'No fuel data';
    return 'Fuel: $fuelStationName ($nearestFuelMiles mi)';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'lat': latitude,
    'lon': longitude,
    'price_per_night': pricePerNight,
    'max_rv_length': maxRvLength,
    'amenities': amenities,
    'has_water': hasWater,
    'distance_to_user': distanceToUser,
    'nearest_fuel_miles': nearestFuelMiles,
    'fuel_station_name': fuelStationName,
  };

  factory Campground.fromJson(Map<String, dynamic> json) => Campground(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Unknown Campground',
    latitude: json['lat']?.toDouble() ?? 0.0,
    longitude: json['lon']?.toDouble() ?? 0.0,
    pricePerNight: json['price_per_night']?.toDouble() ?? 0.0,
    maxRvLength: json['max_rv_length']?.toDouble() ?? 0.0,
    amenities: List<String>.from(json['amenities'] ?? []),
    hasWater: json['has_water'] ?? false,
    distanceToUser: json['distance_to_user']?.toDouble() ?? 0.0,
    nearestFuelMiles: json['nearest_fuel_miles']?.toDouble() ?? 0.0,
    fuelStationName: json['fuel_station_name']?.toString() ?? '',
  );
}