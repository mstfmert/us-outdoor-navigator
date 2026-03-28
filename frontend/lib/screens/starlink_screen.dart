// starlink_screen.dart — Starlink AR Signal Analyzer
// ✅ PRO FEATURE | ✅ Camera preview + compass overlay
// ✅ Obstruction detection | ✅ Satellite pass simulation
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:camera/camera.dart';

class StarlinkScreen extends StatefulWidget {
  const StarlinkScreen({super.key});

  @override
  State<StarlinkScreen> createState() => _StarlinkScreenState();
}

class _StarlinkScreenState extends State<StarlinkScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraCtrl;
  StreamSubscription<CompassEvent>? _compassSub;

  double _heading = 0.0;
  double _brightness = 0.0; // 0.0 = dark (obstruction), 1.0 = clear sky
  bool _obstructionDetected = false;
  bool _cameraReady = false;
  bool _cameraError = false;

  // Simüle Starlink uydu geçişleri
  final List<_SatellitePass> _passes = [];
  late AnimationController _satAnimCtrl;
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Auto-Pause
    _initCamera();
    _initCompass();
    _generateSatPasses();

    _satAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _generateSatPasses(),
    );
  }

  // ── Auto-Pause: Kamera + Pusula arka planda durur ─────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Kamerayı durdur (pil + ısı koruması)
      _cameraCtrl?.stopImageStream();
      _satAnimCtrl.stop();
      _compassSub?.pause();
      debugPrint('⏸️ Starlink AR duraklatıldı (arka plan)');
    } else if (state == AppLifecycleState.resumed) {
      // Kamerayı yeniden başlat
      if (_cameraCtrl != null && _cameraCtrl!.value.isInitialized) {
        _cameraCtrl!.startImageStream(_analyzeBrightness);
      }
      _satAnimCtrl.repeat();
      _compassSub?.resume();
      debugPrint('▶️ Starlink AR yeniden başlatıldı');
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = true);
        return;
      }
      _cameraCtrl = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraCtrl!.initialize();

      // Brightness analizi için periyodik frame okuma
      _cameraCtrl!.startImageStream((img) {
        _analyzeBrightness(img);
      });

      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      if (mounted) setState(() => _cameraError = true);
    }
  }

  void _initCompass() {
    _compassSub = FlutterCompass.events?.listen((event) {
      if (mounted && event.heading != null) {
        setState(() => _heading = event.heading!);
      }
    });
  }

  void _analyzeBrightness(CameraImage img) {
    // YUV/NV21 formatında Y plane'den ortalama parlaklık hesapla
    if (img.planes.isEmpty) return;
    final yPlane = img.planes[0];
    final bytes = yPlane.bytes;

    int sum = 0;
    final step = bytes.length ~/ 100; // 100 örnek al
    for (int i = 0; i < bytes.length; i += math.max(1, step)) {
      sum += bytes[i];
    }
    final avg = sum / (bytes.length / math.max(1, step));
    final brightness = (avg / 255.0).clamp(0.0, 1.0);

    if (mounted) {
      setState(() {
        _brightness = brightness;
        // Parlaklık 0.15'in altındaysa engel tespit edildi
        _obstructionDetected = brightness < 0.15;
      });
    }
  }

  void _generateSatPasses() {
    final rng = math.Random();
    setState(() {
      _passes.clear();
      for (int i = 0; i < 6; i++) {
        _passes.add(
          _SatellitePass(
            startAzimuth: rng.nextDouble() * 360,
            elevation: 20 + rng.nextDouble() * 60,
            passMinutes: 3 + rng.nextInt(8),
            signalStrength: 0.4 + rng.nextDouble() * 0.6,
            isNextPass: i == 0,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraCtrl?.stopImageStream();
    _cameraCtrl?.dispose();
    _compassSub?.cancel();
    _satAnimCtrl.dispose();
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera Background ────────────────────────────────────────
          if (_cameraReady && _cameraCtrl != null)
            Positioned.fill(child: CameraPreview(_cameraCtrl!))
          else
            _buildFallbackBackground(),

          // ── Dark overlay ─────────────────────────────────────────────
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: _cameraReady ? 0.3 : 0.8),
            ),
          ),

          // ── AR Overlay ───────────────────────────────────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _SkyOverlayPainter(
                heading: _heading,
                passes: _passes,
                animation: _satAnimCtrl,
              ),
            ),
          ),

          // ── Obstruction Alert ────────────────────────────────────────
          if (_obstructionDetected)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 20,
              right: 20,
              child: _buildObstructionAlert(),
            ),

          // ── Top Bar ──────────────────────────────────────────────────
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),

          // ── Bottom Panel ─────────────────────────────────────────────
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomPanel()),
        ],
      ),
    );
  }

  Widget _buildFallbackBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF020810), Color(0xFF0A0E17)],
        ),
      ),
      child: _cameraError
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📷', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text(
                    'Camera unavailable\nRunning in simulation mode',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF00FF88).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              '🛰️  Starlink AR View',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            // Compass heading
            Text(
              '${_heading.toStringAsFixed(0)}°  ${_headingLabel(_heading)}',
              style: const TextStyle(
                color: Color(0xFF00FF88),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObstructionAlert() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF1744).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF1744).withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Row(
        children: [
          Text('🌲', style: TextStyle(fontSize: 22)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OBSTRUCTION DETECTED',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Trees or obstacles blocking satellite view. Move RV or adjust dish angle.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF00B4FF).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Signal quality
            Row(
              children: [
                const Text(
                  'SIGNAL QUALITY',
                  style: TextStyle(
                    color: Color(0xFF00B4FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                _buildSignalBar(_brightness),
              ],
            ),
            const SizedBox(height: 12),
            // Next passes
            const Text(
              'UPCOMING PASSES',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _passes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _buildPassChip(_passes[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalBar(double quality) {
    final barCount = 5;
    final filled = (quality * barCount).round();
    return Row(
      children: List.generate(barCount, (i) {
        return Container(
          width: 14,
          height: 8 + i * 3.0,
          margin: const EdgeInsets.only(left: 3),
          decoration: BoxDecoration(
            color: i < filled
                ? const Color(0xFF00FF88)
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildPassChip(_SatellitePass pass) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: pass.isNextPass
            ? const Color(0xFF00FF88).withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: pass.isNextPass
              ? const Color(0xFF00FF88).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${pass.passMinutes}min',
            style: TextStyle(
              color: pass.isNextPass ? const Color(0xFF00FF88) : Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '${pass.elevation.toStringAsFixed(0)}° el.',
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _headingLabel(double h) {
    if (h < 22.5 || h >= 337.5) return 'N';
    if (h < 67.5) return 'NE';
    if (h < 112.5) return 'E';
    if (h < 157.5) return 'SE';
    if (h < 202.5) return 'S';
    if (h < 247.5) return 'SW';
    if (h < 292.5) return 'W';
    return 'NW';
  }
}

// ── AR Sky Overlay Painter ────────────────────────────────────────────────────
class _SkyOverlayPainter extends CustomPainter {
  final double heading;
  final List<_SatellitePass> passes;
  final Animation<double> animation;

  _SkyOverlayPainter({
    required this.heading,
    required this.passes,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.35;

    // ── Horizon line ──────────────────────────────────────────────────
    final horizPaint = Paint()
      ..color = const Color(0xFF00FF88).withValues(alpha: 0.15)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height * 0.6),
      Offset(size.width, size.height * 0.6),
      horizPaint,
    );

    // ── Sky dome circle ───────────────────────────────────────────────
    final domePaint = Paint()
      ..color = const Color(0xFF00B4FF).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: size.width * 0.85,
        height: size.height * 0.5,
      ),
      domePaint,
    );

    // ── Satellite paths ───────────────────────────────────────────────
    for (int i = 0; i < passes.length; i++) {
      final pass = passes[i];
      final relAz = ((pass.startAzimuth - heading) % 360) * (math.pi / 180);
      final elevFactor = 1.0 - (pass.elevation / 90.0);

      final px = cx + (size.width * 0.4 * elevFactor * math.sin(relAz));
      final py = cy - (size.height * 0.2 * (1.0 - elevFactor));

      // Path line
      final pathPaint = Paint()
        ..color = const Color(
          0xFF00FF88,
        ).withValues(alpha: 0.2 * pass.signalStrength)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      final path = Path();
      path.moveTo(px - 30, py);
      path.lineTo(px + 30, py);
      canvas.drawPath(path, pathPaint);

      // Satellite dot with animation
      final animOffset = animation.value * 60 - 30;
      final dotPaint = Paint()
        ..color = pass.isNextPass
            ? const Color(0xFF00FF88)
            : const Color(0xFF00B4FF);
      canvas.drawCircle(Offset(px + animOffset, py), 4, dotPaint);

      // Signal strength ring
      if (pass.isNextPass) {
        final ringPaint = Paint()
          ..color = const Color(
            0xFF00FF88,
          ).withValues(alpha: 0.3 * animation.value)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(
          Offset(px + animOffset, py),
          8 + 4 * animation.value,
          ringPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SkyOverlayPainter old) =>
      old.heading != heading || old.passes != passes;
}

class _SatellitePass {
  final double startAzimuth;
  final double elevation;
  final int passMinutes;
  final double signalStrength;
  final bool isNextPass;

  const _SatellitePass({
    required this.startAzimuth,
    required this.elevation,
    required this.passMinutes,
    required this.signalStrength,
    required this.isNextPass,
  });
}
