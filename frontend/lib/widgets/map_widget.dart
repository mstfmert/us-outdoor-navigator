// map_widget.dart — Ultra Premium flutter_map
// ✅ Dynamic BBox yükleme | ✅ Marker Clustering | ✅ Neon İkonlar | ✅ Heatmap
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/campground.dart';
import '../models/fire_point.dart';
import '../models/poi_point.dart';
import '../models/community_report.dart';
import '../services/map_service.dart';
import 'heatmap_overlay.dart';

// ─── Cluster Modeli ──────────────────────────────────────────────────────────
class _CampCluster {
  final double lat, lon;
  final List<Campground> camps;
  _CampCluster({required this.lat, required this.lon, required this.camps});
}

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
  double _currentZoom = MapService.defaultZoom;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _mapController.move(
        LatLng(widget.latitude, widget.longitude),
        MapService.defaultZoom,
      );
    }
  }

  // ── Clustering ─────────────────────────────────────────────────────────────
  List<_CampCluster> _buildClusters(List<Campground> camps) {
    if (_currentZoom >= 10.0) {
      // Yüksek zoom: her kamp ayrı marker
      return camps
          .map(
            (c) => _CampCluster(lat: c.latitude, lon: c.longitude, camps: [c]),
          )
          .toList();
    }
    // Düşük zoom: grid tabanlı gruplama
    final double cellSize = _currentZoom < 7
        ? 2.0
        : (_currentZoom < 9 ? 0.8 : 0.3);
    final Map<String, List<Campground>> grid = {};
    for (final camp in camps) {
      final key =
          '${(camp.latitude / cellSize).floor()}_${(camp.longitude / cellSize).floor()}';
      grid.putIfAbsent(key, () => []).add(camp);
    }
    return grid.entries.map((e) {
      final list = e.value;
      final lat =
          list.map((c) => c.latitude).reduce((a, b) => a + b) / list.length;
      final lon =
          list.map((c) => c.longitude).reduce((a, b) => a + b) / list.length;
      return _CampCluster(lat: lat, lon: lon, camps: list);
    }).toList();
  }

  // ── POI Neon Renk & İkon ───────────────────────────────────────────────────
  Color _poiColor(PoiType type) => switch (type) {
    PoiType.fuel => const Color(0xFF00B4FF), // Neon mavi (RV yakıt)
    PoiType.evCharge => const Color(0xFF00FFEA), // Neon cyan (EV)
    PoiType.market => const Color(0xFFE040FB), // Neon mor
    PoiType.rvRepair => const Color(0xFFFFD600), // Altın
    PoiType.gearStore => const Color(0xFF00FF88), // Fosforlu yeşil
    PoiType.roadWork => const Color(0xFFFF6B00), // Canlı turuncu
  };

  IconData _poiIcon(PoiType type) => switch (type) {
    PoiType.fuel => Icons.local_gas_station,
    PoiType.evCharge => Icons.ev_station,
    PoiType.market => Icons.shopping_cart,
    PoiType.rvRepair => Icons.build,
    PoiType.gearStore => Icons.backpack,
    PoiType.roadWork => Icons.construction,
  };

  // ── POI Marker ──────────────────────────────────────────────────────────────
  Marker _buildPoiMarker(PoiPoint poi) {
    final color = _poiColor(poi.type);
    final isRvFuel = poi.type == PoiType.fuel;

    return Marker(
      point: LatLng(poi.latitude, poi.longitude),
      width: isRvFuel ? 46 : 40,
      height: isRvFuel ? 46 : 40,
      child: GestureDetector(
        onTap: () => widget.onPoiTapped?.call(poi),
        child: Tooltip(
          message:
              '${poi.emoji} ${poi.name}\n${poi.distanceMiles.toStringAsFixed(1)} mi',
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Dış neon halkası (RV yakıt için büyük)
              if (isRvFuel)
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.12),
                    border: Border.all(color: color.withOpacity(0.4), width: 1),
                  ),
                ),
              // Ana ikon
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E17),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.6),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(_poiIcon(poi.type), color: color, size: 17),
              ),
              // RV etiket (kamyon simgesi)
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
    );
  }

  // ── Yangın Marker ───────────────────────────────────────────────────────────
  Marker _buildFireMarker(FirePoint fire) {
    return Marker(
      point: LatLng(fire.latitude, fire.longitude),
      width: 34,
      height: 34,
      child: Tooltip(
        message: '🔥 Active Fire — ${fire.intensity.toStringAsFixed(0)} FRP',
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFF3D00).withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.red, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.6),
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
    );
  }

  // ── Cluster Marker ──────────────────────────────────────────────────────────
  Marker _buildClusterMarker(_CampCluster cluster) {
    final isSingle = cluster.camps.length == 1;
    final camp = cluster.camps.first;
    final hasWater = cluster.camps.any((c) => c.hasWater);

    if (isSingle) {
      // Tekil kamp — neon yeşil
      return Marker(
        point: LatLng(cluster.lat, cluster.lon),
        width: 52,
        height: 52,
        child: GestureDetector(
          onTap: () => widget.onCampgroundTapped?.call(camp),
          child: Tooltip(
            message:
                '🏕️ ${camp.name}\n\$${camp.pricePerNight}/night · Max ${camp.maxRvLength.toInt()}ft',
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Neon dış halka (water varsa mavi, yoksa yeşil)
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        (hasWater
                                ? const Color(0xFF00B4FF)
                                : const Color(0xFF00FF88))
                            .withOpacity(0.12),
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0E17),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasWater
                          ? const Color(0xFF00B4FF)
                          : const Color(0xFF00FF88),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (hasWater
                                    ? const Color(0xFF00B4FF)
                                    : const Color(0xFF00FF88))
                                .withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.cabin,
                    color: hasWater
                        ? const Color(0xFF00B4FF)
                        : const Color(0xFF00FF88),
                    size: 20,
                  ),
                ),
                // Su damla ikonu (varsa)
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
        ),
      );
    }

    // Cluster badge
    final count = cluster.camps.length;
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

    return Marker(
      point: LatLng(cluster.lat, cluster.lon),
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () {
          // Cluster tıklandığında zoom in yap
          _mapController.move(
            LatLng(cluster.lat, cluster.lon),
            _currentZoom + 2,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Dış halka
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeColor.withOpacity(0.15),
                border: Border.all(
                  color: badgeColor.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
            // İç daire
            Container(
              width: size * 0.68,
              height: size * 0.68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0A0E17),
                border: Border.all(color: badgeColor, width: 2),
                boxShadow: [
                  BoxShadow(color: badgeColor.withOpacity(0.5), blurRadius: 10),
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

  // ── Rapor Marker ──────────────────────────────────────────────────────────
  Marker _buildReportMarker(CommunityReport report) {
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
      child: Tooltip(
        message: '${report.emoji} ${report.label}\n${report.description}',
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E17),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final clusters = _buildClusters(widget.campgrounds);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(widget.latitude, widget.longitude),
        initialZoom: MapService.defaultZoom,
        minZoom: MapService.minZoom,
        maxZoom: MapService.maxZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onPositionChanged: (position, hasGesture) {
          final newZoom = position.zoom ?? _currentZoom;
          if ((newZoom - _currentZoom).abs() > 0.3) {
            setState(() => _currentZoom = newZoom);
          }
          if (position.bounds != null) {
            widget.onBoundsChanged?.call(position.bounds!);
          }
        },
      ),
      children: [
        // ── Mapbox Terrain-RGB (3D Topografya) ───────────────────────────
        if (widget.showTerrain3d)
          Opacity(
            opacity: 0.35,
            child: TileLayer(
              urlTemplate:
                  'https://api.mapbox.com/v4/mapbox.terrain-rgb/{z}/{x}/{y}.pngraw?access_token=${MapService.accessToken}',
              tileSize: 256,
              userAgentPackageName: 'com.usoutdoornavigator.app',
            ),
          ),

        // ── Mapbox Dark v11 ────────────────────────────────────────────────
        TileLayer(
          urlTemplate:
              'https://api.mapbox.com/styles/v1/mapbox/dark-v11/tiles/256/{z}/{x}/{y}@2x?access_token=${MapService.accessToken}',
          tileSize: 256,
          userAgentPackageName: 'com.usoutdoornavigator.app',
          maxZoom: MapService.maxZoom,
          errorTileCallback: (tile, error, stackTrace) {
            debugPrint('🗺️ Tile hatası: $error');
          },
        ),

        // ── BLM Public Land Overlay (ArcGIS REST) ────────────────────────
        if (widget.showBlmOverlay)
          Opacity(
            opacity: 0.40,
            child: TileLayer(
              urlTemplate:
                  'https://gis.blm.gov/arcgis/rest/services/lands/BLM_National_Surface_Management_Agency/MapServer/tile/{z}/{y}/{x}',
              tileSize: 256,
              userAgentPackageName: 'com.usoutdoornavigator.app',
              errorTileCallback: (tile, error, stackTrace) {
                debugPrint('🏞️ BLM tile hatası: $error');
              },
            ),
          ),

        // ── ☀️ Solar Heatmap Overlay ───────────────────────────────────────
        if (widget.showSolarHeatmap) HeatmapLayer(mode: 'solar', opacity: 0.48),

        // ── 📶 Cell Signal Heatmap Overlay ────────────────────────────────
        if (widget.showCellHeatmap) HeatmapLayer(mode: 'cell', opacity: 0.42),

        // ── 🔥 Yangın Noktaları ────────────────────────────────────────────
        if (widget.showFires)
          MarkerLayer(
            markers: widget.firePoints.map(_buildFireMarker).toList(),
          ),

        // ── 🏕️ Kamp Cluster/Marker ────────────────────────────────────────
        if (widget.showCampgrounds)
          MarkerLayer(markers: clusters.map(_buildClusterMarker).toList()),

        // ── 📍 Neon POI Noktaları ─────────────────────────────────────────
        if (widget.poiPoints.isNotEmpty)
          MarkerLayer(markers: widget.poiPoints.map(_buildPoiMarker).toList()),

        // ── 📋 Topluluk Raporları ─────────────────────────────────────────
        if (widget.showCommunityReports && widget.communityReports.isNotEmpty)
          MarkerLayer(
            markers: widget.communityReports.map(_buildReportMarker).toList(),
          ),

        // ── 📍 Kullanıcı Konumu (neon mavi nokta) ────────────────────────
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(widget.latitude, widget.longitude),
              width: 22,
              height: 22,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
