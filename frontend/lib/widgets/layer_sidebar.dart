import 'package:flutter/material.dart';
import '../models/app_state.dart';
import 'package:provider/provider.dart';

/// Sağ kenar paneli — harita katmanlarını aç/kapat
class LayerSidebar extends StatelessWidget {
  /// Opsiyonel: Layer toggle edilince çağrılır (API fetch için)
  final void Function(String layer)? onLayerToggled;

  const LayerSidebar({super.key, this.onLayerToggled});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    void toggle(String layer) {
      appState.toggleLayer(layer);
      onLayerToggled?.call(layer);
    }

    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: const Color(0xCC0D1421),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          // ── Layers label ──
          const Text(
            'LAYERS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 8,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          _LayerBtn(
            emoji: '🏕️',
            label: 'Camps',
            active: appState.showCampgrounds,
            activeColor: const Color(0xFF00C853),
            onTap: () => toggle('campgrounds'),
          ),
          _LayerBtn(
            emoji: '🔥',
            label: 'Fires',
            active: appState.showFires,
            activeColor: Colors.red,
            onTap: () => toggle('fires'),
          ),
          _LayerBtn(
            emoji: '⛽',
            label: 'Fuel',
            active: appState.showFuel,
            activeColor: Colors.orange,
            onTap: () => toggle('fuel'),
          ),
          _LayerBtn(
            emoji: '🔌',
            label: 'EV',
            active: appState.showEvCharge,
            activeColor: Colors.blue,
            onTap: () => toggle('ev'),
          ),
          _LayerBtn(
            emoji: '🛒',
            label: 'Market',
            active: appState.showMarkets,
            activeColor: Colors.purple,
            onTap: () => toggle('markets'),
          ),
          _LayerBtn(
            emoji: '🔧',
            label: 'Repair',
            active: appState.showRvRepair,
            activeColor: Colors.amber,
            onTap: () => toggle('repair'),
          ),
          _LayerBtn(
            emoji: '🚧',
            label: 'Roads',
            active: appState.showRoadWork,
            activeColor: Colors.deepOrange,
            onTap: () => toggle('roads'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Divider(color: Colors.white12, height: 1),
          ),
          _LayerBtn(
            emoji: '☀️',
            label: 'Solar',
            active: appState.showSolarHeatmap,
            activeColor: Color(0xFFFFD600),
            onTap: () => toggle('solar_heat'),
          ),
          _LayerBtn(
            emoji: '📶',
            label: 'Signal',
            active: appState.showCellHeatmap,
            activeColor: Color(0xFF00FF88),
            onTap: () => toggle('cell_heat'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Divider(color: Colors.white12, height: 1),
          ),
          _LayerBtn(
            emoji: '🏞️',
            label: 'BLM',
            active: appState.showBlmOverlay,
            activeColor: Color(0xFF8BC34A),
            onTap: () => toggle('blm'),
          ),
          _LayerBtn(
            emoji: '⛰️',
            label: '3D Arazi',
            active: appState.showTerrain3d,
            activeColor: Color(0xFF795548),
            onTap: () => toggle('terrain3d'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LayerBtn extends StatelessWidget {
  final String emoji;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _LayerBtn({
    required this.emoji,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: Tooltip(
        message: label,
        preferBelow: false,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: active
                  ? activeColor.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? activeColor : Colors.white24,
                width: active ? 2 : 1,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? activeColor : Colors.white38,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
