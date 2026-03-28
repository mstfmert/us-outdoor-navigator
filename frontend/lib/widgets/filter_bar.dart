import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/camp_filter.dart';

/// Haritanın üst kısmında yatay kayan filtre çipleri
class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final filter = appState.campFilter;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xE00D1421),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          // ── Filtre aktif badge ─────────────────────────────────────────
          if (filter.isActive)
            _ActiveBadge(
              onClear: () => appState.setCampFilter(const CampFilter()),
            ),

          // ── 4.5+ Yıldız ───────────────────────────────────────────────
          _Chip(
            label: '⭐ 4.5+',
            active: filter.minRating >= 4.5,
            onTap: () => appState.setCampFilter(
              filter.copyWith(minRating: filter.minRating >= 4.5 ? 0 : 4.5),
            ),
          ),

          // ── Electric Hookup ────────────────────────────────────────────
          _Chip(
            label: '🔌 Electric',
            active: filter.requireElectric,
            onTap: () => appState.setCampFilter(
              filter.copyWith(requireElectric: !filter.requireElectric),
            ),
          ),

          // ── Water Access ───────────────────────────────────────────────
          _Chip(
            label: '💧 Water',
            active: filter.requireWater,
            onTap: () => appState.setCampFilter(
              filter.copyWith(requireWater: !filter.requireWater),
            ),
          ),

          // ── RV > 35ft ─────────────────────────────────────────────────
          _Chip(
            label: '🚌 RV 35ft+',
            active: filter.minRvLength >= 35,
            onTap: () => appState.setCampFilter(
              filter.copyWith(minRvLength: filter.minRvLength >= 35 ? 0 : 35),
            ),
          ),

          // ── RV > 45ft ─────────────────────────────────────────────────
          _Chip(
            label: '🚐 RV 45ft+',
            active: filter.minRvLength >= 45,
            onTap: () => appState.setCampFilter(
              filter.copyWith(minRvLength: filter.minRvLength >= 45 ? 0 : 45),
            ),
          ),

          // ── Under $50 ─────────────────────────────────────────────────
          _Chip(
            label: '💲 Under \$50',
            active: filter.maxPricePerNight <= 50,
            onTap: () => appState.setCampFilter(
              filter.copyWith(
                maxPricePerNight: filter.maxPricePerNight <= 50 ? 500 : 50,
              ),
            ),
          ),

          // ── Free Camping ──────────────────────────────────────────────
          _Chip(
            label: '🆓 Free',
            active: filter.maxPricePerNight <= 0,
            onTap: () => appState.setCampFilter(
              filter.copyWith(
                maxPricePerNight: filter.maxPricePerNight <= 0 ? 500 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF00C853).withValues(alpha: 0.25)
              : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF00C853) : Colors.white24,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF00C853) : Colors.white70,
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  final VoidCallback onClear;
  const _ActiveBadge({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClear,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange, width: 1.5),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt, size: 14, color: Colors.orange),
            SizedBox(width: 4),
            Text(
              'Clear',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
