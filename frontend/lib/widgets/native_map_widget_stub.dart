// Web platformu için stub implementasyon — Mapbox kullanılmaz
import 'package:flutter/material.dart';
import '../models/campground.dart';
import '../models/fire_point.dart';

class NativeMapWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final List<Campground> campgrounds;
  final List<FirePoint> firePoints;
  final void Function(Campground)? onCampgroundTapped;

  const NativeMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.campgrounds = const [],
    this.firePoints = const [],
    this.onCampgroundTapped,
  });

  @override
  Widget build(BuildContext context) {
    // Web'de harita gösterilemiyor; basit bir bilgi kartı göster
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'Interactive Map',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Available on Android & iOS',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              '${campgrounds.length} campgrounds | ${firePoints.length} fire points',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
