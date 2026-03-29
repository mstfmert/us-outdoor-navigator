import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:geolocator/geolocator.dart';
import '../models/location.dart';
import '../models/campground.dart';
import '../models/fire_point.dart';
import '../models/poi_point.dart';
import '../models/community_report.dart';
import '../config/app_config.dart';

class ApiService {
  // ── Dynamic API URL — AppConfig üzerinden yönetilir ──────────────────
  // Local:       http://10.0.2.2:8000 (Android) / localhost (iOS/Web)
  // Production:  https://us-outdoor-api.railway.app
  // Override:    flutter run --dart-define=API_URL=https://...
  static String get _baseUrl => AppConfig.apiBaseUrl;

  static const Duration _timeout = Duration(seconds: 15);

  // ── Offline Resilience ────────────────────────────────────────────────
  // Herhangi bir API çağrısı başarısız olduğunda false olur.
  // UI bu değeri dinleyerek "Offline Mod" banner'ı gösterebilir.
  static bool isOnline = true;

  static void _markOnline() {
    if (!isOnline) {
      isOnline = true;
      debugPrint('🌐 Backend bağlantısı yeniden kuruldu');
    }
  }

  static void _markOffline(dynamic error) {
    if (isOnline) {
      isOnline = false;
      debugPrint('📵 Backend offline — Cache modu aktif: $error');
    }
  }

