import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/campground.dart';
import '../models/fire_point.dart';

class CacheService {
  SharedPreferences? _prefs;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  bool get isInitialized => _prefs != null;
  
  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('CacheService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  bool canWorkOffline() => prefs.containsKey('cached_campgrounds');

  Future<void> cacheCampgrounds(List<Campground> camps) async {
    final data = camps.map((c) => c.toJson()).toList();
    await prefs.setString('cached_campgrounds', jsonEncode(data));
  }

  List<Campground> getCachedCampgrounds() {
    final str = prefs.getString('cached_campgrounds');
    if (str == null) return [];
    final List data = jsonDecode(str);
    return data.map((item) => Campground.fromJson(item)).toList();
  }

  Future<void> cacheFirePoints(List<FirePoint> fires) async {
    final data = fires.map((f) => f.toJson()).toList();
    await prefs.setString('cached_fire_points', jsonEncode(data));
  }

  List<FirePoint> getCachedFirePoints() {
    final str = prefs.getString('cached_fire_points');
    if (str == null) return [];
    final List data = jsonDecode(str);
    return data.map((item) => FirePoint.fromJson(item)).toList();
  }

  Future<void> cacheSafetyStatus(String status, String message) async {
    await prefs.setString('safety_status', status);
    await prefs.setString('safety_message', message);
  }

  Map<String, String> getCachedSafetyStatus() {
    return {
      'status': prefs.getString('safety_status') ?? 'UNKNOWN',
      'message': prefs.getString('safety_message') ?? ''
    };
  }

  Future<void> cacheAll(List<Campground> camps, List<FirePoint> fires, Map<String, dynamic> safety) async {
    await cacheCampgrounds(camps);
    await cacheFirePoints(fires);
    await cacheSafetyStatus(safety['status']?.toString() ?? 'UNKNOWN', safety['message']?.toString() ?? '');
  }

  Future<void> clearCache() async => await prefs.clear();
}
