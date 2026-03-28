// leveling_screen.dart — Digital RV Leveling Tool
// ✅ PRO FEATURE | ✅ sensors_plus accelerometer
// ✅ Bubble level visualization | ✅ Pitch + Roll display
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class LevelingScreen extends StatefulWidget {
  const LevelingScreen({super.key});

  @override
  State<LevelingScreen> createState() => _LevelingScreenState();
}

class _LevelingScreenState extends State<LevelingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  StreamSubscription<AccelerometerEvent>? _sub;

  // Animasyon için smoothed değerler
  double _smoothPitch = 0.0;
  double _smoothRoll = 0.0;
  static const double _alpha = 0.15; // Low-pass filter

  // Bubble pozisyonu (-1.0 to +1.0)
  double get _bubbleX => (_smoothRoll / 20.0).clamp(-1.0, 1.0);
  double get _bubbleY => (_smoothPitch / 20.0).clamp(-1.0, 1.0);

  bool get _isLevel => _smoothPitch.abs() < 1.5 && _smoothRoll.abs() < 1.5;

  Color get _statusColor {
    final maxAngle = math.max(_smoothPitch.abs(), _smoothRoll.abs());
    if (maxAngle < 1.5) return const Color(0xFF00FF88);
    if (maxAngle < 4.0) return const Color(0xFFFFD740);
    return const Color(0xFFFF1744);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Auto-Pause
    _startListening();
  }

  // ── Auto-Pause: Arka plana geçince sensörü durdur ─────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _sub?.cancel();
      _sub = null;
      debugPrint('⏸️ Leveling sensörü duraklatıldı (arka plan)');
    } else if (state == AppLifecycleState.resumed && _sub == null) {
      _startListening();
      debugPrint('▶️ Leveling sensörü yeniden başlatıldı');
    }
  }

  void _startListening() {
    _sub =
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 50),
        ).listen((event) {
          // Accelerometer'dan pitch/roll hesapla
          final double x = event.x;
          final double y = event.y;
          final double z = event.z;

          // Pitch (ön-arka): Y ve Z ekseni
          final rawPitch =
              math.atan2(y, math.sqrt(x * x + z * z)) * (180 / math.pi);
          // Roll (sağ-sol): X ve Z ekseni
          final rawRoll = math.atan2(x, z) * (180 / math.pi);

          if (mounted) {
            setState(() {
              // Low-pass filter (titreşimi azalt)
              _smoothPitch = _smoothPitch + _alpha * (rawPitch - _smoothPitch);
              _smoothRoll = _smoothRoll + _alpha * (rawRoll - _smoothRoll);
            });
          }
        });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1526),
        title: const Row(
          children: [
            Text('📐', style: TextStyle(fontSize: 20)),
            SizedBox(width: 10),
            Text(
              'Digital Level',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            SizedBox(width: 8),
            _ProBadge(),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ── Status Banner ──────────────────────────────────────────
              _buildStatusBanner(),
              const SizedBox(height: 28),

              // ── Bubble Level ───────────────────────────────────────────
              Expanded(flex: 3, child: _buildBubbleLevelView()),
              const SizedBox(height: 24),

              // ── Numeric Readings ───────────────────────────────────────
              _buildNumericReadings(),
              const SizedBox(height: 20),

              // ── Side Guide Bar ─────────────────────────────────────────
              _buildLevelingGuide(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _statusColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _isLevel ? '✅' : '⚠️',
              key: ValueKey(_isLevel),
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _isLevel ? 'RV is LEVEL — Good to Camp!' : 'Adjust Leveling Jacks',
            style: TextStyle(
              color: _statusColor,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleLevelView() {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _BubbleLevelPainter(
                bubbleX: _bubbleX,
                bubbleY: _bubbleY,
                statusColor: _statusColor,
                isLevel: _isLevel,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumericReadings() {
    return Row(
      children: [
        Expanded(child: _angleCard('PITCH', _smoothPitch, '↕️', 'Fore-Aft')),
        const SizedBox(width: 12),
        Expanded(child: _angleCard('ROLL', _smoothRoll, '↔️', 'Side-to-Side')),
      ],
    );
  }

  Widget _angleCard(String label, double angle, String emoji, String subtitle) {
    final isOk = angle.abs() < 1.5;
    final color = isOk
        ? const Color(0xFF00FF88)
        : (angle.abs() < 4.0
              ? const Color(0xFFFFD740)
              : const Color(0xFFFF1744));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1526),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            '${angle.toStringAsFixed(1)}°',
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelingGuide() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1526),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 LEVELING GUIDE',
            style: TextStyle(
              color: Color(0xFF00FF88),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          _guideRow(
            '< 1.5°',
            'Perfect — Level for sleep & appliances',
            const Color(0xFF00FF88),
          ),
          _guideRow(
            '1.5° – 3°',
            'Acceptable — Minor adjustment needed',
            const Color(0xFFFFD740),
          ),
          _guideRow(
            '> 3°',
            'Uncomfortable — Use leveling blocks',
            const Color(0xFFFF1744),
          ),
        ],
      ),
    );
  }

  Widget _guideRow(String angle, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            angle,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Painter: Bubble Level ─────────────────────────────────────────────
class _BubbleLevelPainter extends CustomPainter {
  final double bubbleX;
  final double bubbleY;
  final Color statusColor;
  final bool isLevel;

  const _BubbleLevelPainter({
    required this.bubbleX,
    required this.bubbleY,
    required this.statusColor,
    required this.isLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) * 0.9;

    // ── Outer ring ────────────────────────────────────────────────────
    final outerPaint = Paint()
      ..color = const Color(0xFF1E3A5F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(cx, cy), r, outerPaint);

    // ── Grid lines ────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), gridPaint);
    canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), gridPaint);

    // ── Target zone (center circle — level zone) ──────────────────────
    final targetZoneR = r * 0.15;
    final targetPaint = Paint()
      ..color = const Color(0xFF00FF88).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), targetZoneR, targetPaint);

    final targetBorderPaint = Paint()
      ..color = const Color(0xFF00FF88).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), targetZoneR, targetBorderPaint);

    // ── Warning ring ──────────────────────────────────────────────────
    final warnPaint = Paint()
      ..color = const Color(0xFFFFD740).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(cx, cy), r * 0.4, warnPaint);

    // ── Bubble ────────────────────────────────────────────────────────
    final bubbleCx = cx + bubbleX * r * 0.85;
    final bubbleCy = cy + bubbleY * r * 0.85;
    final bubbleR = r * 0.12;

    // Glow
    for (int i = 3; i >= 1; i--) {
      final glowPaint = Paint()
        ..color = statusColor.withValues(alpha: 0.08 * i)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(bubbleCx, bubbleCy), bubbleR + i * 4, glowPaint);
    }

    // Bubble fill
    final bubblePaint = Paint()
      ..shader =
          RadialGradient(
            colors: [statusColor, statusColor.withValues(alpha: 0.5)],
            center: const Alignment(-0.3, -0.3),
          ).createShader(
            Rect.fromCircle(
              center: Offset(bubbleCx, bubbleCy),
              radius: bubbleR,
            ),
          );
    canvas.drawCircle(Offset(bubbleCx, bubbleCy), bubbleR, bubblePaint);

    // Bubble highlight
    final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawCircle(
      Offset(bubbleCx - bubbleR * 0.3, bubbleCy - bubbleR * 0.3),
      bubbleR * 0.3,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(_BubbleLevelPainter old) =>
      old.bubbleX != bubbleX ||
      old.bubbleY != bubbleY ||
      old.statusColor != statusColor;
}

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF00FF88),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'PRO',
        style: TextStyle(
          color: Colors.black,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
