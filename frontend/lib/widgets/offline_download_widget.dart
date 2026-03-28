// offline_download_widget.dart — Offline Eyalet İndirme Arayüzü
// "Download Utah" tek tuş ile eyalet kamp verilerini ve meta bilgileri indirir
import 'package:flutter/material.dart';

// ─── Model ───────────────────────────────────────────────────────────────────
class StateDownloadInfo {
  final String code;
  final String name;
  final String emoji;
  final int campCount;
  final double sizeMb;

  const StateDownloadInfo({
    required this.code,
    required this.name,
    required this.emoji,
    required this.campCount,
    required this.sizeMb,
  });
}

// ─── Dialog Açıcı ─────────────────────────────────────────────────────────────
void showOfflineDownloadDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _OfflineDownloadSheet(),
  );
}

// ─── Statik Eyalet Listesi ────────────────────────────────────────────────────
const _stateList = [
  StateDownloadInfo(
    code: 'CA',
    name: 'California',
    emoji: '🌴',
    campCount: 312,
    sizeMb: 4.2,
  ),
  StateDownloadInfo(
    code: 'AZ',
    name: 'Arizona',
    emoji: '🌵',
    campCount: 187,
    sizeMb: 2.8,
  ),
  StateDownloadInfo(
    code: 'WA',
    name: 'Washington',
    emoji: '🌲',
    campCount: 241,
    sizeMb: 3.6,
  ),
  StateDownloadInfo(
    code: 'OR',
    name: 'Oregon',
    emoji: '🌿',
    campCount: 198,
    sizeMb: 3.0,
  ),
  StateDownloadInfo(
    code: 'UT',
    name: 'Utah',
    emoji: '🏜️',
    campCount: 156,
    sizeMb: 2.4,
  ),
  StateDownloadInfo(
    code: 'CO',
    name: 'Colorado',
    emoji: '⛰️',
    campCount: 203,
    sizeMb: 3.1,
  ),
  StateDownloadInfo(
    code: 'NV',
    name: 'Nevada',
    emoji: '🎰',
    campCount: 89,
    sizeMb: 1.5,
  ),
  StateDownloadInfo(
    code: 'MT',
    name: 'Montana',
    emoji: '🦌',
    campCount: 134,
    sizeMb: 2.1,
  ),
  StateDownloadInfo(
    code: 'WY',
    name: 'Wyoming',
    emoji: '🦅',
    campCount: 112,
    sizeMb: 1.8,
  ),
  StateDownloadInfo(
    code: 'ID',
    name: 'Idaho',
    emoji: '🥔',
    campCount: 98,
    sizeMb: 1.6,
  ),
  StateDownloadInfo(
    code: 'TX',
    name: 'Texas',
    emoji: '🤠',
    campCount: 267,
    sizeMb: 4.0,
  ),
  StateDownloadInfo(
    code: 'FL',
    name: 'Florida',
    emoji: '🐊',
    campCount: 178,
    sizeMb: 2.7,
  ),
  StateDownloadInfo(
    code: 'TN',
    name: 'Tennessee',
    emoji: '🎸',
    campCount: 145,
    sizeMb: 2.2,
  ),
  StateDownloadInfo(
    code: 'NC',
    name: 'N. Carolina',
    emoji: '🌊',
    campCount: 167,
    sizeMb: 2.5,
  ),
];

// ─── Sheet Widget ─────────────────────────────────────────────────────────────
class _OfflineDownloadSheet extends StatefulWidget {
  const _OfflineDownloadSheet();
  @override
  State<_OfflineDownloadSheet> createState() => _OfflineDownloadSheetState();
}

class _OfflineDownloadSheetState extends State<_OfflineDownloadSheet> {
  final Set<String> _downloaded = {'CA'}; // Simüle edilmiş indirilenler
  final Set<String> _downloading = {};
  final Map<String, double> _progress = {};

  void _download(StateDownloadInfo state) async {
    if (_downloaded.contains(state.code) || _downloading.contains(state.code))
      return;

    setState(() {
      _downloading.add(state.code);
      _progress[state.code] = 0.0;
    });

    // Simülasyon: gerçekte Hive/SQLite'a kaydedilecek
    final steps = 20;
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() => _progress[state.code] = i / steps);
    }

    if (!mounted) return;
    setState(() {
      _downloading.remove(state.code);
      _downloaded.add(state.code);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${state.emoji} ${state.name} indirildi! '
            '(${state.campCount} kamp, ${state.sizeMb}MB)',
          ),
          backgroundColor: const Color(0xFF0D1526),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _delete(String code) {
    if (code == 'CA') return; // Varsayılan korumalı
    setState(() => _downloaded.remove(code));
  }

  double get _totalMb => _downloaded
      .map(
        (c) => _stateList
            .firstWhere(
              (s) => s.code == c,
              orElse: () => const StateDownloadInfo(
                code: '',
                name: '',
                emoji: '',
                campCount: 0,
                sizeMb: 0,
              ),
            )
            .sizeMb,
      )
      .fold(0.0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1526),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.download_for_offline,
                  color: Color(0xFF00FF88),
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Çevrimdışı Harita',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        'Eyalet verilerini indirerek internet olmadan kullanın',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white38),
                ),
              ],
            ),
          ),

          // ── Depolama özeti ─────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1525),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.storage, color: Color(0xFF4FC3F7), size: 16),
                const SizedBox(width: 6),
                Text(
                  '${_downloaded.length} eyalet · '
                  '${_totalMb.toStringAsFixed(1)} MB kullanıldı',
                  style: const TextStyle(
                    color: Color(0xFF4FC3F7),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  'Max ~50 MB önerilen',
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                ),
              ],
            ),
          ),

          // ── Liste ──────────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _stateList.length,
              itemBuilder: (_, i) {
                final state = _stateList[i];
                final isDownloaded = _downloaded.contains(state.code);
                final isDownloading = _downloading.contains(state.code);
                final progress = _progress[state.code] ?? 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDownloaded
                        ? const Color(0xFF00FF88).withOpacity(0.06)
                        : const Color(0xFF0A1525),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDownloaded
                          ? const Color(0xFF00FF88).withOpacity(0.4)
                          : Colors.white10,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            state.emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${state.name} (${state.code})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${state.campCount} kamp · '
                                  '${state.sizeMb} MB',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Buton
                          if (isDownloaded)
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF00FF88),
                                  size: 18,
                                ),
                                if (state.code != 'CA')
                                  GestureDetector(
                                    onTap: () => _delete(state.code),
                                    child: const Padding(
                                      padding: EdgeInsets.only(left: 6),
                                      child: Icon(
                                        Icons.delete_outline,
                                        color: Colors.white30,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          else if (isDownloading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF00FF88),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: () => _download(state),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF00FF88,
                                  ).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF00FF88),
                                  ),
                                ),
                                child: const Text(
                                  'İndir',
                                  style: TextStyle(
                                    color: Color(0xFF00FF88),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Progress bar
                      if (isDownloading) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF00FF88),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
