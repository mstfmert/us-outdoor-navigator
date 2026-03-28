import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/poi_point.dart';

/// POI tıklandığında alttan açılan detay paneli
class PoiInfoPanel extends StatelessWidget {
  final PoiPoint poi;
  final VoidCallback onClose;

  const PoiInfoPanel({super.key, required this.poi, required this.onClose});

  Color get _accentColor => switch (poi.type) {
    PoiType.fuel => const Color(0xFFFF6F00),
    PoiType.evCharge => const Color(0xFF1565C0),
    PoiType.market => const Color(0xFF7B1FA2),
    PoiType.rvRepair => const Color(0xFFF9A825),
    PoiType.gearStore => const Color(0xFF00695C),
    PoiType.roadWork => const Color(0xFFE64A19),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1421),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: _accentColor, width: 2)),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ───────────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accentColor, width: 1.5),
                  ),
                  child: Text(poi.emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poi.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        poi.displayLabel,
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white54),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 24),

          // ── Detail Rows ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                // Mesafe
                _InfoRow(
                  icon: Icons.place,
                  iconColor: Colors.greenAccent,
                  label: 'Distance',
                  value: '${poi.distanceMiles.toStringAsFixed(1)} miles away',
                ),

                // Adres
                if (poi.address.isNotEmpty)
                  _InfoRow(
                    icon: Icons.location_city,
                    iconColor: Colors.blueAccent,
                    label: 'Address',
                    value: poi.address,
                  ),

                // Çalışma Saatleri
                _InfoRow(
                  icon: Icons.access_time,
                  iconColor: Colors.amberAccent,
                  label: 'Hours',
                  value: poi.hours.isNotEmpty ? poi.hours : 'Not available',
                ),

                // Telefon
                _InfoRow(
                  icon: Icons.phone,
                  iconColor: Colors.greenAccent,
                  label: 'Phone',
                  value: poi.phone.isNotEmpty ? poi.phone : 'Not listed',
                  onTap: poi.phone.isNotEmpty
                      ? () => launchUrl(Uri.parse('tel:${poi.phone}'))
                      : null,
                ),

                const SizedBox(height: 16),

                // Navigasyon Butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final url =
                          'https://www.google.com/maps/dir/?api=1&destination=${poi.latitude},${poi.longitude}';
                      await launchUrl(Uri.parse(url));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.navigation),
                    label: const Text(
                      'Navigate',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: onTap != null
                          ? Colors.greenAccent
                          : Colors.white70,
                      fontSize: 13,
                      decoration: onTap != null
                          ? TextDecoration.underline
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }
}
