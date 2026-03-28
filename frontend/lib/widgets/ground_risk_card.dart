// ground_risk_card.dart — Weather Impact Score Görsel Kartı
// "Zemin Çamur Riski: %85 - Sadece 4x4 araçlar için uygundur"
import 'package:flutter/material.dart';

class GroundRiskCard extends StatelessWidget {
  final Map<String, dynamic>? riskData;
  final bool compact;

  const GroundRiskCard({super.key, this.riskData, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (riskData == null) return const SizedBox.shrink();

    final double riskPct =
        (riskData!['mud_risk_pct'] as num?)?.toDouble() ?? 0.0;
    final String level = riskData!['level'] ?? 'SAFE';
    final String advice = riskData!['advice'] ?? '';
    final String icon = riskData!['icon'] ?? '✅';
    final String groundLabel = riskData!['ground_label'] ?? '';
    final bool frostWarning = riskData!['frost_warning'] ?? false;
    final double precipMm =
        (riskData!['precipitation_mm'] as num?)?.toDouble() ?? 0.0;

    final Color riskColor = _levelColor(level);

    if (compact) return _buildCompact(riskPct, level, riskColor, icon);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1526),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: riskColor.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: riskColor.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Başlık ──────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: riskColor.withOpacity(0.15),
                  border: Border.all(color: riskColor, width: 1.5),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zemin Risk Analizi',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _levelLabel(level),
                      style: TextStyle(
                        color: riskColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Risk yüzdesi badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: riskColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: riskColor, width: 1.5),
                ),
                child: Text(
                  '%${riskPct.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Risk Progress Bar ─────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: riskPct / 100.0,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
            ),
          ),

          const SizedBox(height: 10),

          // ── Tavsiye Metni ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              advice,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Detay Satırları ──────────────────────────────────────────────
          Row(
            children: [
              _detailChip(
                icon: '🌧️',
                label: '${precipMm.toStringAsFixed(1)} mm yağış',
                color: const Color(0xFF4FC3F7),
              ),
              const SizedBox(width: 8),
              _detailChip(
                icon: '🏕️',
                label: groundLabel,
                color: const Color(0xFF00FF88),
              ),
              if (frostWarning) ...[
                const SizedBox(width: 8),
                _detailChip(
                  icon: '🧊',
                  label: 'Buz Riski',
                  color: const Color(0xFF80DEEA),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(double riskPct, String level, Color color, String icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            'Zemin %${riskPct.toStringAsFixed(0)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailChip({
    required String icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _levelColor(String level) => switch (level) {
    'EXTREME' => const Color(0xFFFF1744),
    'HIGH' => const Color(0xFFFF6B00),
    'MODERATE' => const Color(0xFFFFD600),
    'LOW' => const Color(0xFF00FF88),
    _ => const Color(0xFF00FF88),
  };

  String _levelLabel(String level) => switch (level) {
    'EXTREME' => '🚫 Aşırı Risk — Geçiş Önerilmez',
    'HIGH' => '⚠️ Yüksek Risk — Sadece 4x4',
    'MODERATE' => '🟡 Orta Risk — Dikkatli Olun',
    'LOW' => '✅ Düşük Risk — Standart Geçiş',
    _ => '✅ Güvenli Zemin',
  };
}
