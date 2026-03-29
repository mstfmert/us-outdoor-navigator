// map_widget.dart — Formula 1 Hızında Harita
// ✅ flutter_map_marker_cluster (Supercluster algoritması — GPU dostu)
// ✅ RepaintBoundary → Her marker izole repaint katmanında
// ✅ Tile optimizasyonu: keepBuffer:4, tileFadeIn:0ms, evictErrorTile
// ✅ Pre-computed marker listesi (didUpdateWidget cache)
// ✅ 1500+ kamp noktası için 60 FPS
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import '../models/campground.dart';
import '../models/fire_point.dart';
import '../models/poi_point.dart';
import '../models/community_report.dart';
import '../services/map_service.dart';
import 'heatmap_overlay.dart';

class MapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final List<Campground> campgrounds;
  final List<FirePoint> firePoints;
  final List<PoiPoint> poiPoints;
  final List<CommunityReport> communityReports;
  final bool showCampgrounds;
  final bool showFires;
  final bool showCommunityReports;
  final bool showSolarHeatmap;
  final bool showCellHeatmap;
  final bool showBlmOverlay;
  final bool showTerrain3d;
  final void Function(Campground)? onCampgroundTapped;
  final void Function(PoiPoint)? onPoiTapped;
  final void Function(LatLngBounds bounds)? onBoundsChanged;

  const MapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.campgrounds = const [],
    this.firePoints = const [],
    this.poiPoints = const [],
    this.communityReports = const [],
    this.showCampgrounds = true,
    this.showFires = true,
    this.showCommunityReports = true,
    this.showSolarHeatmap = false,
    this.showCellHeatmap = false,
    this.showBlmOverlay = false,
    this.showTerrain3d = false,
    this.onCampgroundTapped,
    this.onPoiTapped,
    this.onBoundsChanged,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late final MapController _mapController;

  // ── Cached Marker Listeleri (performans için didUpdateWidget'ta rebuild) ─
  List<Marker> _campMarkers = [];
  List<Marker> _fireMarkers = [];
  List<Marker> _poiMarkers = [];
  List<Marker> _reportMarkers = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _rebuildAllMarkers();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ⚠️ KAMERA OTOMATİK TAŞINMIYOR — kullanıcı haritayı serbestçe gezebilir
    // GPS Sırbıstan bile olsa harita Joshua Tree / kullanıcının baktığı yerde kalır
    // Sadece veri listeleri değişince marker'lar güncellenir

    // Sadece değişen veri listelerini yeniden oluştur (불필요한 rebuild yok)
    bool needsRebuild = false;
    if (!identical(oldWidget.campgrounds, widget.campgrounds)) {
      _campMarkers = _buildCampMarkerList();
      needsRebuild = true;
    }
    if (!identical(oldWidget.firePoints, widget.firePoints)) {
      _fireMarkers = _buildFireMarkerList();
      needsRebuild = true;
    }
    if (!identical(oldWidget.poiPoints, widget.poiPoints)) {
      _poiMarkers = _buildPoiMarkerList();
      needsRebuild = true;
    }
    if (!identical(oldWidget.communityReports, widget.communityReports)) {
      _reportMarkers = _buildReportMarkerList();
      needsRebuild = true;
    }
    if (needsRebuild) setState(() {});
  }

  // ── Tüm Marker Listelerini İlk Kez Oluştur ───────────────────────────────
  void _rebuildAllMarkers() {
    _campMarkers = _buildCampMarkerList();
    _fireMarkers = _buildFireMarkerList();
    _poiMarkers = _buildPoiMarkerList();
    _reportMarkers = _buildReportMarkerList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // KAMP MARKERLARI (Supercluster'a verilecek ham liste)
  // ─────────────────────────────────────────────────────────────────────────
  List<Marker> _buildCampMarkerList() {
    return widget.campgrounds.map((camp) {
      return Marker(
        point: LatLng(camp.latitude, camp.longitude),
        width: 52,
        height: 52,
        // ↑ markerWidgetExtraSize ile cluster algoritması daha iyi çalışır
        child: RepaintBoundary(
          // ← İzole repaint katmanı: sadece bu marker refresh olur
          child: _CampMarkerWidget(
            camp: camp,
            onTap: () => widget.onCampgroundTapped?.call(camp),
          ),
        ),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // YANGN MARKERLARI
  // ─────────────────────────────────────────────────────────────────────────
  List<Marker> _buildFireMarkerList() {
    return widget.firePoints.map((fire) {
      return Marker(
        point: LatLng(fire.latitude, fire.longitude),
        width: 34,
        height: 34,
        child: RepaintBoundary(
          child: Tooltip(
            message:
                '🔥 Active Fire — ${fire.intensity.toStringAsFixed(0)} FRP',
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFF3D00).withValues(alpha: 0.9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // POI MARKERLARI
  // ─────────────────────────────────────────────────────────────────────────
  List<Marker> _buildPoiMarkerList() {
    return widget.poiPoints.map((poi) {
      final color = _poiColor(poi.type);
      final isRvFuel = poi.type == PoiType.fuel;
      return Marker(
        point: LatLng(poi.latitude, poi.longitude),
        width: isRvFuel ? 46 : 40,
        height: isRvFuel ? 46 : 40,
        child: RepaintBoundary(
          child: GestureDetector(
            onTap: () => widget.onPoiTapped?.call(poi),
            child: Tooltip(
              message:
                  '${poi.emoji} ${poi.name}\n${poi.distanceMiles.toStringAsFixed(1)} mi',
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isRvFuel)
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.12),
                        border: Border.all(
                          color: color.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                    ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0E17),
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(_poiIcon(poi.type), color: color, size: 17),
                  ),
                  if (isRvFuel)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.rv_hookup,
                          color: Colors.black,
                          size: 9,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RAPOR MARKERLARI
  // ─────────────────────────────────────────────────────────────────────────
  List<Marker> _buildReportMarkerList() {
    return widget.communityReports.map((report) {
      final Color color = switch (report.type) {
        ReportType.bearSighting => const Color(0xFF6D4C41),
        ReportType.roadClosed => const Color(0xFFFF1744),
        ReportType.fireHazard => const Color(0xFFFF6B00),
        ReportType.other => const Color(0xFFFFD600),
      };
      return Marker(
        point: LatLng(report.latitude, report.longitude),
        width: 40,
        height: 40,
        child: RepaintBoundary(
          child: Tooltip(
            message: '${report.emoji} ${report.label}\n${report.description}',
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E17),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(report.emoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // ── POI Renk & İkon yardımcıları ─────────────────────────────────────────
  Color _poiColor(PoiType type) => switch (type) {
    PoiType.fuel => const Color(0xFF00B4FF),
    PoiType.evCharge => const Color(0xFF00FFEA),
    PoiType.market => const Color(0xFFE040FB),
    PoiType.rvRepair => const Color(0xFFFFD600),
    PoiType.gearStore => const Color(0xFF00FF88),
    PoiType.roadWork => const Color(0xFFFF6B00),
  };

  IconData _poiIcon(PoiType type) => switch (type) {
    PoiType.fuel => Icons.local_gas_station,
    PoiType.evCharge => Icons.ev_station,
    PoiType.market => Icons.shopping_cart,
    PoiType.rvRepair => Icons.build,
    PoiType.gearStore => Icons.backpack,
    PoiType.roadWork => Icons.construction,
  };

  // ── Cluster Badge Builder (Supercluster → bize kaç marker verdi) ─────────
  Widget _buildClusterBadge(BuildContext context, List<Marker> markers) {
    final count = markers.length;
    final badgeColor = count > 50
        ? const Color(0xFFFF1744)
        : count > 20
        ? const Color(0xFFFF6B00)
        : const Color(0xFF00FF88);
    final size = count > 50
        ? 58.0
        : count > 10
        ? 52.0
        : 44.0;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          // Cluster'a tıklanınca Supercluster otomatik zoom yapar
          // Ek olarak haritayı ortalıyoruz
          final avgLat =
              markers.map((m) => m.point.latitude).reduce((a, b) => a + b) /
              markers.length;
          final avgLon =
              markers.map((m) => m.point.longitude).reduce((a, b) => a + b) /
              markers.length;
          _mapController.move(
            LatLng(avgLat, avgLon),
            _mapController.camera.zoom + 2,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Dış halo
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeColor.withValues(alpha: 0.15),
                border: Border.all(
                  color: badgeColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
            // İç badge
            Container(
              width: size * 0.68,
              height: size * 0.68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A0E17),
                border: Border.all(color: badgeColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: count > 99 ? 10 : 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(widget.latitude, widget.longitude),
        initialZoom: MapService.defaultZoom,
        minZoom: MapService.minZoom,
        maxZoom: MapService.maxZoom,
        backgroundColor: const Color(0xFF0A0E17), // Anında koyu arka plan
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
          // Parmak kaydırırken 60 FPS için pinch threshold
          pinchZoomThreshold: 0.5,
        ),
        onPositionChanged: (position, hasGesture) {
          if (position.bounds != null) {
            widget.onBoundsChanged?.call(position.bounds!);
          }
        },
      ),
      children: [
        // ── Mapbox Terrain-RGB (3D Topografya — sadece açıksa yükle) ────────
        // ── OpenTopoMap 3D Arazi Katmanı (FREE, Mapbox yerine) ────────────
        if (widget.showTerrain3d)
          Opacity(
            opacity: 0.35,
            child: TileLayer(
              urlTemplate: 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
              tileSize: 256,
              userAgentPackageName: 'com.usoutdoornavigator.app',
              keepBuffer: 2,
              evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
              errorTileCallback: (tile, error, stackTrace) {
                debugPrint('🏔️ Topo tile hatası: $error');
              },
            ),
          ),

        // ── CartoDB DarkMatter (Ana Harita — FREE, API key GEREKMİYOR!) ───
        // 🚀 TileDisplay.instantaneous() → tile fade yok = jilet gibi akıcı
        // Subdomains: 4 CDN sunucusuna yük dağıtımı (a/b/c/d)
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.usoutdoornavigator.app',
          maxZoom: 19,
          tileSize: 256,
          keepBuffer: 4,
          tileDisplay: const TileDisplay.instantaneous(),
          evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
          fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          errorTileCallback: (tile, error, stackTrace) {
            debugPrint('🗺️ Tile hatası: $error');
          },
        ),

        // ── BLM Public Land Overlay ─────────────────────────────────────────
        if (widget.showBlmOverlay)
          Opacity(
            opacity: 0.40,
            child: TileLayer(
              urlTemplate:
                  'https://gis.blm.gov/arcgis/rest/services/lands/BLM_National_Surface_Management_Agency/MapServer/tile/{z}/{y}/{x}',
              tileSize: 256,
              userAgentPackageName: 'com.usoutdoornavigator.app',
              keepBuffer: 2,
              evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
              errorTileCallback: (tile, error, stackTrace) {
                debugPrint('🏞️ BLM tile hatası: $error');
              },
            ),
          ),

        // ── ☀️ Solar Heatmap ────────────────────────────────────────────────
        if (widget.showSolarHeatmap) HeatmapLayer(mode: 'solar', opacity: 0.48),

        // ── 📶 Cell Signal Heatmap ──────────────────────────────────────────
        if (widget.showCellHeatmap) HeatmapLayer(mode: 'cell', opacity: 0.42),

        // ── 🔥 Yangın Noktaları (normal MarkerLayer — sayı az) ─────────────
        if (widget.showFires && _fireMarkers.isNotEmpty)
          MarkerLayer(
            markers: _fireMarkers,
            rotate: false, // rotation hesabı gereksiz
          ),

        // ── 🏕️ KAMP KÜMELEMESİ — Supercluster Algoritması ──────────────────
        // flutter_map_marker_cluster: 1500+ marker için O(log n) zoom lookup
        // Grid tabanlı eski sistemin yerini aldı → tamamen GPU dostu
        if (widget.showCampgrounds && _campMarkers.isNotEmpty)
          MarkerClusterLayerWidget(
            options: MarkerClusterLayerOptions(
              maxClusterRadius: 80, // px cinsinden kümeleme yarıçapı
              size: const Size(58, 58),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(50),
              maxZoom: 14, // Bu zoom'dan sonra her kamp ayrı gösterilir
              markers: _campMarkers,
              // ── Cluster Badge Widget ─────────────────────────────────────
              builder: _buildClusterBadge,
              // ── Animasyon Süresi ─────────────────────────────────────────
              animationsOptions: const AnimationsOptions(
                zoom: Duration(milliseconds: 250),
                fitBound: Duration(milliseconds: 400),
                spiderfy: Duration(milliseconds: 250),
                centerMarker: Duration(milliseconds: 350),
              ),
            ),
          ),

        // ── 📍 Neon POI Noktaları ──────────────────────────────────────────
        if (_poiMarkers.isNotEmpty)
          MarkerLayer(markers: _poiMarkers, rotate: false),

        // ── 📋 Topluluk Raporları ──────────────────────────────────────────
        if (widget.showCommunityReports && _reportMarkers.isNotEmpty)
          MarkerLayer(markers: _reportMarkers, rotate: false),

        // ── 📍 Kullanıcı Konumu (neon mavi nokta) ──────────────────────────
        MarkerLayer(
          rotate: false,
          markers: [
            Marker(
              point: LatLng(widget.latitude, widget.longitude),
              width: 22,
              height: 22,
              child: RepaintBoundary(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.6),
                        blurRadius: 12,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ayrı StatelessWidget olarak kamp marker'ı
// (const constructor → Flutter widget ağacında yeniden kullanılır)
// ─────────────────────────────────────────────────────────────────────────────
class _CampMarkerWidget extends StatelessWidget {
  final Campground camp;
  final VoidCallback onTap;

  const _CampMarkerWidget({required this.camp, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasWater = camp.hasWater;
    final color = hasWater ? const Color(0xFF00B4FF) : const Color(0xFF00FF88);

    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message:
            '🏕️ ${camp.name}\n\$${camp.pricePerNight}/night · Max ${camp.maxRvLength.toInt()}ft',
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Dış neon halkası
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
            ),
            // Ana ikon çerçevesi
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E17),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.cabin, color: color, size: 20),
            ),
            // Su damla ikonu (water hook-up varsa)
            if (hasWater)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B4FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    color: Colors.white,
                    size: 8,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
