// weather_sentinel_screen.dart — Extreme Weather Sentinel
// ✅ PRO FEATURE | ✅ NOAA Flash Flood + High Wind
// ✅ flutter_local_notifications | ✅ Critical push alerts
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

// ── Notification setup (global singleton) ────────────────────────────────────
final FlutterLocalNotificationsPlugin _notif =
    FlutterLocalNotificationsPlugin();

Future<void> initWeatherNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/launcher_icon');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    requestCriticalPermission: true,
  );
  await _notif.initialize(
    const InitializationSettings(android: android, iOS: ios),
  );
}

Future<void> _sendCriticalAlert(String title, String body) async {
  const androidDetails = AndroidNotificationDetails(
    'weather_sentinel',
    'Extreme Weather Alerts',
    channelDescription: 'Critical weather safety notifications',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    enableVibration: true,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    color: Color(0xFFFF1744),
  );
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    interruptionLevel: InterruptionLevel.critical,
  );
  await _notif.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    const NotificationDetails(android: androidDetails, iOS: iosDetails),
  );
}

class WeatherSentinelScreen extends StatefulWidget {
  final double lat;
  final double lon;

  const WeatherSentinelScreen({
    super.key,
    required this.lat,
    required this.lon,
  });

  @override
  State<WeatherSentinelScreen> createState() => _WeatherSentinelScreenState();
}

class _WeatherSentinelScreenState extends State<WeatherSentinelScreen> {
  bool _isLoading = true;
  bool _sentinelActive = false;
  Timer? _pollTimer;

  List<_WeatherAlert> _alerts = [];
  _WeatherAlert? _criticalAlert;
  DateTime _lastCheck = DateTime.now();

