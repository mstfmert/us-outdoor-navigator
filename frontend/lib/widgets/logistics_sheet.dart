// logistics_sheet.dart — Apple Maps tarzı Kamp Detay Sliding Sheet
// Kamp kuralları, güneş verimliliği, temiz su, lojistik bilgileri
// Tasarım: Koyu lacivert + fosforlu yeşil + uzay kokpiti
import 'package:flutter/material.dart';
import '../models/campground.dart';

class LogisticsSheet extends StatelessWidget {
  final Campground camp;
  final Map<String, dynamic>? rulesData; // /get_camp_rules yanıtı
  final Map<String, dynamic>? solarData; // /get_solar_estimate yanıtı
  final Map<String, dynamic>? rvLogistics; // /get_rv_logistics yanıtı
  final VoidCallback onClose;

  const LogisticsSheet({
    super.key,
    required this.camp,
    required this.onClose,
    this.rulesData,
    this.solarData,
    this.rvLogistics,
  });

  static const _kNavy = Color(0xFF0A0E17);
  static const _kCard = Color(0xFF0D1526);
  static const _kBorder = Color(0xFF1E3A5F);
  static const _kGreen = Color(0xFF00FF88);
  static const _kOrange = Color(0xFFFF6B00);
  static const _kBlue = Color(0xFF4FC3F7);
  static const _kPurple = Color(0xFF9C27B0);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.52,
      minChildSize: 0.15,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D1526),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x660A0E17),
                blurRadius: 30,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Drag Handle ───────────────────────────────────────────────
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Header ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kGreen.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: _kGreen, width: 1),
                      ),
                      child: const Icon(Icons.cabin, color: _kGreen, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            camp.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 12,
                                color: Color(0xFF4FC3F7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${camp.distanceToUser.toStringAsFixed(1)} mi  ·  '
                                '\$${camp.pricePerNight.toInt()}/gece',
                                style: const TextStyle(
                                  color: Color(0xFF4FC3F7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: onClose,
                    ),
                  ],
                ),
              ),
              const Divider(
                color: Color(0xFF1E3A5F),
                height: 20,
                indent: 20,
                endIndent: 20,
              ),

              // ── Scrollable İçerik ─────────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // RV Boyut Bilgisi
                    _buildInfoRow(
                      icon: Icons.rv_hookup,
                      label: 'Maks. Karavan',
                      value: '${camp.maxRvLength.toInt()} ft',
                      valueColor: _kGreen,
                    ),
                    if (camp.hasWater)
                      _buildInfoRow(
                        icon: Icons.water_drop,
                        label: 'İçme Suyu',
                        value: 'Mevcut ✓',
                        valueColor: _kBlue,
                      ),

                    const SizedBox(height: 12),

                    // ── KAMP KURALLARI ─────────────────────────────────────
                    _sectionHeader('Kamp Kuralları', Icons.gavel),
                    const SizedBox(height: 8),
                    _buildRulesGrid(rulesData),

                    const SizedBox(height: 16),

                    // ── GÜNEŞ PANELİ VERİMLİLİĞİ ─────────────────────────
                    _sectionHeader(
                      'Güneş Paneli Verimliliği',
                      Icons.solar_power,
                    ),
                    const SizedBox(height: 8),
                    _buildSolarCard(solarData),

                    const SizedBox(height: 16),

                    // ── RV LOJİSTİK ────────────────────────────────────────
                    _sectionHeader(
                      'RV Lojistik Özeti',
                      Icons.local_gas_station,
                    ),
                    const SizedBox(height: 8),
                    _buildRvLogisticsCard(rvLogistics),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Yardımcı Builder'lar ────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _kGreen, size: 16),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: _kGreen,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesGrid(Map<String, dynamic>? data) {
    final rules =
        data?['rules'] as Map<String, dynamic>? ??
        {
          'fire_ban': false,
          'alcohol_allowed': true,
          'pets_allowed': true,
          'quiet_hours_start': '22:00',
          'reservation_req': false,
          'max_stay_days': 14,
        };

    final items = [
      _RuleItem(
        icon: Icons.local_fire_department,
        label: rules['fire_ban'] == true ? 'Ateş Yasak' : 'Ateş İzni Var',
        active: rules['fire_ban'] != true,
        color: rules['fire_ban'] == true ? const Color(0xFFFF1744) : _kOrange,
      ),
      _RuleItem(
        icon: Icons.local_bar,
        label: rules['alcohol_allowed'] == false
            ? 'Alkol Yasak'
            : 'Alkol Serbest',
        active: rules['alcohol_allowed'] != false,
        color: rules['alcohol_allowed'] == false
            ? const Color(0xFFFF6B00)
            : Colors.cyan,
      ),
      _RuleItem(
        icon: Icons.pets,
        label: rules['pets_allowed'] == false
            ? 'Evcil Hayvan Yasak'
            : 'Evcil Hayvan OK',
        active: rules['pets_allowed'] != false,
        color: rules['pets_allowed'] == false
            ? const Color(0xFFFF6B00)
            : _kGreen,
      ),
      _RuleItem(
        icon: Icons.volume_off,
        label: 'Sessiz: ${rules['quiet_hours_start'] ?? '22:00'}',
        active: true,
        color: _kBlue,
      ),
      _RuleItem(
        icon: Icons.event_available,
        label: rules['reservation_req'] == true
            ? 'Rezervasyon Şart'
            : 'Rezervasyon Opsiyonel',
        active: true,
        color: Colors.amber,
      ),
      _RuleItem(
        icon: Icons.calendar_month,
        label: 'Maks. ${rules['max_stay_days'] ?? 14} Gece',
        active: true,
        color: _kPurple,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 3.2,
      children: items.map((item) => _buildRuleTile(item)).toList(),
    );
  }

  Widget _buildRuleTile(_RuleItem item) {
    return Container(
      decoration: BoxDecoration(
        color: item.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: item.color.withOpacity(0.35)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          Icon(item.icon, color: item.color, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                color: item.color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolarCard(Map<String, dynamic>? data) {
    final eff = (data?['efficiency_pct'] as num?)?.toDouble() ?? 0.0;
    final label = data?['label'] as String? ?? 'Veri alınıyor...';
    final rec = data?['recommendation'] as String? ?? '';
    final cover = data?['tree_cover'] as String? ?? 'open';

    final color = eff >= 70
        ? _kGreen
        : eff >= 45
        ? _kOrange
        : eff >= 20
        ? const Color(0xFFFFD600)
        : const Color(0xFFFF1744);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.solar_power, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                '${eff.toStringAsFixed(0)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // İlerleme çubuğu
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: eff / 100,
              backgroundColor: const Color(0xFF1E3A5F),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.forest, color: Colors.grey, size: 12),
              const SizedBox(width: 4),
              Text(
                'Orman: $cover  ·  ',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              Icon(Icons.tips_and_updates, color: color, size: 12),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  rec,
                  style: TextStyle(color: color, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRvLogisticsCard(Map<String, dynamic>? data) {
    final cats = data?['categories'] as Map<String, dynamic>?;
    final rvFuel = (cats?['rv_fuel'] as List?)?.length ?? 0;
    final dumpSt = (cats?['dump_station'] as List?)?.length ?? 0;
    final water = (cats?['potable_water'] as List?)?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _LogisticsStat(
            icon: Icons.local_gas_station,
            label: 'RV Yakıt',
            value: '$rvFuel',
            color: _kBlue,
          ),
          _LogisticsStat(
            icon: Icons.water_damage,
            label: 'Dump İstasyon',
            value: '$dumpSt',
            color: Colors.grey,
          ),
          _LogisticsStat(
            icon: Icons.water_drop,
            label: 'Temiz Su',
            value: '$water',
            color: _kBlue,
          ),
        ],
      ),
    );
  }
}

class _RuleItem {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  const _RuleItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.color,
  });
}

class _LogisticsStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _LogisticsStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}
