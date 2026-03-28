/// POI (Point of Interest) — Yakıt, Market, Tamir, Yol Yapımı
enum PoiType { fuel, evCharge, market, rvRepair, gearStore, roadWork }

class PoiPoint {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final PoiType type;
  final String phone;
  final String hours;
  final String address;
  final double distanceMiles;

  const PoiPoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.phone = '',
    this.hours = '',
    this.address = '',
    this.distanceMiles = 0.0,
  });

  factory PoiPoint.fromOverpass(
    Map<String, dynamic> json,
    PoiType type,
    double distMiles,
  ) {
    final tags = json['tags'] as Map<String, dynamic>? ?? {};
    final lat = (json['lat'] as num?)?.toDouble() ?? 0.0;
    final lon = (json['lon'] as num?)?.toDouble() ?? 0.0;
    return PoiPoint(
      id: json['id'].toString(),
      name: tags['name'] ?? tags['brand'] ?? typeLabel(type),
      latitude: lat,
      longitude: lon,
      type: type,
      phone: tags['phone'] ?? tags['contact:phone'] ?? '',
      hours: tags['opening_hours'] ?? '',
      address: [
        tags['addr:housenumber'],
        tags['addr:street'],
        tags['addr:city'],
      ].where((e) => e != null && e.isNotEmpty).join(', '),
      distanceMiles: distMiles,
    );
  }

  static String typeLabel(PoiType t) => switch (t) {
    PoiType.fuel => 'Fuel Station',
    PoiType.evCharge => 'EV Charger',
    PoiType.market => 'Market',
    PoiType.rvRepair => 'RV Repair',
    PoiType.gearStore => 'Gear Store',
    PoiType.roadWork => 'Road Work',
  };

  String get displayLabel => typeLabel(type);

  /// Haritada gösterilecek ikon
  String get emoji => switch (type) {
    PoiType.fuel => '⛽',
    PoiType.evCharge => '🔌',
    PoiType.market => '🛒',
    PoiType.rvRepair => '🔧',
    PoiType.gearStore => '🎒',
    PoiType.roadWork => '🚧',
  };
}
