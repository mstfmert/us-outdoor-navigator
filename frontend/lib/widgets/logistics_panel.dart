import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/campground.dart';

class LogisticsPanel extends StatefulWidget {
  final Campground campground;
  final VoidCallback onClose;

  const LogisticsPanel({
    super.key,
    required this.campground,
    required this.onClose,
  });

  @override
  State<LogisticsPanel> createState() => _LogisticsPanelState();
}

class _LogisticsPanelState extends State<LogisticsPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closePanel() {
    _controller.reverse().then((_) => widget.onClose());
  }

  // ─── Google Maps veya geo URI ile navigasyon başlat ──────────────────────
  Future<void> _startNavigation() async {
    final lat = widget.campground.latitude;
    final lon = widget.campground.longitude;
    final campName = Uri.encodeComponent(widget.campground.name);

    // Evrensel Google Maps URL (Android + iOS'ta Google Maps uygulamasını açar)
    final googleUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&destination_place_id=$campName&travelmode=driving',
    );

    // Fallback: geo URI (Android yerel harita uygulamaları)
    final geoUri = Uri.parse('geo:$lat,$lon?q=$lat,$lon($campName)');

    try {
      if (await canLaunchUrl(googleUri)) {
        await launchUrl(googleUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Harita uygulaması açılamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Navigasyon hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPriceRow() {
    final camp = widget.campground;
    return Row(
      children: [
        const Icon(Icons.attach_money, size: 20, color: Colors.white70),
        const SizedBox(width: 8),
        const Text(
          'Price:',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: camp.isFree
                ? Colors.green.withOpacity(0.2)
                : Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: camp.isFree ? Colors.green : Colors.blue,
              width: 1,
            ),
          ),
          child: Text(
            camp.priceDisplay,
            style: TextStyle(
              color: camp.isFree ? Colors.green : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceRow() {
    return Row(
      children: [
        const Icon(Icons.directions_car, size: 20, color: Colors.white70),
        const SizedBox(width: 8),
        const Text(
          'Distance to you:',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const Spacer(),
        Text(
          '${widget.campground.distanceToUser.toStringAsFixed(1)} mi',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFuelRow() {
    return Row(
      children: [
        const Icon(Icons.local_gas_station, size: 20, color: Colors.white70),
        const SizedBox(width: 8),
        const Text(
          'Nearest fuel:',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${widget.campground.nearestFuelMiles.toStringAsFixed(1)} mi',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              widget.campground.fuelStationName,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRvLengthRow() {
    return Row(
      children: [
        const Icon(Icons.rv_hookup, size: 20, color: Colors.white70),
        const SizedBox(width: 8),
        const Text(
          'RV length limit:',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const Spacer(),
        Text(
          widget.campground.rvLengthDisplay,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildAmenitiesRow() {
    final amenities = widget.campground.amenities;
    if (amenities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Amenities:',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: amenities.map((amenity) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                amenity,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sürükleme çubuğu
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Başlık ve kapatma butonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.campground.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _closePanel,
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Kamp alanı detayları
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  _buildPriceRow(),
                  const SizedBox(height: 12),
                  _buildDistanceRow(),
                  const SizedBox(height: 12),
                  _buildFuelRow(),
                  const SizedBox(height: 12),
                  _buildRvLengthRow(),
                  _buildAmenitiesRow(),
                ],
              ),
            ),

            // Su bilgisi
            if (widget.campground.hasWater)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.water_drop, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Water available',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Potable',
                        style: TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // ─── START NAVIGATION butonu (gerçek navigasyon) ─────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startNavigation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'START NAVIGATION',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