  /// Backend sağlık kontrolü — UI bunu periyodik olarak çağırabilir.
  static Future<bool> checkHealth() async {
    try {
      final r = await http
          .get(Uri.parse('${AppConfig.apiBaseUrl}/'))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        _markOnline();
        return true;
      }
    } catch (e) {
      _markOffline(e);
    }
    return false;
  }

  final http.Client _client;
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> getFullReport({
    required double lat,
    required double lon,
    String userId = 'pro_user_2026',
    double maxCampPrice = 100.0,
    double? rvLength,
  }) async {
    try {
      final body = {
        'lat': lat,
        'lon': lon,
        'user_id': userId,
        'max_camp_price': maxCampPrice,
      };
      if (rvLength != null) {
        body['rv_length'] = rvLength;
      }
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/get_full_report'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('API error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed report: $e');
    }
  }

  /// Kullanıcının gerçek GPS konumunu alır.
  /// İzin verilmezse veya hata oluşursa Joshua Tree, CA fallback olarak döner.
  Future<Location> getUserLocation() async {
    try {
      // 1) Konum servisi aktif mi?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('📍 GPS: Konum servisi kapalı → Joshua Tree fallback');
        return _joshuaTreeFallback();
      }

      // 2) Mevcut izni kontrol et
      LocationPermission permission = await Geolocator.checkPermission();

      // 3) Gerekirse izin iste
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('📍 GPS: İzin reddedildi → Joshua Tree fallback');
          return _joshuaTreeFallback();
        }
      }

      // 4) Kalıcı olarak reddedildiyse ayarlara yönlendir
      if (permission == LocationPermission.deniedForever) {
        debugPrint('📍 GPS: İzin kalıcı reddedildi → Joshua Tree fallback');
        return _joshuaTreeFallback();
      }

      // 5) Gerçek konumu al (10 sn timeout ile)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10));

      debugPrint(
        '📍 GPS: Gerçek konum alındı → ${position.latitude}, ${position.longitude}',
      );
      return Location(
        latitude: position.latitude,
        longitude: position.longitude,
        address: 'Current Location',
      );
    } catch (e) {
      debugPrint('📍 GPS Hatası: $e → Joshua Tree fallback');
      return _joshuaTreeFallback();
    }
  }

  /// Fallback: Joshua Tree Ulusal Parkı (Güney California)
  Location _joshuaTreeFallback() => Location(
    latitude: 33.8734,
    longitude: -115.9010,
    address: 'Joshua Tree, CA (Default)',
  );

  List<Campground> parseCampgrounds(Map<String, dynamic> data) {
    final logistics = data['logistics'] as List?;
    if (logistics == null) return [];
    return logistics.map((item) {
      final campInfo = item['camp_info'] as Map<String, dynamic>;
      return Campground(
        id: campInfo['id'].toString(),
        name: campInfo['name'] ?? 'Unknown',
        latitude: (campInfo['lat'] as num?)?.toDouble() ?? 0.0,
        longitude: (campInfo['lon'] as num?)?.toDouble() ?? 0.0,
        pricePerNight: (campInfo['price_per_night'] as num?)?.toDouble() ?? 0.0,
        maxRvLength: (campInfo['max_rv_length'] as num?)?.toDouble() ?? 0.0,
        amenities: List<String>.from(campInfo['amenities'] ?? []),
        hasWater: campInfo['has_water'] ?? false,
        distanceToUser: (item['distance_to_user'] as num?)?.toDouble() ?? 0.0,
        nearestFuelMiles:
            (item['nearest_fuel_miles'] as num?)?.toDouble() ?? 0.0,
        fuelStationName: item['fuel_station_name']?.toString() ?? '',
      );
    }).toList();
  }

  List<FirePoint> parseFirePoints(Map<String, dynamic> data) {
    final safety = data['safety'];
    if (safety == null ||
        (safety['status'] != 'DANGER' && safety['status'] != 'WARNING')) {
      return [];
    }
    final threats = safety['threats'] as List?;
    if (threats == null) return [];
    return threats.asMap().entries.map((entry) {
      final idx = entry.key;
      final threat = entry.value as Map<String, dynamic>;
      return FirePoint(
        id: 'fire_$idx',
        latitude: (threat['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (threat['longitude'] as num?)?.toDouble() ?? 0.0,
        intensity: (threat['intensity'] as num?)?.toDouble() ?? 0.0,
        confidence: (threat['confidence'] as num?)?.toDouble() ?? 0.0,
        distance: (threat['distance'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  /// POI verisi çeker — backend /get_poi, başarısız → Overpass API fallback
  /// poiType: 'fuel' | 'ev' | 'market' | 'repair'
  Future<List<PoiPoint>> getPoiPoints({
    required double lat,
    required double lon,
    required String poiType,
    int radiusM = 50000,
  }) async {
    // 1. Backend dene
    try {
      final uri = Uri.parse('$_baseUrl/get_poi').replace(
        queryParameters: {
          'lat': lat.toString(),
          'lon': lon.toString(),
          'poi_type': poiType,
          'radius_m': radiusM.toString(),
        },
      );
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        _markOnline();
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final pois = _parsePoiList(data['pois'] ?? [], poiType);
        if (pois.isNotEmpty) return pois;
      }
    } catch (e) {
      _markOffline(e);
      debugPrint('⚠️ Backend POI failed ($poiType) → Overpass fallback: $e');
    }
    // 2. Overpass API fallback — her zaman çalışır
    debugPrint('🔄 Overpass POI query: $poiType');
    return _getPoiFromOverpass(
      lat: lat,
      lon: lon,
      poiType: poiType,
      radiusM: radiusM,
    );
  }

  List<PoiPoint> _parsePoiList(List<dynamic> rawList, String typeStr) {
    final poiType = _poiTypeFromString(typeStr);
    return rawList.map((raw) {
      final m = raw as Map<String, dynamic>;
      return PoiPoint.fromOverpass(
        m,
        poiType,
        (m['distance_miles'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  PoiType _poiTypeFromString(String s) => switch (s) {
    'fuel' => PoiType.fuel,
    'ev' => PoiType.evCharge,
    'market' => PoiType.market,
    'repair' => PoiType.rvRepair,
    _ => PoiType.fuel,
  };

  /// Topluluk raporu gönder — POST /report
  Future<CommunityReport?> submitReport({
    required double lat,
    required double lon,
    required ReportType type,
    String description = '',
    String userId = 'anonymous',
  }) async {
    try {
      final body = {
        'lat': lat,
        'lon': lon,
        'report_type': _reportTypeStr(type),
        'description': description,
        'user_id': userId,
      };
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/report'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CommunityReport.fromJson(data['report'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ submitReport hatası: $e');
      return null;
    }
  }

  /// Yakın topluluk raporlarını çek — GET /get_reports
  Future<List<CommunityReport>> getCommunityReports({
    required double lat,
    required double lon,
    int radiusM = 150000,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/get_reports').replace(
        queryParameters: {
          'lat': lat.toString(),
          'lon': lon.toString(),
          'radius_m': radiusM.toString(),
        },
      );
      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['reports'] as List? ?? [];
      return list
          .map((r) => CommunityReport.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('⚠️ getCommunityReports hatası: $e');
      return [];
    }
  }

  String _reportTypeStr(ReportType t) => switch (t) {
    ReportType.bearSighting => 'bear_sighting',
    ReportType.roadClosed => 'road_closed',
    ReportType.fireHazard => 'fire_hazard',
    ReportType.other => 'other',
  };

  /// Bounding Box ile kamp sorgula — GET /get_camps_in_view
  /// [isPremium]: true → tüm 50 eyalet, false → sadece CA/AZ/UT (free tier)
  /// Offline durumunda boş liste döner ve isOnline=false işaretlenir.
  Future<List<Map<String, dynamic>>> getCampsInView({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    int limit = 300,
    bool isPremium = false,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/get_camps_in_view').replace(
        queryParameters: {
          'min_lat': minLat.toString(),
          'max_lat': maxLat.toString(),
          'min_lon': minLon.toString(),
          'max_lon': maxLon.toString(),
          'limit': limit.toString(),
          'is_premium': isPremium.toString(), // ← premium eyalet kilidi
        },
      );
      final r = await _client.get(uri).timeout(_timeout);
      if (r.statusCode == 200) {
        _markOnline();
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['camps'] ?? []);
      }
      _markOffline('HTTP ${r.statusCode}');
    } catch (e) {
      _markOffline(e);
      debugPrint('⚠️ getCampsInView offline: $e');
    }
    return [];
  }

  /// BBox kamp listesini Campground modeline parse et
  List<Campground> parseCampsInView(List<Map<String, dynamic>> raw) {
    return raw.map((m) {
      return Campground(
        id: m['id']?.toString() ?? '',
        name: m['name'] ?? 'Unknown',
        latitude: (m['lat'] as num?)?.toDouble() ?? 0.0,
        longitude: (m['lon'] as num?)?.toDouble() ?? 0.0,
        pricePerNight: (m['price_per_night'] as num?)?.toDouble() ?? 0.0,
        maxRvLength: (m['max_rv_length'] as num?)?.toDouble() ?? 0.0,
        amenities: List<String>.from(m['amenities'] ?? []),
        hasWater: m['has_water'] ?? false,
        distanceToUser: 0.0,
        nearestFuelMiles: 0.0,
        fuelStationName: '',
      );
    }).toList();
  }

  // ── YENİ SERVİSLER ────────────────────────────────────────────────────────

  /// NOAA/NWS Gece Hava Durumu Raporu — GET /get_night_weather
  Future<Map<String, dynamic>?> getNightWeather({
    required double lat,
    required double lon,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/get_night_weather').replace(
        queryParameters: {'lat': lat.toString(), 'lon': lon.toString()},
      );
      final r = await _client.get(uri).timeout(_timeout);
      if (r.statusCode == 200)
        return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('⚠️ getNightWeather: $e');
    }
    return null;
  }

  /// SOS / PANIC Tetikle — POST /sos
  Future<Map<String, dynamic>?> triggerSos({
    required double lat,
    required double lon,
    required String userId,
    String emergencyContact = '',
    String userName = 'Unknown User',
  }) async {
    try {
      final r = await _client
          .post(
            Uri.parse('$_baseUrl/sos'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'lat': lat,
              'lon': lon,
              'user_id': userId,
              'emergency_contact': emergencyContact,
              'user_name': userName,
              'message': 'PANIC BUTTON PRESSED',
            }),
          )
          .timeout(_timeout);
      if (r.statusCode == 200)
        return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('⚠️ triggerSos: $e');
    }
    return null;
  }

  /// Güneş Paneli Verimlilik Tahmini — GET /get_solar_estimate
  Future<Map<String, dynamic>?> getSolarEstimate({
    required double lat,
    required double lon,
    String treeCover = 'open',
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/get_solar_estimate').replace(
        queryParameters: {
          'lat': lat.toString(),
          'lon': lon.toString(),
          'tree_cover': treeCover,
        },
      );
      final r = await _client.get(uri).timeout(_timeout);
      if (r.statusCode == 200)
        return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('⚠️ getSolarEstimate: $e');
    }
    return null;
  }

  /// RV Lojistik — GET /get_rv_logistics (dump station, temiz su, rv yakıt)
  Future<Map<String, dynamic>?> getRvLogistics({
    required double lat,
    required double lon,
    int radiusM = 80000,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/get_rv_logistics').replace(
        queryParameters: {
          'lat': lat.toString(),
          'lon': lon.toString(),
          'radius_m': radiusM.toString(),
        },
      );
      final r = await _client.get(uri).timeout(_timeout);
      if (r.statusCode == 200)
        return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('⚠️ getRvLogistics: $e');
    }
    return null;
  }

  /// Hesap & Veri Silme — DELETE /delete_account
  Future<void> deleteAccount({required String userId}) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/delete_account',
      ).replace(queryParameters: {'user_id': userId});
      final resp = await http.delete(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) {
        throw Exception('Delete account failed: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ deleteAccount: $e');
      // Hata fırlatma — offline/network sorununda sessizce devam et
    }
  }

  /// RV Rota (Boyut Kontrolü) — GET /get_route
  Future<Map<String, dynamic>?> getRvRoute({
    required double originLat,
    required double originLon,
    required double destLat,
    required double destLon,
    double rvHeightFt = 13.5,
    double rvWidthFt = 8.5,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/get_route').replace(
        queryParameters: {
          'origin_lat': originLat.toString(),
          'origin_lon': originLon.toString(),
          'dest_lat': destLat.toString(),
          'dest_lon': destLon.toString(),
          'rv_height_ft': rvHeightFt.toString(),
          'rv_width_ft': rvWidthFt.toString(),
        },
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) return json.decode(resp.body);
    } catch (e) {
      debugPrint('⚠️ getRvRoute: $e');
    }
    return null;
  }

  /// Kamp Kuralları — GET /get_camp_rules/{camp_id}
  Future<Map<String, dynamic>?> getCampRules(String campId) async {
    try {
      final r = await _client
          .get(Uri.parse('$_baseUrl/get_camp_rules/$campId'))
          .timeout(_timeout);
      if (r.statusCode == 200)
        return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('⚠️ getCampRules: $e');
    }
    return null;
  }

  /// Dead Man's Switch Check-in — POST /checkin
  Future<bool> doCheckin({
    required double lat,
    required double lon,
    required String userId,
    int nextCheckinHours = 24,
  }) async {
    try {
      final r = await _client
          .post(
            Uri.parse('$_baseUrl/checkin'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'lat': lat,
              'lon': lon,
              'user_id': userId,
              'next_checkin_hours': nextCheckinHours,
            }),
          )
          .timeout(_timeout);
      return r.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ doCheckin: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // OVERPASS API DIRECT FALLBACK — Backend olmadan çalışır
  // ══════════════════════════════════════════════════════════════════════════

  /// Overpass API üzerinden kamp alanlarını direkt çek
  Future<List<Campground>> getCampgroundsFromOverpass(
    double lat,
    double lon, {
    int radiusM = 80000,
  }) async {
    try {
      final query =
          '[out:json][timeout:25];'
          '(node["tourism"="camp_site"](around:$radiusM,$lat,$lon);'
          'way["tourism"="camp_site"](around:$radiusM,$lat,$lon););'
          'out center 50;';
      final response = await _client
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'data=${Uri.encodeComponent(query)}',
          )
          .timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = data['elements'] as List? ?? [];
      int idx = 0;
      return elements.take(50).map((el) {
        final m = el as Map<String, dynamic>;
        final elLat = ((m['lat'] ?? m['center']?['lat'] ?? lat) as num)
            .toDouble();
        final elLon = ((m['lon'] ?? m['center']?['lon'] ?? lon) as num)
            .toDouble();
        final tags = m['tags'] as Map<String, dynamic>? ?? {};
        final hasWater =
            tags.containsKey('drinking_water') ||
            tags['drinking_water'] == 'yes';
        final name = tags['name'] as String? ?? 'Campsite #${++idx}';
        return Campground(
          id: 'osm_${m["id"]}',
          name: name,
          latitude: elLat,
          longitude: elLon,
          pricePerNight: 0.0,
          maxRvLength: 40.0,
          amenities: hasWater ? ['water', 'fire_ring'] : ['fire_ring'],
          hasWater: hasWater,
          distanceToUser: 0.0,
          nearestFuelMiles: 10.0,
          fuelStationName: '',
        );
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Overpass camps error: $e');
      return [];
    }
  }

  /// Overpass API üzerinden POI çek — private fallback
  Future<List<PoiPoint>> _getPoiFromOverpass({
    required double lat,
    required double lon,
    required String poiType,
    int radiusM = 50000,
  }) async {
    try {
      final tag = switch (poiType) {
        'fuel' => '"amenity"="fuel"',
        'ev' => '"amenity"="charging_station"',
        'market' => '"shop"="supermarket"',
        'repair' => '"shop"="car_repair"',
        _ => '"amenity"="fuel"',
      };
      final query =
          '[out:json][timeout:25];'
          '(node[$tag](around:$radiusM,$lat,$lon);'
          'way[$tag](around:$radiusM,$lat,$lon););'
          'out center 20;';
      final response = await _client
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'data=${Uri.encodeComponent(query)}',
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = data['elements'] as List? ?? [];
      final overpassPoiType = _poiTypeFromString(poiType);
      return elements.take(25).map((el) {
        final m = el as Map<String, dynamic>;
        final elLat = ((m['lat'] ?? m['center']?['lat'] ?? lat) as num)
            .toDouble();
        final elLon = ((m['lon'] ?? m['center']?['lon'] ?? lon) as num)
            .toDouble();
        final tags = m['tags'] as Map<String, dynamic>? ?? {};
        final defaultName = switch (poiType) {
          'fuel' => 'Gas Station',
          'ev' => 'EV Charging',
          'market' => 'Supermarket',
          'repair' => 'Auto Repair',
          _ => 'POI',
        };
        return PoiPoint.fromOverpass(
          {
            'id': m['id'].toString(),
            'lat': elLat,
            'lon': elLon,
            'tags': {'name': tags['name'] ?? defaultName, ...tags},
          },
          overpassPoiType,
          0.0,
        );
      }).toList();
    } catch (e) {
      debugPrint('⚠️ Overpass POI error: $e');
      return [];
    }
  }

  void dispose() => _client.close();
}
