// permission_request_screen.dart — App Store Ready Permission Flow
// Apple & Google: İzin nedenini açıklayan modern pop-up'lar
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'map_screen.dart';

class PermissionRequestScreen extends StatefulWidget {
  const PermissionRequestScreen({super.key});

  @override
  State<PermissionRequestScreen> createState() =>
      _PermissionRequestScreenState();
}

class _PermissionRequestScreenState extends State<PermissionRequestScreen> {
  int _step = 0; // 0=location, 1=notification, 2=done
  bool _requesting = false;

  static const List<_PermissionInfo> _permissions = [
    _PermissionInfo(
      emoji: '📍',
      title: 'Location Access',
      reason:
          'US Outdoor Navigator uses your location to find nearby campgrounds, '
          'show real-time wildfire proximity, and enable the SOS emergency feature.\n\n'
          'Your location is never stored or shared with third parties.',
      accentColor: Color(0xFF00FF88),
      note: 'Required for core functionality',
    ),
    _PermissionInfo(
      emoji: '🔔',
      title: 'Notifications',
      reason:
          'We send critical alerts when:\n'
          '• Wildfires are detected near your location\n'
          '• Severe weather threatens your campsite\n'
          '• Your Dead Man\'s Switch check-in is overdue\n\n'
          'You can customize alert types in Settings anytime.',
      accentColor: Color(0xFFFF6B00),
      note: 'Recommended for safety alerts',
    ),
  ];

  Future<void> _requestCurrent() async {
    if (_requesting) return;
    setState(() => _requesting = true);

    try {
      if (_step == 0) {
        final status = await Permission.locationWhenInUse.request();
        if (status.isGranted) {
          // Also request always (for background SOS)
          await Permission.locationAlways.request();
        }
      } else if (_step == 1) {
        await Permission.notification.request();
      }

      if (mounted) {
        if (_step < _permissions.length - 1) {
          setState(() {
            _step++;
            _requesting = false;
          });
        } else {
          _goToApp();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _requesting = false);
    }
  }

  void _skip() {
    if (_step < _permissions.length - 1) {
      setState(() => _step++);
    } else {
      _goToApp();
    }
  }

  void _goToApp() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MapScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final info = _permissions[_step];
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress dots
              Row(
                children: List.generate(
                  _permissions.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 6),
                    width: _step == i ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _step >= i ? info.accentColor : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const Spacer(),

              // ── Big emoji ──────────────────────────────────────────────
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    key: ValueKey(_step),
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: info.accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: info.accentColor.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: info.accentColor.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        info.emoji,
                        style: const TextStyle(fontSize: 52),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // ── Badge ────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: info.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: info.accentColor.withOpacity(0.3)),
                ),
                child: Text(
                  info.note.toUpperCase(),
                  style: TextStyle(
                    color: info.accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Title ─────────────────────────────────────────────────────
              Text(
                info.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),

              // ── Reason text ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1526),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  info.reason,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 14,
                    height: 1.7,
                  ),
                ),
              ),
              const Spacer(),

              // ── Allow Button ───────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _requesting ? null : _requestCurrent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: info.accentColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _requesting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black.withOpacity(0.6),
                          ),
                        )
                      : Text(
                          'Allow ${info.title}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Skip ──────────────────────────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    _step < _permissions.length - 1
                        ? 'Not now — ask later'
                        : 'Skip & continue',
                    style: const TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Model ───────────────────────────────────────────────────────────────────
class _PermissionInfo {
  final String emoji;
  final String title;
  final String reason;
  final Color accentColor;
  final String note;
  const _PermissionInfo({
    required this.emoji,
    required this.title,
    required this.reason,
    required this.accentColor,
    required this.note,
  });
}
