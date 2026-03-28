// data_credits_screen.dart — US Outdoor Navigator
// Open Data Sources & Third-Party Credits
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DataCreditsScreen extends StatelessWidget {
  const DataCreditsScreen({super.key});

  static void show(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DataCreditsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1526),
        title: const Text(
          'Data Credits',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF00FF88)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white12),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1A2E), Color(0xFF091523)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00FF88).withValues(alpha: 0.25),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('🌍', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Open Data Acknowledgements',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'US Outdoor Navigator is powered by free, open-source '
                            'and publicly available data from government agencies '
                            'and open communities. We are grateful for their work.',
                            style: TextStyle(
                              color: Color(0xFF8899BB),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── NASA ─────────────────────────────────────────────────────
          _sectionHeader('🔥 Fire & Satellite Data'),
          _creditCard(
            context: context,
            emoji: '🚀',
            name: 'NASA FIRMS',
            fullName: 'Fire Information for Resource Management System',
            description:
                'Real-time active wildfire detection data from NASA\'s MODIS and '
                'VIIRS satellite sensors. Updated every 3 hours. Critical for '
                'campfire safety alerts and evacuation warnings.',
            license: 'Public Domain — U.S. Government',
            url: 'https://firms.modaps.eosdis.nasa.gov/',
            color: const Color(0xFFFF4500),
          ),
          _creditCard(
            context: context,
            emoji: '🛰️',
            name: 'NASA Earthdata',
            fullName: 'NASA Open Data Portal',
            description:
                'Satellite-derived terrain and atmospheric data used for '
                'elevation profiles, solar irradiance estimates, and '
                'ground condition modeling.',
            license: 'Public Domain — NASA',
            url: 'https://earthdata.nasa.gov/',
            color: const Color(0xFF0B3D91),
          ),
          const SizedBox(height: 8),

          // ── NOAA ──────────────────────────────────────────────────────
          _sectionHeader('🌩️ Weather & Alerts'),
          _creditCard(
            context: context,
            emoji: '🌦️',
            name: 'NOAA / NWS',
            fullName:
                'National Oceanic and Atmospheric Administration / '
                'National Weather Service',
            description:
                'Real-time weather forecasts, severe weather alerts, and '
                'hourly forecasts via api.weather.gov. Powers the Weather '
                'Sentinel feature — thunder, flood, and high-wind warnings.',
            license: 'Public Domain — U.S. Government',
            url: 'https://www.weather.gov/documentation/services-web-api',
            color: const Color(0xFF0066CC),
          ),
          const SizedBox(height: 8),

          // ── OpenStreetMap ─────────────────────────────────────────────
          _sectionHeader('🗺️ Maps & Points of Interest'),
          _creditCard(
            context: context,
            emoji: '🗺️',
            name: 'OpenStreetMap',
            fullName: 'OpenStreetMap Contributors',
            description:
                'The world\'s largest open geographic database, maintained '
                'by millions of volunteer mappers worldwide. Powers all map '
                'tiles and geographic features in this app.',
            license: 'ODbL — Open Database License',
            url: 'https://www.openstreetmap.org/copyright',
            color: const Color(0xFF7EBC6F),
          ),
          _creditCard(
            context: context,
            emoji: '🔍',
            name: 'Overpass API',
            fullName: 'Overpass API by Roland Olbricht',
            description:
                'OSM data query engine used to find real-time RV fuel '
                'stations, dump stations, potable water points, and '
                'RV repair shops near your location.',
            license: 'Open License — Free to use',
            url: 'https://overpass-api.de/',
            color: const Color(0xFF4CAF50),
          ),
          _creditCard(
            context: context,
            emoji: '🛤️',
            name: 'OSRM',
            fullName: 'Open Source Routing Machine',
            description:
                'High-performance routing engine for RV navigation. '
                'Used by the RV Dimension Guard feature to calculate '
                'routes and identify low-clearance bridges and tunnels.',
            license: 'BSD 2-Clause License',
            url: 'http://project-osrm.org/',
            color: const Color(0xFF00BCD4),
          ),
          const SizedBox(height: 8),

          // ── Flutter & Dart ────────────────────────────────────────────
          _sectionHeader('📱 Mobile Framework'),
          _creditCard(
            context: context,
            emoji: '💙',
            name: 'Flutter & Dart',
            fullName: 'Google Flutter Framework',
            description:
                'Cross-platform mobile UI framework by Google. Enables '
                'a single codebase to run natively on both iOS and '
                'Android with high performance.',
            license: 'BSD 3-Clause License',
            url: 'https://flutter.dev/',
            color: const Color(0xFF027DFD),
          ),
          const SizedBox(height: 8),

          // ── Routing & Backend ─────────────────────────────────────────
          _sectionHeader('⚙️ Backend & Infrastructure'),
          _creditCard(
            context: context,
            emoji: '⚡',
            name: 'FastAPI',
            fullName: 'FastAPI by Sebastián Ramírez',
            description:
                'Modern, high-performance Python web framework used '
                'for all backend API endpoints.',
            license: 'MIT License',
            url: 'https://fastapi.tiangolo.com/',
            color: const Color(0xFF009688),
          ),
          _creditCard(
            context: context,
            emoji: '🗄️',
            name: 'SQLite',
            fullName: 'SQLite Database Engine',
            description:
                'Embedded relational database engine used for community '
                'reports, SOS logs, and rate limiting on the backend.',
            license: 'Public Domain',
            url: 'https://www.sqlite.org/',
            color: const Color(0xFF37474F),
          ),
          const SizedBox(height: 8),

          // ── Subscription & Analytics ──────────────────────────────────
          _sectionHeader('💳 Subscriptions & Analytics'),
          _creditCard(
            context: context,
            emoji: '💰',
            name: 'RevenueCat',
            fullName: 'RevenueCat In-App Purchase SDK',
            description:
                'In-app subscription management for Pro tier. Handles '
                'iOS App Store and Google Play billing securely.',
            license: 'Commercial — Standard License',
            url: 'https://www.revenuecat.com/',
            color: const Color(0xFFE91E63),
          ),
          _creditCard(
            context: context,
            emoji: '🔥',
            name: 'Firebase',
            fullName: 'Google Firebase Platform',
            description:
                'Firebase Crashlytics for crash reporting and Firebase '
                'Analytics for anonymous usage statistics. No personal '
                'data is stored without consent.',
            license: 'Commercial — Google Cloud',
            url: 'https://firebase.google.com/',
            color: const Color(0xFFFF6F00),
          ),
          const SizedBox(height: 16),

          // ── Footer ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1526),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                const Text(
                  '❤️ Thank You',
                  style: TextStyle(
                    color: Color(0xFF00FF88),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We deeply thank every government agency, open-source developer, '
                  'and volunteer mapper whose work makes this safety application possible. '
                  'Without open data, open source, and open maps — '
                  'this app would not exist.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'US Outdoor Navigator is not affiliated with NASA, NOAA, '
                  'or any government agency. Data is used under their respective '
                  'public access policies.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4, left: 4),
    child: Text(
      title,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    ),
  );

  Widget _creditCard({
    required BuildContext context,
    required String emoji,
    required String name,
    required String fullName,
    required String description,
    required String license,
    required String url,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1526),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.open_in_new,
                          color: color.withValues(alpha: 0.7),
                          size: 14,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fullName,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '📄 $license',
                        style: TextStyle(
                          color: color.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