  @override
  void initState() {
    super.initState();
    initWeatherNotifications();
    _fetchAlerts();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _toggleSentinel() {
    setState(() => _sentinelActive = !_sentinelActive);
    if (_sentinelActive) {
      _pollTimer = Timer.periodic(
        const Duration(minutes: 15),
        (_) => _fetchAlerts(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '🛡️ Weather Sentinel ACTIVE — Monitoring every 15 min',
          ),
          backgroundColor: Color(0xFF00FF88),
        ),
      );
    } else {
      _pollTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weather Sentinel disabled')),
      );
    }
  }

  Future<void> _fetchAlerts() async {
    setState(() => _isLoading = true);
    try {
      // NOAA NWS Alerts API
      final uri = Uri.parse(
        'https://api.weather.gov/alerts/active'
        '?point=${widget.lat},${widget.lon}'
        '&status=actual&urgency=Immediate,Expected'
        '&severity=Extreme,Severe,Moderate',
      );
      final resp = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'USOutdoorNavigator/1.0 (support@usoutdoor.app)',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final features = (data['features'] as List?) ?? [];
        _alerts = features.take(10).map((f) {
          final props = f['properties'] as Map<String, dynamic>;
          return _WeatherAlert(
            event: props['event'] ?? 'Weather Alert',
            headline: props['headline'] ?? '',
            description: (props['description'] ?? '').toString().trim(),
            severity: props['severity'] ?? 'Unknown',
            urgency: props['urgency'] ?? 'Unknown',
            onset: props['onset'] != null
                ? DateTime.tryParse(props['onset'])
                : null,
            expires: props['expires'] != null
                ? DateTime.tryParse(props['expires'])
                : null,
            areaDesc: props['areaDesc'] ?? '',
          );
        }).toList();

        // Kritik uyarı var mı?
        _criticalAlert = _alerts.firstWhere(
          (a) =>
              a.event.toLowerCase().contains('flash flood') ||
              a.event.toLowerCase().contains('high wind') ||
              a.severity == 'Extreme',
          orElse: () => _WeatherAlert.none,
        );
        if (_criticalAlert!.event == '') _criticalAlert = null;

        // Sentinel aktif ve kritik uyarı varsa bildirim gönder
        if (_sentinelActive && _criticalAlert != null) {
          await _sendCriticalAlert(
            '⚠️ ${_criticalAlert!.event}',
            _criticalAlert!.headline.isNotEmpty
                ? _criticalAlert!.headline
                : 'Extreme weather detected at your location.',
          );
        }
      } else {
        // Backend fallback
        final backUri = Uri.parse(
          '${AppConfig.apiBaseUrl}/get_weather_alerts'
          '?lat=${widget.lat}&lon=${widget.lon}',
        );
        final backResp = await http
            .get(backUri)
            .timeout(const Duration(seconds: 10));
        if (backResp.statusCode == 200) {
          final bd = jsonDecode(backResp.body);
          final list = (bd['alerts'] as List?) ?? [];
          _alerts = list.map((a) => _WeatherAlert.fromBackend(a)).toList();
        }
      }
    } catch (e) {
      debugPrint('⚠️ WeatherSentinel fetch: $e');
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
        _lastCheck = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1526),
        title: const Row(
          children: [
            Text('🌊', style: TextStyle(fontSize: 20)),
            SizedBox(width: 10),
            Text(
              'Weather Sentinel',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            SizedBox(width: 8),
            _SentinelBadge(),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _fetchAlerts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFF1744)),
                  SizedBox(height: 16),
                  Text(
                    'Checking NOAA alerts...',
                    style: TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            )
          : _buildBody(),
      bottomNavigationBar: _buildSentinelToggle(),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _fetchAlerts,
      color: const Color(0xFFFF1744),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildRiskSummary(),
            const SizedBox(height: 20),
            if (_alerts.isEmpty) _buildAllClearCard() else _buildAlertsList(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final hasActive = _alerts.isNotEmpty;
    final color = hasActive ? const Color(0xFFFF1744) : const Color(0xFF00FF88);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Text(hasActive ? '⚠️' : '✅', style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasActive
                      ? '${_alerts.length} ACTIVE ALERT${_alerts.length > 1 ? 'S' : ''}'
                      : 'ALL CLEAR',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Last check: ${_lastCheck.hour}:${_lastCheck.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _sentinelActive
                  ? const Color(0xFF00FF88).withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _sentinelActive
                    ? const Color(0xFF00FF88).withValues(alpha: 0.4)
                    : Colors.white12,
              ),
            ),
            child: Text(
              _sentinelActive ? '🛡️ ON' : '⏸ OFF',
              style: TextStyle(
                color: _sentinelActive
                    ? const Color(0xFF00FF88)
                    : Colors.grey[500],
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskSummary() {
    final hasFlood = _alerts.any(
      (a) => a.event.toLowerCase().contains('flood'),
    );
    final hasWind = _alerts.any(
      (a) =>
          a.event.toLowerCase().contains('wind') ||
          a.event.toLowerCase().contains('tornado'),
    );
    final hasThunder = _alerts.any(
      (a) => a.event.toLowerCase().contains('thunder'),
    );

    return Row(
      children: [
        Expanded(child: _riskChip('🌊', 'Flash Flood', hasFlood)),
        const SizedBox(width: 8),
        Expanded(child: _riskChip('💨', 'High Wind', hasWind)),
        const SizedBox(width: 8),
        Expanded(child: _riskChip('⚡', 'Thunderstorm', hasThunder)),
      ],
    );
  }

  Widget _riskChip(String emoji, String label, bool active) {
    final color = active ? const Color(0xFFFF1744) : Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFFF1744).withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey[600],
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? const Color(0xFFFF1744) : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllClearCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF00FF88).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00FF88).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          const Text('☀️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'No Active Weather Alerts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'NOAA reports no flash floods, high winds,\nor severe weather in your area.',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACTIVE ALERTS',
          style: TextStyle(
            color: Color(0xFFFF1744),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ..._alerts.map(_buildAlertCard),
      ],
    );
  }

  Widget _buildAlertCard(_WeatherAlert alert) {
    final isExtreme = alert.severity == 'Extreme';
    final color = isExtreme ? const Color(0xFFFF1744) : const Color(0xFFFFD740);
    final emoji = _alertEmoji(alert.event);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  alert.event,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  alert.severity,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (alert.headline.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              alert.headline,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (alert.expires != null) ...[
            const SizedBox(height: 6),
            Text(
              'Expires: ${_fmtDate(alert.expires!)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSentinelToggle() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GestureDetector(
          onTap: _toggleSentinel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _sentinelActive
                    ? [const Color(0xFFFF1744), const Color(0xFFFF6B6B)]
                    : [const Color(0xFF00FF88), const Color(0xFF00CC66)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color:
                      (_sentinelActive
                              ? const Color(0xFFFF1744)
                              : const Color(0xFF00FF88))
                          .withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              _sentinelActive
                  ? '🛡️  SENTINEL ACTIVE — Tap to Disable'
                  : '🚀  ACTIVATE SENTINEL — Monitor Every 15 Min',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _alertEmoji(String event) {
    final e = event.toLowerCase();
    if (e.contains('flood')) return '🌊';
    if (e.contains('wind') || e.contains('tornado')) return '💨';
    if (e.contains('thunder')) return '⚡';
    if (e.contains('snow') || e.contains('blizzard')) return '❄️';
    if (e.contains('fire')) return '🔥';
    if (e.contains('earthquake')) return '🌍';
    return '⚠️';
  }

  String _fmtDate(DateTime dt) =>
      '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
}

class _SentinelBadge extends StatelessWidget {
  const _SentinelBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFF1744),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _WeatherAlert {
  final String event;
  final String headline;
  final String description;
  final String severity;
  final String urgency;
  final DateTime? onset;
  final DateTime? expires;
  final String areaDesc;

  const _WeatherAlert({
    required this.event,
    required this.headline,
    required this.description,
    required this.severity,
    required this.urgency,
    this.onset,
    this.expires,
    required this.areaDesc,
  });

  static const _WeatherAlert none = _WeatherAlert(
    event: '',
    headline: '',
    description: '',
    severity: '',
    urgency: '',
    areaDesc: '',
  );

  factory _WeatherAlert.fromBackend(Map<String, dynamic> m) => _WeatherAlert(
    event: m['event'] ?? '',
    headline: m['headline'] ?? '',
    description: m['description'] ?? '',
    severity: m['severity'] ?? 'Unknown',
    urgency: m['urgency'] ?? 'Unknown',
    areaDesc: m['area'] ?? '',
  );
}
