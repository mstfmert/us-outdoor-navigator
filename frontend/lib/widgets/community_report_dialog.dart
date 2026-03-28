// community_report_dialog.dart — Sosyal Rapor Arayüzü
// Kullanıcı: Ayı gördüm / Yol kapalı / Yangın tehlikesi raporu girebilir
import 'package:flutter/material.dart';
import '../models/community_report.dart';
import '../models/app_state.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';

// ─── Dialog Açıcı ─────────────────────────────────────────────────────────────
void showCommunityReportDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CommunityReportSheet(),
  );
}

// ─── Report Sheet ─────────────────────────────────────────────────────────────
class _CommunityReportSheet extends StatefulWidget {
  const _CommunityReportSheet();
  @override
  State<_CommunityReportSheet> createState() => _CommunityReportSheetState();
}

class _CommunityReportSheetState extends State<_CommunityReportSheet> {
  ReportType _selectedType = ReportType.other;
  final TextEditingController _descController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  static const Map<ReportType, _ReportTypeInfo> _typeInfo = {
    ReportType.bearSighting: _ReportTypeInfo(
      emoji: '🐻',
      label: 'Ayı Gördüm',
      hint: 'Nerede gördünüz? Kaç kişi vardı?',
      color: Color(0xFF8D6E63),
    ),
    ReportType.roadClosed: _ReportTypeInfo(
      emoji: '🚧',
      label: 'Yol Kapalı',
      hint: 'Neden kapalı? Geçiş mümkün mü?',
      color: Color(0xFFFF1744),
    ),
    ReportType.fireHazard: _ReportTypeInfo(
      emoji: '🔥',
      label: 'Yangın Tehlikesi',
      hint: 'Duman mı görüyorsunuz? Alev var mı?',
      color: Color(0xFFFF6B00),
    ),
    ReportType.other: _ReportTypeInfo(
      emoji: '📍',
      label: 'Diğer Durum',
      hint: 'Ne gözlemlediniz?',
      color: Color(0xFF00FF88),
    ),
  };

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final appState = context.read<AppState>();
    final apiService = context.read<ApiService>();
    final lat = appState.currentLocation?.latitude ?? 33.8734;
    final lon = appState.currentLocation?.longitude ?? -115.9010;

    setState(() => _isSubmitting = true);
    try {
      final desc = _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : _typeInfo[_selectedType]!.label;
      final report = await apiService.submitReport(
        lat: lat,
        lon: lon,
        type: _selectedType,
        description: desc,
      );
      if (report != null && mounted) {
        appState.addCommunityReport(report);
      } else if (mounted) {
        // API offline → yerel rapor oluştur
        appState.addCommunityReport(
          CommunityReport(
            id: 'local_${DateTime.now().millisecondsSinceEpoch}',
            type: _selectedType,
            latitude: lat,
            longitude: lon,
            description: desc,
            timestamp: DateTime.now(),
          ),
        );
      }
      if (mounted) setState(() => _submitted = true);
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1526),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _submitted
              ? _buildSuccess()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    Row(
                      children: [
                        const Icon(
                          Icons.report_gmailerrorred,
                          color: Color(0xFF00FF88),
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Durum Raporu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Çevrenizde ne gözlemlediniz?',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // ── Rapor Tipi Seçici ────────────────────────────────────
                    SizedBox(
                      height: 88,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: ReportType.values.map((type) {
                          final info = _typeInfo[type]!;
                          final isSelected = _selectedType == type;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedType = type),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 90,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? info.color.withOpacity(0.18)
                                    : const Color(0xFF0A1525),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? info.color
                                      : Colors.white12,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: info.color.withOpacity(0.3),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    info.emoji,
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    info.label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? info.color
                                          : Colors.white54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Açıklama Alanı ────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1525),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: TextField(
                        controller: _descController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _typeInfo[_selectedType]!.hint,
                          hintStyle: const TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Konum bilgisi
                    Consumer<AppState>(
                      builder: (_, appState, __) {
                        final loc = appState.currentLocation;
                        return Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Color(0xFF00FF88),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              loc != null
                                  ? '${loc.latitude.toStringAsFixed(4)}, '
                                        '${loc.longitude.toStringAsFixed(4)}'
                                  : 'Konum alınıyor...',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // ── Gönder Butonu ─────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _typeInfo[_selectedType]!.color,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                _typeInfo[_selectedType]!.emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                        label: Text(
                          _isSubmitting ? 'Gönderiliyor...' : 'Raporu Gönder',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        const Icon(
          Icons.check_circle_outline,
          color: Color(0xFF00FF88),
          size: 64,
        ),
        const SizedBox(height: 16),
        const Text(
          'Rapor Gönderildi!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Topluluk raporu haritaya eklendi. Teşekkürler!',
          style: TextStyle(color: Colors.grey[400], fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─── Tip Bilgi Modeli ─────────────────────────────────────────────────────────
class _ReportTypeInfo {
  final String emoji;
  final String label;
  final String hint;
  final Color color;
  const _ReportTypeInfo({
    required this.emoji,
    required this.label,
    required this.hint,
    required this.color,
  });
}
