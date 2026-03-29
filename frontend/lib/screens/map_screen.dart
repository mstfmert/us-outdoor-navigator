// map_screen.dart — US Outdoor Navigator v6.1
// ✅ Tüm butonlar SAĞ PANEL'de — asla üst üste gelmez
// ✅ Panel A (right:80) : Aksiyon butonları + SOS + alt kontroller
// ✅ Panel B (right:8)  : LayerSidebar (scrollable, 60px geniş)
// ✅ Overpass API fallback — backend olmadan gerçek kamp/POI verisi
// ✅ Demo campground fallback — tam offline durumda bile veri gösterilir
import 'dart:async';
import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/safety_bar_widget.dart';
import '../widgets/report_button.dart';
import '../widgets/offline_indicator.dart';
import '../widgets/map_widget.dart';
import '../widgets/layer_sidebar.dart';
import '../widgets/poi_info_panel.dart';
import '../widgets/sos_button.dart';
import '../widgets/weather_ribbon.dart';
import '../widgets/logistics_sheet.dart';
import '../widgets/community_report_dialog.dart';
import '../widgets/offline_download_widget.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/subscription_service.dart';
import '../models/app_state.dart';
import '../models/campground.dart';
import 'profile_screen.dart';
import 'paywall_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isLoading = false;
  double _rvLength = 35.0;
  final TextEditingController _rvLengthController = TextEditingController();
  String _userId = 'user_anonymous';

  Timer? _bboxTimer;
  Timer? _healthTimer;

  // ── Harita viewport merkezi — TÜM API sorguları bu koordinatı kullanır ──
  // GPS konumu değil! Kullanıcının bakttığı harita merkezi.
  // Sırbıstan'dan geliştiren → Joshua Tree'de başlar, harita kaydıkça güncellenir.
  LatLng _mapCenter = const LatLng(33.8734, -115.9010); // Joshua Tree, CA

  Map<String, dynamic>? _weatherData;
  Map<String, dynamic>? _solarData;
  Map<String, dynamic>? _rvLogisticsData;
  Map<String, dynamic>? _campRulesData;

  @override
  void initState() {
    super.initState();
    _rvLengthController.text = _rvLength.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initUserId();
      _initializeData();
      _fetchWeatherData();
      _startHealthCheck();
    });
  }

  Future<void> _initUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? stored = prefs.getString('device_user_id');
    if (stored == null || stored.isEmpty) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final rnd = Random().nextInt(9000) + 1000;
      stored = 'user_${ts}_$rnd';
      await prefs.setString('device_user_id', stored);
    }
    if (mounted) setState(() => _userId = stored!);
  }

  void _startHealthCheck() {
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!mounted) return;
      final wasOnline = ApiService.isOnline;
      final nowOnline = await ApiService.checkHealth();
      if (!mounted) return;
      final appState = context.read<AppState>();
      appState.setOfflineMode(!nowOnline);
      if (wasOnline && !nowOnline) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Backend offline — Cached/Overpass data active'),
              ],
            ),
            backgroundColor: Color(0xFFE65100),
            duration: Duration(seconds: 4),
          ),
        );
      } else if (!wasOnline && nowOnline) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('✅ Backend reconnected — Live data active'),
              ],
            ),
            backgroundColor: Color(0xFF1B5E20),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _bboxTimer?.cancel();
    _healthTimer?.cancel();
    _rvLengthController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    final appState = context.read<AppState>();
    final cacheService = context.read<CacheService>();
    final apiService = context.read<ApiService>();
    appState.setLoading(true);

    // ── KRİTİK: Sorgular için _mapCenter kullan, GPS sadece mavi nokta içindir ──
    // Sırbıstan'dan geliştirirken ABD haritasına kaydırınca bu koordinatlar güncellenir
    // İlk açılışta Joshua Tree, CA (33.8734, -115.9010) — ABD'nin varsayılan merkezi
    double lat = _mapCenter.latitude;
    double lon = _mapCenter.longitude;

    try {
      // 1. Offline cache kontrolü
      if (cacheService.canWorkOffline() && appState.isOfflineMode) {
        appState.setCampgrounds(cacheService.getCachedCampgrounds());
        appState.setFirePoints(cacheService.getCachedFirePoints());
        final s = cacheService.getCachedSafetyStatus();
        appState.setSafetyStatus(
          s['status'] ?? 'SAFE',
          s['message'] ?? 'Cached data',
        );
        if (appState.campgrounds.isEmpty) {
          appState.setCampgrounds(_buildDemoCampgrounds(lat, lon));
        }
      } else {
        // 2. GPS al — SADECE haritadaki mavi nokta için (sorgular için değil!)
        try {
          final loc = await apiService.getUserLocation();
          appState.setCurrentLocation(loc);
          // ⚠️ lat/lon GÜNCELLEME YOK — _mapCenter (Joshua Tree/harita merkezi) kullanılır
          // GPS Sırbıstan (44°N, 21°E) olsa bile sorgular Joshua Tree'den yapılır
        } catch (_) {}

        // 3. Backend API dene — _mapCenter koordinatlarıyla
        bool backendSuccess = false;
        try {
          final data = await apiService.getFullReport(
            lat: lat,
            lon: lon,
            rvLength: _rvLength,
          );
          final camps = apiService.parseCampgrounds(data);
          final fires = apiService.parseFirePoints(data);
          final safety = data['safety'] as Map<String, dynamic>? ?? {};
          if (safety['status'] == 'DANGER') HapticFeedback.heavyImpact();
          appState.setSafetyStatus(
            safety['status'] ?? 'SAFE',
            safety['message'] ?? 'Area clear',
          );
          appState.setCampgrounds(camps);
          appState.setFirePoints(fires);
          await cacheService.cacheAll(camps, fires, safety);
          backendSuccess = true;
        } catch (e) {
          debugPrint('⚠️ Backend getFullReport failed: $e');
        }

        // 4. Backend başarısız → Overpass API'den gerçek kamp verisi
        if (!backendSuccess) {
          appState.setSafetyStatus('SAFE', '📡 Live data via Overpass API');
          final overpassCamps = await apiService.getCampgroundsFromOverpass(
            lat,
            lon,
          );
          if (overpassCamps.isNotEmpty) {
            appState.setCampgrounds(overpassCamps);
            debugPrint('✅ Overpass: ${overpassCamps.length} kamp yüklendi');
          } else {
            // 5. Tamamen offline → demo data
            appState.setCampgrounds(_buildDemoCampgrounds(lat, lon));
            debugPrint('ℹ️ Demo kamp verisi gösteriliyor');
          }
        }
      }
    } catch (e) {
      appState.setError(null); // Hata gösterme, sadece demo göster
      appState.setSafetyStatus(
        'SAFE',
        'Demo mode — connect to internet for live data',
      );
      appState.setCampgrounds(_buildDemoCampgrounds(lat, lon));
    } finally {
      appState.setLoading(false);
    }
  }

  /// Demo campground data — her zaman çalışır, internet gerekmez
  List<Campground> _buildDemoCampgrounds(double lat, double lon) {
    final demos = [
      ['Joshua Tree North Camp', 0.08, 0.06, 15.0, true, 35],
      ['Hidden Valley Campground', 0.12, -0.12, 25.0, false, 40],
      ['Jumbo Rocks Camp', -0.06, 0.14, 0.0, false, 30],
      ['Ryan Campground', -0.10, -0.08, 10.0, true, 45],
      ['White Tank Camp', 0.03, 0.22, 5.0, false, 0],
      ['Cottonwood Springs', -0.18, 0.04, 20.0, true, 35],
      ['Belle Campground', 0.15, 0.18, 8.0, false, 25],
      ['Sheep Pass Camp', -0.04, -0.20, 0.0, false, 30],
    ];

    return demos.asMap().entries.map((entry) {
      final i = entry.key;
      final d = entry.value;
      return Campground(
        id: 'demo_$i',
        name: d[0] as String,
        latitude: lat + (d[1] as double),
        longitude: lon + (d[2] as double),
        pricePerNight: d[3] as double,
        maxRvLength: (d[5] as int).toDouble(),
        amenities: (d[4] as bool)
            ? ['water', 'electric', 'restrooms']
            : ['fire_ring'],
        hasWater: d[4] as bool,
        distanceToUser: (i + 1) * 2.8,
        nearestFuelMiles: (i + 2) * 4.0,
        fuelStationName: 'Local Gas Station',
      );
    }).toList();
  }

  Future<void> _fetchWeatherData() async {
    final appState = context.read<AppState>();
    final apiService = context.read<ApiService>();
    final lat = appState.currentLocation?.latitude ?? 33.8734;
    final lon = appState.currentLocation?.longitude ?? -115.9010;
    try {
      final weather = await apiService.getNightWeather(lat: lat, lon: lon);
      if (mounted) setState(() => _weatherData = weather);
    } catch (_) {}
  }

  Future<void> _fetchCampDetails(String campId, double lat, double lon) async {
    final apiService = context.read<ApiService>();
    try {
      final results = await Future.wait([
        apiService.getCampRules(campId),
        apiService.getSolarEstimate(lat: lat, lon: lon),
        apiService.getRvLogistics(lat: lat, lon: lon, radiusM: 80000),
      ]);
      if (mounted) {
        setState(() {
          _campRulesData = results[0];
          _solarData = results[1];
          _rvLogisticsData = results[2];
        });
      }
    } catch (_) {}
  }

  void _onMapBoundsChanged(LatLngBounds bounds) {
    // ── VIEWPORT MERKEZİNİ KAYDET — TÜM sorgular bu koordinatı kullanır ──
    // GPS konumu değil → kullanıcının baktığı harita merkezi
    if (mounted) setState(() => _mapCenter = bounds.center);

    _bboxTimer?.cancel();
    _bboxTimer = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      final appState = context.read<AppState>();
      final apiService = context.read<ApiService>();
      final subSvc = context.read<SubscriptionService>();
      if (appState.isOfflineMode) return;
      try {
        final raw = await apiService.getCampsInView(
          minLat: bounds.south,
          maxLat: bounds.north,
          minLon: bounds.west,
          maxLon: bounds.east,
          limit: 300,
          isPremium: subSvc.isPremium,
        );
        if (raw.isNotEmpty && mounted) {
          final newCamps = apiService.parseCampsInView(raw);
          final existingIds = {for (final c in appState.campgrounds) c.id};
          final toAdd = newCamps
              .where((c) => !existingIds.contains(c.id))
              .toList();
          if (toAdd.isNotEmpty) {
            appState.setCampgrounds([...appState.campgrounds, ...toAdd]);
            debugPrint('🗺️ BBox: +${toAdd.length} kamp');
          }
        }
      } catch (e) {
        // BBox failed → try Overpass for visible area
        try {
          final center = bounds.center;
          final apiService = context.read<ApiService>();
          final overpassCamps = await apiService.getCampgroundsFromOverpass(
            center.latitude,
            center.longitude,
          );
          if (overpassCamps.isNotEmpty && mounted) {
            final appState = context.read<AppState>();
            final existingIds = {for (final c in appState.campgrounds) c.id};
            final toAdd = overpassCamps
                .where((c) => !existingIds.contains(c.id))
                .toList();
            if (toAdd.isNotEmpty)
              appState.setCampgrounds([...appState.campgrounds, ...toAdd]);
          }
        } catch (_) {}
      }
    });
  }

  /// Layer toggle — POI verisi yoksa Overpass API'den çek
  /// ✅ _mapCenter kullanır: Sırbıstan GPS değil, kullanıcının baktığı ABD haritası
  void _onLayerToggled(String layer) async {
    final appState = context.read<AppState>();
    final apiService = context.read<ApiService>();
    // ── KRİTİK: GPS konumu değil, HALİHAZIRDA bakılan harita merkezi ──
    final lat =
        _mapCenter.latitude; // Joshua Tree veya kullanıcının pan ettiği yer
    final lon = _mapCenter.longitude;

    final String? poiType = switch (layer) {
      'fuel' => 'fuel',
      'ev' => 'ev',
      'markets' => 'market',
      'repair' => 'repair',
      _ => null,
    };
    if (poiType == null)
      return; // campgrounds/fires/layers → AppState zaten toggle etti

    // Toggle sonrası aktif mi?
    final isNowActive = switch (layer) {
      'fuel' => appState.showFuel,
      'ev' => appState.showEvCharge,
      'markets' => appState.showMarkets,
      'repair' => appState.showRvRepair,
      _ => false,
    };
    if (!isNowActive) return; // Kapatıldıysa veri çekme

    // POI verisi çek — backend, yoksa Overpass fallback (api_service içinde)
    try {
      final pois = await apiService.getPoiPoints(
        lat: lat,
        lon: lon,
        poiType: poiType,
      );
      if (pois.isNotEmpty && mounted) {
        appState.addPoiPoints(pois);
        debugPrint('✅ $poiType: ${pois.length} POI yüklendi');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$poiType POI verisi bulunamadı (alan genişletiliyor...)',
            ),
            backgroundColor: const Color(0xFF1E3A5F),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('⚠️ POI layer toggle error: $e');
    }
  }

  Future<void> _triggerSos({
    required double lat,
    required double lon,
    required String userId,
    String emergencyContact = '',
  }) async {
    final apiService = context.read<ApiService>();
    await apiService.triggerSos(
      lat: lat,
      lon: lon,
      userId: userId,
      emergencyContact: emergencyContact,
    );
  }

  void _onRefresh() async {
    setState(() => _isLoading = true);
    await context.read<CacheService>().clearCache();
    await _initializeData();
    await _fetchWeatherData();
    setState(() => _isLoading = false);
  }

  void _showSafetyDetails(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF0D1526),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E3A5F)),
        ),
        title: const Text(
          'Safety Status',
          style: TextStyle(color: Color(0xFF00FF88)),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00FF88))),
          ),
        ],
      ),
    );
  }

  void _showLiveMapDialog() {
    final appState = context.read<AppState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1526),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E3A5F)),
        ),
        title: const Row(
          children: [
            Icon(Icons.map, color: Color(0xFF4FC3F7)),
            SizedBox(width: 8),
            Text('Live Map', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (appState.currentLocation != null) ...[
              Text(
                appState.currentLocation!.address ?? 'Current Location',
                style: const TextStyle(color: Color(0xFF00FF88)),
              ),
              const SizedBox(height: 4),
              Text(
                'Lat: ${appState.currentLocation!.latitude.toStringAsFixed(4)}',
                style: TextStyle(color: Colors.grey[400]),
              ),
              Text(
                'Lon: ${appState.currentLocation!.longitude.toStringAsFixed(4)}',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${appState.campgrounds.length} kamp | ${appState.firePoints.length} yangın | ${appState.poiPoints.length} POI',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'KAPAT',
              style: TextStyle(color: Color(0xFF00FF88)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapActionBtn({
    required IconData icon,
    VoidCallback? onPressed,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: const Color(0xFF0D1526),
        mini: true,
        heroTag: null,
        child: Icon(icon, color: const Color(0xFF00FF88), size: 20),
      ),
    );
  }

  Widget _buildMap() {
    final appState = context.watch<AppState>();
    return MapWidget(
      latitude: appState.currentLocation?.latitude ?? 33.8734,
      longitude: appState.currentLocation?.longitude ?? -115.9010,
      campgrounds: appState.campgrounds,
      firePoints: appState.firePoints,
      poiPoints: appState.poiPoints,
      communityReports: appState.communityReports,
      showCampgrounds: appState.showCampgrounds,
      showFires: appState.showFires,
      showCommunityReports: appState.showCommunityReports,
      showSolarHeatmap: appState.showSolarHeatmap,
      showCellHeatmap: appState.showCellHeatmap,
      showBlmOverlay: appState.showBlmOverlay,
      showTerrain3d: appState.showTerrain3d,
      onCampgroundTapped: (camp) {
        appState.selectCampground(camp);
        _fetchCampDetails(camp.id, camp.latitude, camp.longitude);
      },
      onPoiTapped: (poi) => appState.selectPoi(poi),
      onBoundsChanged: _onMapBoundsChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final bool hasWeatherWarning =
        _weatherData != null && _weatherData!['alarm_level'] != 'SAFE';

    // Üst barların toplam yüksekliği (weather ribbon + safety bar)
    final double topOffset = hasWeatherWarning
        ? (appState.isEvacuationWarning ? 98.0 : 50.0)
        : (appState.isEvacuationWarning ? 96.0 : 48.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ─── 0. Harita (tam ekran arka plan) ─────────────────────────────
          _buildMap(),

          // ─── 1. DANGER kırmızı gölge (pointer geçirgen) ──────────────────
          if (appState.isEvacuationWarning)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5,
                      colors: [
                        const Color(0xFFFF1744).withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                      stops: const [0.2, 1.0],
                    ),
                  ),
                ),
              ),
            ),

          // ─── 2. Weather Ribbon (en üst) ───────────────────────────────────
          if (_weatherData != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: WeatherRibbon(
                weatherData: _weatherData,
                onTap: () {
                  if (_weatherData != null)
                    showWeatherDetailDialog(context, _weatherData!);
                },
              ),
            ),

          // ─── 3. Güvenlik Barı ─────────────────────────────────────────────
          Positioned(
            top: hasWeatherWarning ? 42 : 40,
            left: 0,
            right: 0,
            child: SafetyBarWidget(
              isWarningActive: appState.isEvacuationWarning,
              warningMessage: appState.safetyMessage,
              onTap: () => _showSafetyDetails(context, appState.safetyMessage),
            ),
          ),

          // ─── 4. Sol üst: Profil + PRO badge ──────────────────────────────
          Positioned(
            top: topOffset,
            left: 12,
            child: Consumer<SubscriptionService>(
              builder: (ctx, svc, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => ProfileScreen.show(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1526).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: svc.isPremium
                        ? null
                        : () => PaywallScreen.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: svc.isPremium
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFF00FF88), Color(0xFF00B4FF)],
                              ),
                        color: svc.isPremium
                            ? const Color(0xFF00FF88).withValues(alpha: 0.15)
                            : null,
                        borderRadius: BorderRadius.circular(10),
                        border: svc.isPremium
                            ? Border.all(
                                color: const Color(
                                  0xFF00FF88,
                                ).withValues(alpha: 0.5),
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('👑', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            svc.isPremium ? 'PRO' : 'Upgrade',
                            style: TextStyle(
                              color: svc.isPremium
                                  ? const Color(0xFF00FF88)
                                  : Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: svc.isPremium ? 1 : 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ═══════════════════════════════════════════════════════════════════
          // ─── 5. SAĞ PANEL A — Aksiyon butonları + SOS (right:80) ──────────
          //    Sağ kenardan 80px uzakta → Panel B (sidebar, right:8) ile
          //    kesinlikle çakışmaz (80 > 68, 12px güvenli boşluk)
          // ═══════════════════════════════════════════════════════════════════
          Positioned(
            top: topOffset,
            right: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // ── Yenile
                _buildMapActionBtn(
                  icon: Icons.refresh,
                  tooltip: 'Yenile',
                  onPressed: _onRefresh,
                ),
                const SizedBox(height: 6),
                // ── Bilgi
                _buildMapActionBtn(
                  icon: Icons.info_outline,
                  tooltip: 'Durum',
                  onPressed: () => _showSafetyDetails(
                    context,
                    'US Outdoor Navigator v6.1\n\n'
                    'Durum: ${appState.safetyStatus}\n'
                    'Kamp: ${appState.campgrounds.length} adet\n'
                    'Yangın: ${appState.firePoints.length} nokta\n'
                    'POI: ${appState.poiPoints.length} nokta\n'
                    'Konum: ${appState.currentLocation?.address ?? "Bilinmiyor"}\n'
                    'Hava: ${_weatherData?["alarm_level"] ?? "N/A"}',
                  ),
                ),
                const SizedBox(height: 6),
                // ── Hava Durumu
                _buildMapActionBtn(
                  icon: Icons.cloud_queue,
                  tooltip: 'Hava Durumu',
                  onPressed: () {
                    if (_weatherData != null) {
                      showWeatherDetailDialog(context, _weatherData!);
                    } else {
                      _fetchWeatherData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hava durumu yükleniyor...'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Color(0xFF1E3A5F),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 14),
                // ── Live Map Butonu
                FloatingActionButton.extended(
                  heroTag: 'live_map_btn',
                  onPressed: _showLiveMapDialog,
                  backgroundColor: const Color(0xFF0D1526),
                  foregroundColor: const Color(0xFF4FC3F7),
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text('Live Map', style: TextStyle(fontSize: 12)),
                  elevation: 4,
                ),
                const SizedBox(height: 6),
                // ── Topluluk Raporu
                Tooltip(
                  message: 'Topluluk Raporu',
                  child: FloatingActionButton(
                    heroTag: 'community_report_btn',
                    onPressed: () => showCommunityReportDialog(context),
                    backgroundColor: const Color(0xFF0D1526),
                    mini: true,
                    elevation: 4,
                    child: const Text('🐻', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 6),
                // ── Offline İndir
                Tooltip(
                  message: 'Offline İndir',
                  child: FloatingActionButton(
                    heroTag: 'offline_download_btn',
                    onPressed: () => showOfflineDownloadDialog(context),
                    backgroundColor: const Color(0xFF0D1526),
                    mini: true,
                    elevation: 4,
                    child: const Icon(
                      Icons.download_for_offline,
                      color: Color(0xFF00FF88),
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // ── SOS Butonu (parlayan kırmızı)
                SosButton(
                  lat: appState.currentLocation?.latitude ?? 33.8734,
                  lon: appState.currentLocation?.longitude ?? -115.9010,
                  userId: _userId,
                  onSosTrigger:
                      ({
                        required double lat,
                        required double lon,
                        required String userId,
                        String emergencyContact = '',
                      }) => _triggerSos(
                        lat: lat,
                        lon: lon,
                        userId: userId,
                        emergencyContact: emergencyContact,
                      ),
                ),
                const SizedBox(height: 6),
                // ── Rapor Butonu
                ReportButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Report submitted ✅'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Color(0xFF1E3A5F),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════════════════════
          // ─── 6. SAĞ PANEL B — Layer Sidebar (right:8, 60px geniş) ─────────
          //    Panel A (right:80) sağ kenarı = screenWidth-80
          //    Panel B (right:8)  sol kenarı = screenWidth-68
          //    → Panel B, Panel A'nın 12px SAĞINDA → ASLA çakışmaz ✅
          //    bottom:16 ile ekranı aşağıya kadar kullanır (scrollable)
          // ═══════════════════════════════════════════════════════════════════
          Positioned(
            top: topOffset,
            right: 8,
            bottom: 16,
            child: LayerSidebar(onLayerToggled: _onLayerToggled),
          ),

          // ─── 7. POI Detay Paneli (alttan açılır) ─────────────────────────
          if (appState.selectedPoi != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: PoiInfoPanel(
                poi: appState.selectedPoi!,
                onClose: () => appState.clearSelection(),
              ),
            ),

          // ─── 8. Kamp Detay Paneli (Apple Maps tarzı) ─────────────────────
          if (appState.selectedCampground != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LogisticsSheet(
                camp: appState.selectedCampground!,
                rulesData: _campRulesData,
                solarData: _solarData,
                rvLogistics: _rvLogisticsData,
                onClose: () {
                  appState.clearSelection();
                  setState(() {
                    _campRulesData = null;
                    _solarData = null;
                    _rvLogisticsData = null;
                  });
                },
              ),
            ),

          // ─── 9. Sol alt: Online/Offline göstergesi ────────────────────────
          Positioned(
            bottom: 80,
            left: 16,
            child: GestureDetector(
              onTap: () => appState.toggleOfflineMode(),
              child: OfflineIndicator(isOffline: appState.isOfflineMode),
            ),
          ),
        ],
      ),
      floatingActionButton: _isLoading
          ? const FloatingActionButton(
              onPressed: null,
              backgroundColor: Color(0xFF0D1526),
              child: CircularProgressIndicator(color: Color(0xFF00FF88)),
            )
          : null,
    );
  }
}
