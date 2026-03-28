// heatmap_overlay.dart — Solar & Cell Signal Isı Haritası
// Canvas tabanlı, harita üzerine bindirilen şeffaf katman
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// ─── Model ───────────────────────────────────────────────────────────────────
class HeatPoint {
  final double lat, lon;
  final double intensity; // 0.0 – 1.0

  const HeatPoint({
    required this.lat,
    required this.lon,
    required this.intensity,
  });
}

// ─── Hesaplama yardımcıları ───────────────────────────────────────────────────
List<HeatPoint> buildSolarHeatPoints(
  LatLngBounds bounds, {
  int gridN = 12,
  int month = 3,
}) {
  final latStep = (bounds.north - bounds.south) / gridN;
  final lonStep = (bounds.east - bounds.west) / gridN;
  final pts = <HeatPoint>[];
  for (int r = 0; r < gridN; r++) {
    for (int c = 0; c < gridN; c++) {
      final lat = bounds.south + r * latStep + latStep / 2;
      final lon = bounds.west + c * lonStep + lonStep / 2;
      final sa =
          90 - (lat - 23.5 * math.sin((month - 3) * 30 * math.pi / 180)).abs();
      final eff = (sa.clamp(10.0, 90.0) / 90.0);
      pts.add(HeatPoint(lat: lat, lon: lon, intensity: eff));
    }
  }
  return pts;
}

List<HeatPoint> buildCellHeatPoints(LatLngBounds bounds, {int gridN = 12}) {
  final latStep = (bounds.north - bounds.south) / gridN;
  final lonStep = (bounds.east - bounds.west) / gridN;
  final centerLat = (bounds.north + bounds.south) / 2;
  final centerLon = (bounds.east + bounds.west) / 2;
  final pts = <HeatPoint>[];
  for (int r = 0; r < gridN; r++) {
    for (int c = 0; c < gridN; c++) {
      final lat = bounds.south + r * latStep + latStep / 2;
      final lon = bounds.west + c * lonStep + lonStep / 2;
      // Merkeze (daha 'kentsel') yakın = daha iyi sinyal
      final dist = math.sqrt(
        math.pow(lat - centerLat, 2) + math.pow(lon - centerLon, 2),
      );
      final maxDist = math.sqrt(
        math.pow((bounds.north - bounds.south) / 2, 2) +
            math.pow((bounds.east - bounds.west) / 2, 2),
      );
      final signal = (1.0 - (dist / (maxDist + 0.001))).clamp(0.0, 1.0);
      pts.add(HeatPoint(lat: lat, lon: lon, intensity: signal));
    }
  }
  return pts;
}

// ─── HeatmapLayer ─────────────────────────────────────────────────────────────
/// flutter_map üzerine bindirilen özel overlay katmanı.
/// [mode]: 'solar' | 'cell'
class HeatmapLayer extends StatelessWidget {
  final String mode; // 'solar' | 'cell'
  final LatLngBounds? bounds;
  final double opacity;

  const HeatmapLayer({
    super.key,
    required this.mode,
    this.bounds,
    this.opacity = 0.45,
  });

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final b = bounds ?? camera.visibleBounds;
    final month = DateTime.now().month;

    final points = mode == 'solar'
        ? buildSolarHeatPoints(b, month: month)
        : buildCellHeatPoints(b);

    return IgnorePointer(
      child: CustomPaint(
        painter: _HeatPainter(
          points: points,
          camera: camera,
          mode: mode,
          opacity: opacity,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _HeatPainter extends CustomPainter {
  final List<HeatPoint> points;
  final MapCamera camera;
  final String mode;
  final double opacity;

  _HeatPainter({
    required this.points,
    required this.camera,
    required this.mode,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final pt in points) {
      final offset = camera.latLngToScreenPoint(LatLng(pt.lat, pt.lon));
      if (offset == null) continue;
      final px = Offset(offset.x, offset.y);

      // Her nokta için büyüklük: zoom'a göre ölçeklenir
      final radius = (size.width / 10).clamp(28.0, 72.0);

      final colors = mode == 'solar'
          ? _solarColors(pt.intensity, opacity)
          : _cellColors(pt.intensity, opacity);

      final paint = Paint()
        ..shader = RadialGradient(
          colors: colors,
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: px, radius: radius));

      canvas.drawCircle(px, radius, paint);
    }
  }

  List<Color> _solarColors(double eff, double op) {
    if (eff > 0.7) {
      return [
        const Color(0xFFFFD600).withOpacity(op * 0.9),
        const Color(0xFFFF6B00).withOpacity(op * 0.5),
        Colors.transparent,
      ];
    } else if (eff > 0.45) {
      return [
        const Color(0xFFFF9800).withOpacity(op * 0.7),
        const Color(0xFFFF5722).withOpacity(op * 0.35),
        Colors.transparent,
      ];
    } else {
      return [
        const Color(0xFF1565C0).withOpacity(op * 0.55),
        const Color(0xFF0D47A1).withOpacity(op * 0.25),
        Colors.transparent,
      ];
    }
  }

  List<Color> _cellColors(double sig, double op) {
    if (sig > 0.65) {
      return [
        const Color(0xFF00FF88).withOpacity(op * 0.8),
        const Color(0xFF00BFA5).withOpacity(op * 0.4),
        Colors.transparent,
      ];
    } else if (sig > 0.35) {
      return [
        const Color(0xFFFFD600).withOpacity(op * 0.65),
        const Color(0xFFFF6B00).withOpacity(op * 0.3),
        Colors.transparent,
      ];
    } else {
      return [
        const Color(0xFFFF1744).withOpacity(op * 0.55),
        const Color(0xFF8B0000).withOpacity(op * 0.25),
        Colors.transparent,
      ];
    }
  }

  @override
  bool shouldRepaint(_HeatPainter old) =>
      old.mode != mode || old.opacity != opacity;
}

// ─── flutter_map latLngToScreenPoint helper ──────────────────────────────────
extension _CameraExt on MapCamera {
  math.Point<double>? latLngToScreenPoint(LatLng latlng) {
    try {
      final p = project(latlng);
      final topLeft = project(visibleBounds.northWest);
      return math.Point(p.x - topLeft.x, p.y - topLeft.y);
    } catch (_) {
      return null;
    }
  }
}
