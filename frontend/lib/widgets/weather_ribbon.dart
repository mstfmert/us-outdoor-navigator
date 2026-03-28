// weather_ribbon.dart — Hava Durumu Kritik Uyarı Şeridi
// Tasarım: Yarı şeffaf, kayarak gelen, uzay kokpiti estetiği
// Renk: CRITICAL=kırmızı, WARNING=turuncu, CAUTION=sarı, SAFE=yeşil/gizli
import 'package:flutter/material.dart';

class WeatherRibbon extends StatefulWidget {
  /// Backend /get_night_weather yanıtı
  final Map<String, dynamic>? weatherData;
  final VoidCallback? onTap;

  const WeatherRibbon({super.key, this.weatherData, this.onTap});

  @override
  State<WeatherRibbon> createState() => _WeatherRibbonState();
}

class _WeatherRibbonState extends State<WeatherRibbon>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void didUpdateWidget(WeatherRibbon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.weatherData != oldWidget.weatherData) {
      _slideCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.weatherData;
    final level = data?['alarm_level'] as String? ?? 'SAFE';
    final message = data?['alarm_message'] as String? ?? '';

    // SAFE ise ribbon gösterme
    if (level == 'SAFE' || level == 'UNKNOWN' || data == null) {
      return const SizedBox.shrink();
    }

    final config = _levelConfig(level);

    return SlideTransition(
      position: _slideAnim,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                config.bgColor.withOpacity(0.92),
                config.bgColor.withOpacity(0.75),
              ],
            ),
            border: Border(
              bottom: BorderSide(color: config.borderColor, width: 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: config.bgColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Yanıp sönen ikon
              _BlinkIcon(icon: config.icon, color: config.iconColor),
              const SizedBox(width: 10),
              // Uyarı mesajı
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: config.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Kaynak badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: config.iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: config.iconColor.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_queue, size: 12, color: config.iconColor),
                    const SizedBox(width: 4),
                    Text(
                      'NWS',
                      style: TextStyle(
                        color: config.iconColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: config.iconColor, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  _RibbonConfig _levelConfig(String level) {
    switch (level) {
      case 'CRITICAL':
        return _RibbonConfig(
          bgColor: const Color(0xCC8B0000),
          borderColor: const Color(0xFFFF1744),
          iconColor: const Color(0xFFFF1744),
          textColor: Colors.white,
          icon: Icons.warning_amber_rounded,
        );
      case 'WARNING':
        return _RibbonConfig(
          bgColor: const Color(0xCCB34700),
          borderColor: const Color(0xFFFF6B00),
          iconColor: const Color(0xFFFF6B00),
          textColor: Colors.white,
          icon: Icons.thunderstorm,
        );
      case 'CAUTION':
        return _RibbonConfig(
          bgColor: const Color(0xCC665500),
          borderColor: const Color(0xFFFFD600),
          iconColor: const Color(0xFFFFD600),
          textColor: Colors.white,
          icon: Icons.water_drop,
        );
      default:
        return _RibbonConfig(
          bgColor: const Color(0xCC003322),
          borderColor: const Color(0xFF00FF88),
          iconColor: const Color(0xFF00FF88),
          textColor: Colors.white,
          icon: Icons.check_circle_outline,
        );
    }
  }
}

class _RibbonConfig {
  final Color bgColor, borderColor, iconColor, textColor;
  final IconData icon;
  const _RibbonConfig({
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });
}

// Yanıp sönen ikon animasyonu
class _BlinkIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _BlinkIcon({required this.icon, required this.color});
  @override
  State<_BlinkIcon> createState() => _BlinkIconState();
}

class _BlinkIconState extends State<_BlinkIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Icon(
        widget.icon,
        color: widget.color.withOpacity(0.4 + 0.6 * _ctrl.value),
        size: 20,
      ),
    );
  }
}

/// Detaylı hava durumu dialog'u
void showWeatherDetailDialog(BuildContext context, Map<String, dynamic> data) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1526),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF1E3A5F), width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Başlık
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.wb_cloudy, color: Color(0xFF00FF88)),
                const SizedBox(width: 8),
                Text(
                  'Hava Durumu Detayı',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _alarmColor(data['alarm_level']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _alarmColor(data['alarm_level'])),
                  ),
                  child: Text(
                    data['alarm_level'] ?? 'UNKNOWN',
                    style: TextStyle(
                      color: _alarmColor(data['alarm_level']),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Alarm mesajı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _alarmColor(data['alarm_level']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _alarmColor(data['alarm_level']).withOpacity(0.4),
                ),
              ),
              child: Text(
                data['alarm_message'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Gece tahmini listesi
          if ((data['night_forecast'] as List?)?.isNotEmpty == true)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: (data['night_forecast'] as List).length,
                itemBuilder: (_, i) {
                  final f =
                      (data['night_forecast'] as List)[i]
                          as Map<String, dynamic>;
                  return _ForecastTile(forecast: f);
                },
              ),
            ),
          // Veri kaynağı
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Kaynak: ${data['data_source'] ?? 'NOAA/NWS'}',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ),
        ],
      ),
    ),
  );
}

Color _alarmColor(String? level) => switch (level) {
  'CRITICAL' => const Color(0xFFFF1744),
  'WARNING' => const Color(0xFFFF6B00),
  'CAUTION' => const Color(0xFFFFD600),
  _ => const Color(0xFF00FF88),
};

class _ForecastTile extends StatelessWidget {
  final Map<String, dynamic> forecast;
  const _ForecastTile({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final time = (forecast['time'] as String? ?? '').substring(11, 16);
    final temp = forecast['temperature_f'] as int? ?? 0;
    final precip = forecast['precip_pct'] as int? ?? 0;
    final desc = forecast['short_desc'] as String? ?? '';
    final wind = forecast['wind_speed'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1525),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E3A5F)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              time,
              style: const TextStyle(
                color: Color(0xFF00FF88),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$temp°F',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(width: 8),
          if (precip > 0)
            Row(
              children: [
                const Icon(
                  Icons.water_drop,
                  color: Color(0xFF4FC3F7),
                  size: 12,
                ),
                Text(
                  '$precip%',
                  style: const TextStyle(
                    color: Color(0xFF4FC3F7),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(wind, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}
