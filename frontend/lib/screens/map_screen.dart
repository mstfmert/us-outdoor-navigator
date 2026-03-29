import 'dart:async';
import 'dart:math' show Random;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
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
  // ── Cihaz bazlı anonim kullanıcı kimliği ─────────────────────────────────
  // İlk çalışmada UUID benzeri bir ID üretilir ve SharedPreferences'e kaydedilir.
  // SOS, checkin ve raporlama bu ID ile bağlanır.
  String _userId = 'user_anonymous';

  // ── BBox debounce timer ──────────────────────────────────────────────────
  Timer? _bboxTimer;
  // ── Backend Health Check timer (30 sn'de bir çalışır) ──────────────────
  Timer? _healthTimer;

  // ── Survival & Comfort State ─────────────────────────────────────────────
  Map<String, dynamic>? _weatherData;
  Map<String, dynamic>? _solarData;
  Map<String, dynamic>? _rvLogisticsData;
  Map<String, dynamic>? _campRulesData;

  @override
  void initState() {
    super.initState();
    _rvLengthController.text = _rvLength.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initUserId(); // Kalıcı anonim kullanıcı ID'si
      _initializeData();
      _fetchWeatherData();
      _startHealthCheck(); // Backend bağlantı izleme
    });
  }

  // ── Kalıcı Anonim Kullanıcı ID'si ────────────────────────────────────────
  /// SharedPreferences'den ID okur; yoksa üretir ve kaydeder.
  /// Format: user_<13 haneli timestamp><4 haneli random>
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
    debugPrint('👤 User ID: $_userId');
  }

  // ── Backend Health Check ─────────────────────────────────────────────────
  /// 30 sn'de bir backend'i ping'ler. Başarısız olursa OfflineIndicator
  /// otomatik olarak turuncu olur ve SnackBar gösterir.
  void _startHealthCheck() {
    _healthTimer?.cancel();
    _healthTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!mounted) return;
      final wasOnline = ApiService.isOnline;
      final nowOnline = await ApiService.checkHealth();
      if (!mounted) return;
      final appState = context.read<AppState>();
      appState.setOfflineMode(!nowOnline);
      // Durum değiştiyse SnackBar göster
      if (wasOnline && !nowOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Backend offline — Cached data shown'),
              ],
            ),
            backgroundColor: Color(0xFFE65100),
            duration: Duration(seconds: 4),
          ),
        );
      } else if (!wasOnline && nowOnline) {
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

  void _updateRvLength() {
    final text = _rvLengthController.text;
    if (text.isNotEmpty) {
      final value = double.tryParse(text);
      if (value != null && value > 0) {
        setState(() => _rvLength = value);
        _refreshWithRvLength();
      }
    }
  }

  void _refreshWithRvLength() {
    setState(() => _isLoading = true);
    _initializeData().then((_) => setState(() => _isLoading = false));
  }

  Future<void> _initializeData() async {
    final appState = context.read<AppState>();
    final cacheService = context.read<CacheService>();
    final apiService = context.read<ApiService>();
    appState.setLoading(true);
    try {
      if (cacheService.canWorkOffline() && appState.isOfflineMode) {
        appState.setCampgrounds(cacheService.getCachedCampgrounds());
        appState.setFirePoints(cacheService.getCachedFirePoints());
        final s = cacheService.getCachedSafetyStatus();
        appState.setSafetyStatus(s['status']!, s['message']!);
      } else {
        final loc = await apiService.getUserLocation();
        appState.setCurrentLocation(loc);
        final data = await apiService.getFullReport(
          lat: loc.latitude,
          lon: loc.longitude,
          rvLength: _rvLength,
        );
        final camps = apiService.parseCampgrounds(data);
        final fires = apiService.parseFirePoints(data);
        final safety = data['safety'] as Map<String, dynamic>;
        if (safety['status'] == 'DANGER') HapticFeedback.heavyImpact();
        appState.setSafetyStatus(
          safety['status'] ?? 'UNKNOWN',
          safety['message'] ?? '',
        );
        appState.setCampgrounds(camps);
        appState.setFirePoints(fires);
        await cacheService.cacheAll(camps, fires, safety);
      }
    } catch (e) {
      appState.setError(e.toString());
    } finally {
      appState.setLoading(false);
    }
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
  }

  // ── Harita BBox değişince backend'den yeni kamp listesi çek ─────────────
  void _onMapBoundsChanged(LatLngBounds bounds) {
    _bboxTimer?.cancel();
    _bboxTimer = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      final appState = context.read<AppState>();
      final apiService = context.read<ApiService>();
      // Premium durumunu SubscriptionService'ten al
      final subSvc = context.read<SubscriptionService>();
      if (appState.isOfflineMode) return;
      try {
        final raw = await apiService.getCampsInView(
          minLat: bounds.south,
          maxLat: bounds.north,
          minLon: bounds.west,
          maxLon: bounds.east,
          limit: 300,
          isPremium: subSvc.isPremium, // ← premium eyalet kilidi
        );
        if (raw.isNotEmpty && mounted) {
          final newCamps = apiService.parseCampsInView(raw);
          // Mevcut listeye merge et (duplicate önle)
          final existingIds = {for (final c in appState.campgrounds) c.id};
          final toAdd = newCamps
              .where((c) => !existingIds.contains(c.id))
              .toList();
          if (toAdd.isNotEmpty) {
            appState.setCampgrounds([...appState.campgrounds, ...toAdd]);
            debugPrint('🗺️ BBox: +${toAdd.length} yeni kamp yüklendi');
          }
        }
      } catch (e) {
        debugPrint('⚠️ BBox fetch: $e');
      }
    });
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

  void _onLayerToggled(String layer) {
    final appState = context.read<AppState>();
    final apiService = context.read<ApiService>();
    final lat = appState.currentLocation?.latitude ?? 33.8734;
    final lon = appState.currentLocation?.longitude ?? -115.9010;

    final String? poiType = switch (layer) {
      'fuel' => 'fuel',
      'ev' => 'ev',
      'markets' => 'market',
      'repair' => 'repair',
      _ => null,
    };

    if (poiType == null) return;

    final isNowActive = switch (layer) {
      'fuel' => appState.showFuel,
      'ev' => appState.showEvCharge,
      'markets' => appState.showMarkets,
      'repair' => appState.showRvRepair,
      _ => false,
    };

    if (!isNowActive) return;

    apiService.getPoiPoints(lat: lat, lon: lon, poiType: poiType).then((pois) {
      if (pois.isNotEmpty && mounted) {
        appState.addPoiPoints(pois);
        debugPrint('✅ ${pois.length} $poiType POI yüklendi');
      }
    });
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

  Widget _buildMapActionBtn({required IconData icon, VoidCallback? onPressed}) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: const Color(0xFF0D1526),
      mini: true,
      heroTag: null,
      child: Icon(icon, color: const Color(0xFF00FF88)),
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

  // ─── WEB placeholder ─────────────────────────────────────────────────────
  Widget _buildWebMapPlaceholder() {
    final appState = context.watch<AppState>();
    return Container(
      color: const Color(0xFF0A0E17),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0D1526),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'US Outdoor Navigator',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00FF88),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Survival & Comfort Edition v6.0',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF88).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF00FF88)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.api, size: 16, color: Color(0xFF00FF88)),
                          SizedBox(width: 6),
                          Text(
                            'API v6.0',
                            style: TextStyle(
                              color: Color(0xFF00FF88),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1525),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E3A5F)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.rv_hookup,
                        color: Color(0xFF4FC3F7),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'RV Length (ft):',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        height: 36,
                        child: TextField(
                          controller: _rvLengthController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            hintText: '35',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                          ),
                          onSubmitted: (_) => _updateRvLength(),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _updateRvLength,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FC3F7),
                          foregroundColor: const Color(0xFF0A0E17),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Güvenlik kartı
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1526),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: appState.isEvacuationWarning
                            ? const Color(0xFFFF1744)
                            : const Color(0xFF00FF88),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              appState.isEvacuationWarning
                                  ? Icons.warning
                                  : Icons.check_circle,
                              color: appState.isEvacuationWarning
                                  ? const Color(0xFFFF1744)
                                  : const Color(0xFF00FF88),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                appState.isEvacuationWarning
                                    ? 'DANGER ZONE'
                                    : 'SAFE AREA',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          appState.safetyMessage.isNotEmpty
                              ? appState.safetyMessage
                              : 'Area safety data loading...',
                          style: TextStyle(color: Colors.grey[300]),
                        ),
                      ],
                    ),
                  ),
                  // Hava durumu bilgisi
                  if (_weatherData != null &&
                      _weatherData!['alarm_level'] != 'SAFE')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A0808),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFF6B00)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.thunderstorm,
                            color: Color(0xFFFF6B00),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _weatherData!['alarm_message'] ?? '',
                              style: const TextStyle(
                                color: Color(0xFFFF6B00),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // İstatistik kartları
                  Row(
                    children: [
                      Expanded(
                        child: _buildDataCard(
                          icon: Icons.cabin,
                          title: 'Campgrounds',
                          value: appState.campgrounds.length.toString(),
                          color: const Color(0xFF00FF88),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDataCard(
                          icon: Icons.local_fire_department,
                          title: 'Fire Points',
                          value: appState.firePoints.length.toString(),
                          color: const Color(0xFFFF6B00),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (appState.campgrounds.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nearby Campgrounds (${appState.campgrounds.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00FF88),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...appState.campgrounds
                            .take(5)
                            .map(
                              (camp) => GestureDetector(
                                onTap: () {
                                  appState.selectCampground(camp);
                                  _fetchCampDetails(
                                    camp.id,
                                    camp.latitude,
                                    camp.longitude,
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D1526),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: camp.hasWater
                                          ? const Color(0xFF4FC3F7)
                                          : const Color(0xFF1E3A5F),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.cabin,
                                        color: Color(0xFF00FF88),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              camp.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${camp.distanceToUser.toStringAsFixed(1)} mi  ·  \$${camp.pricePerNight}/night  ·  Max ${camp.maxRvLength.toInt()}ft RV',
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 11,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey[600],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1526),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final bool hasWeatherWarning =
        _weatherData != null && _weatherData!['alarm_level'] != 'SAFE';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: Stack(
        children: [
          // ── Harita (Web'de sade liste görünümü, mobilde flutter_map) ─────
          if (kIsWeb) _buildWebMapPlaceholder() else _buildMap(),

          // DANGER kırmızı gölge
          if (appState.isEvacuationWarning)
            Container(
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

          // ── Weather Ribbon (üst — kritik uyarı varsa görünür) ────────────
          if (_weatherData != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: WeatherRibbon(
                weatherData: _weatherData,
                onTap: () {
                  if (_weatherData != null) {
                    showWeatherDetailDialog(context, _weatherData!);
                  }
                },
              ),
            ),

          // ── Güvenlik Barı (weather ribbon'ın altına kayar) ───────────────
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

          // ── Sol üst: Profil + Upgrade butonları ──────────────────────────
          // SafetyBarWidget yüksekliği ~48px. Evacuation aktifse butonlar
          // barın altına (top ≥ 96) itiliyor; aksi hâlde bar gizli (SizedBox).
          Positioned(
            top: appState.isEvacuationWarning
                ? (hasWeatherWarning ? 98 : 96) // Bar görünür → altına kaç
                : (hasWeatherWarning ? 50 : 48), // Bar gizli → eski konum
            left: 12,
            child: Consumer<SubscriptionService>(
              builder: (ctx, svc, _) => Row(
                children: [
                  // Profil butonu
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
                  // Pro badge / Upgrade butonu
                  if (!svc.isPremium)
                    GestureDetector(
                      onTap: () => PaywallScreen.show(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00FF88), Color(0xFF00B4FF)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('👑', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Text(
                              'Upgrade Pro',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF88).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF00FF88).withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('👑', style: TextStyle(fontSize: 12)),
                          SizedBox(width: 4),
                          Text(
                            'PRO',
                            style: TextStyle(
                              color: Color(0xFF00FF88),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Layer Sidebar (sağ orta) ──────────────────────────────────────
          Positioned(
            top: 160,
            right: 8,
            child: LayerSidebar(onLayerToggled: _onLayerToggled),
          ),

          // ── POI Detay Paneli (alttan açılır) ─────────────────────────────
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

          // ── Sağ üst aksiyon butonları ─────────────────────────────────────
          Positioned(
            top: 100,
            right: 16,
            child: Column(
              children: [
                _buildMapActionBtn(icon: Icons.refresh, onPressed: _onRefresh),
                const SizedBox(height: 8),
                _buildMapActionBtn(
                  icon: Icons.info_outline,
                  onPressed: () => _showSafetyDetails(
                    context,
                    'US Outdoor Navigator v6.0\n'
                    'Survival & Comfort Edition\n\n'
                    'Status: ${appState.safetyStatus}\n'
                    'Campgrounds: ${appState.campgrounds.length}\n'
                    'Fire Points: ${appState.firePoints.length}\n'
                    'Location: ${appState.currentLocation?.address ?? "Unknown"}\n'
                    'Weather: ${_weatherData?['alarm_level'] ?? 'N/A'}',
                  ),
                ),
                const SizedBox(height: 8),
                // Hava durumu hızlı butonu
                _buildMapActionBtn(
                  icon: Icons.cloud_queue,
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
              ],
            ),
          ),

          // ── Sağ alt: Live Map + SOS + Rapor ──────────────────────────────
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Live Map butonu
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: FloatingActionButton.extended(
                    heroTag: 'live_map_btn',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF0D1526),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFF1E3A5F)),
                          ),
                          title: const Row(
                            children: [
                              Icon(Icons.map, color: Color(0xFF4FC3F7)),
                              SizedBox(width: 8),
                              Text(
                                'Live Map',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (appState.currentLocation != null) ...[
                                Text(
                                  '${appState.currentLocation!.address}',
                                  style: const TextStyle(
                                    color: Color(0xFF00FF88),
                                  ),
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
                                '${appState.campgrounds.length} kamp | ${appState.firePoints.length} yangın',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'KAPAT',
                                style: TextStyle(color: Color(0xFF00FF88)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    backgroundColor: const Color(0xFF0D1526),
                    foregroundColor: const Color(0xFF4FC3F7),
                    icon: const Icon(Icons.map),
                    label: const Text('Live Map'),
                  ),
                ),
                // 🐻 Topluluk Raporu Butonu
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: FloatingActionButton(
                    heroTag: 'community_report_btn',
                    onPressed: () => showCommunityReportDialog(context),
                    backgroundColor: const Color(0xFF0D1526),
                    mini: true,
                    child: const Text('🐻', style: TextStyle(fontSize: 18)),
                  ),
                ),

                // 📥 Offline İndirme Butonu
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: FloatingActionButton(
                    heroTag: 'offline_download_btn',
                    onPressed: () => showOfflineDownloadDialog(context),
                    backgroundColor: const Color(0xFF0D1526),
                    mini: true,
                    child: const Icon(
                      Icons.download_for_offline,
                      color: Color(0xFF00FF88),
                      size: 20,
                    ),
                  ),
                ),

                // SOS Butonu (parlayan kırmızı)
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
                const SizedBox(height: 10),
                // Rapor Butonu
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

          // ── Kamp Detay: LogisticsSheet (Apple Maps tarzı) ─────────────────
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

          // ── Sol alt: Online/Offline göstergesi ───────────────────────────
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
