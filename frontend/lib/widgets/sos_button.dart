// sos_button.dart — Ultra Premium SOS / PANIC Butonu
// Tasarım: Koyu lacivert + parlayan kırmızı + uzay kokpiti estetiği
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Sağ alt köşeye yerleştirilen hafif parlayan kırmızı SOS butonu.
/// Basılı tutunca onay dialog'u açılır (yanlışlıkla tetiklemeyi önler).
/// SizedBox(86×86) ile pulse animasyonu sabit alan kaplar → sidebar çakışmaz.
class SosButton extends StatefulWidget {
  final double lat;
  final double lon;
  final String userId;
  final String? emergencyContact;
  final Future<void> Function({
    required double lat,
    required double lon,
    required String userId,
    String emergencyContact,
  })
  onSosTrigger;

  const SosButton({
    super.key,
    required this.lat,
    required this.lon,
    required this.userId,
    required this.onSosTrigger,
    this.emergencyContact,
  });

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _isSending = false;

  static const _kOrange = Color(0xFFFF6B00);
  static const _kRedGlow = Color(0xFFFF1744);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm(BuildContext ctx) async {
    HapticFeedback.heavyImpact();
    final confirmed = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (c) => _SosConfirmDialog(
        lat: widget.lat,
        lon: widget.lon,
        emergencyContact: widget.emergencyContact,
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _isSending = true);
      try {
        await widget.onSosTrigger(
          lat: widget.lat,
          lon: widget.lon,
          userId: widget.userId,
          emergencyContact: widget.emergencyContact ?? '',
        );
        if (mounted) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              backgroundColor: _kOrange,
              content: const Row(
                children: [
                  Icon(Icons.sos, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'SOS GÖNDERİLDİ — Koordinatlar kaydedildi!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔑 SizedBox(86×86) → pulse animasyonu sabit alan kaplar
    // LayerSidebar (right:8) ile alt buton col (right:80) çakışmaz
    return SizedBox(
      width: 86,
      height: 86,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (ctx, child) {
          return GestureDetector(
            onLongPress: () => _confirm(context),
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Basılı tutun → SOS Aktif',
                    style: TextStyle(color: Colors.white),
                  ),
                  duration: Duration(seconds: 2),
                  backgroundColor: Color(0xFF8B0000),
                ),
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dış parlama halkası — 86px içinde kısıtlı
                Container(
                  width: 72 * _pulseAnim.value,
                  height: 72 * _pulseAnim.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kRedGlow.withValues(alpha: 0.15 * _pulseAnim.value),
                  ),
                ),
                // Ana buton (sabit 58px)
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFF4444), Color(0xFF8B0000)],
                      center: Alignment(-0.3, -0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kRedGlow.withValues(alpha: 0.6),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: _kRedGlow.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 6,
                      ),
                    ],
                    border: Border.all(color: _kRedGlow, width: 1.5),
                  ),
                  child: _isSending
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sos, color: Colors.white, size: 22),
                            Text(
                              'SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Onay Dialog'u ─────────────────────────────────────────────────────────────
class _SosConfirmDialog extends StatelessWidget {
  final double lat;
  final double lon;
  final String? emergencyContact;

  const _SosConfirmDialog({
    required this.lat,
    required this.lon,
    this.emergencyContact,
  });

  static const _kGreen = Color(0xFF00FF88);
  static const _kOrange = Color(0xFFFF6B00);
  static const _kRed = Color(0xFFFF1744);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0D1526),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFFF1744), width: 1.5),
      ),
      title: const Row(
        children: [
          Icon(Icons.sos, color: Color(0xFFFF1744), size: 28),
          SizedBox(width: 10),
          Text(
            'ACİL DURUM',
            style: TextStyle(
              color: Color(0xFFFF1744),
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SOS sinyali göndermeyi onaylıyor musunuz?',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.location_on,
            color: _kGreen,
            text: 'Konum: ${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}',
          ),
          if (emergencyContact?.isNotEmpty == true)
            _InfoRow(
              icon: Icons.contact_phone,
              color: _kOrange,
              text: 'Acil kişi: $emergencyContact',
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A0808),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kOrange.withValues(alpha: 0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFFF6B00), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Koordinatlarınız log\'a kaydedilecek. '
                    'Gerçek acil durumda 911\'i arayın.',
                    style: TextStyle(color: Color(0xFFFF6B00), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.cancel, color: Colors.grey),
          label: const Text('İPTAL', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.sos, size: 18),
          label: const Text(
            'SOS GÖNDER',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
