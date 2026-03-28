// rv_guard_panel.dart — RV Dimension Guard Paneli
// Rota üzerindeki alçak köprü / dar tünel uyarılarını gösterir
import 'package:flutter/material.dart';

class RvGuardPanel extends StatelessWidget {
  final Map<String, dynamic>? routeData;
  final VoidCallback? onClose;
  final VoidCallback? onRecalculate;

  const RvGuardPanel({
    super.key,
    this.routeData,
    this.onClose,
    this.onRecalculate,
  });

  @override
  Widget build(BuildContext context) {
    if (routeData == null) return const SizedBox.shrink();

    final String? error = routeData!['error'];
    if (error != null) {
      return _buildError(error);
    }

    final double distKm =
        (routeData!['distance_km'] as num?)?.toDouble() ?? 0.0;
    final double durationMin =
        (routeData!['duration_min'] as num?)?.toDouble() ?? 0.0;
    final List<dynamic> warnings =
        (routeData!['clearance_warnings'] as List?) ?? [];
    final Map<String, dynamic> rvProfile =
        (routeData!['rv_profile'] as Map<String, dynamic>?) ?? {};

    final criticalWarnings = warnings
        .where((w) => w['severity'] == 'CRITICAL')
        .toList();
    final hasBlockers = criticalWarnings.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1526),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasBlockers
              ? const Color(0xFFFF1744)
              : const Color(0xFF00FF88),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (hasBlockers
                        ? const Color(0xFFFF1744)
                        : const Color(0xFF00FF88))
                    .withOpacity(0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  (hasBlockers
                          ? const Color(0xFFFF1744)
                          : const Color(0xFF00FF88))
                      .withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasBlockers ? Icons.warning_amber : Icons.route,
                  color: hasBlockers
                      ? const Color(0xFFFF1744)
                      : const Color(0xFF00FF88),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasBlockers
                            ? '⚠️ RV GÜVENLİ ROTA DEĞİL'
                            : '✅ Rota RV Uyumlu',
                        style: TextStyle(
                          color: hasBlockers
                              ? const Color(0xFFFF1744)
                              : const Color(0xFF00FF88),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${distKm.toStringAsFixed(1)} km · '
                        '${durationMin.toStringAsFixed(0)} dk',
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // RV profili
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FC3F7).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF4FC3F7),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${rvProfile['height_ft'] ?? 13.5}ft H\n'
                    '${rvProfile['width_ft'] ?? 8.5}ft W',
                    style: const TextStyle(
                      color: Color(0xFF4FC3F7),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(
                    Icons.close,
                    color: Colors.white38,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),

          // ── Uyarılar ───────────────────────────────────────────────────
          if (warnings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Text('✅', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Rota boyunca bilinen köprü/tünel yükseklik kısıtı yok.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(10),
                itemCount: warnings.length,
                itemBuilder: (_, i) {
                  final w = warnings[i] as Map<String, dynamic>;
                  return _buildWarningTile(w);
                },
              ),
            ),

          // ── Alt Butonlar ──────────────────────────────────────────────
          if (hasBlockers)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRecalculate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text(
                    'Alternatif Rota Bul',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWarningTile(Map<String, dynamic> warning) {
    final type = warning['type'] ?? '';
    final severity = warning['severity'] ?? 'INFO';
    final message = warning['message'] ?? '';
    final limitFt = (warning['limit_ft'] as num?)?.toDouble();
    final rvHeightFt = (warning['rv_height_ft'] as num?)?.toDouble();

    Color tileColor;
    String emoji;
    if (severity == 'CRITICAL') {
      tileColor = const Color(0xFFFF1744);
      emoji = '🚫';
    } else if (severity == 'WARNING') {
      tileColor = const Color(0xFFFF6B00);
      emoji = '⚠️';
    } else {
      tileColor = const Color(0xFF4FC3F7);
      emoji = 'ℹ️';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tileColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tileColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: tileColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (limitFt != null && rvHeightFt != null)
                  Text(
                    'Fark: ${(rvHeightFt - limitFt).toStringAsFixed(1)}ft aşım',
                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0808),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF1744)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF1744), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rota hesaplanamadı: $error',
              style: const TextStyle(color: Color(0xFFFF1744), fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, color: Colors.white38, size: 16),
          ),
        ],
      ),
    );
  }
}
