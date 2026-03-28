// onboarding_screen.dart — App Store Ready Onboarding
// ✅ 3 Premium Slide | ✅ Smooth Animations | ✅ SharedPreferences skip flag
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'permission_request_screen.dart';

const String _kOnboardingDone = 'onboarding_done_v1';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_kOnboardingDone) ?? false);
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDone, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _ctrl = PageController();
  int _page = 0;

  static const List<_Slide> _slides = [
    _Slide(
      emoji: '🗺️',
      title: 'Unlimited Exploration',
      subtitle: 'US Outdoor Navigator',
      description:
          'Discover 1,500+ campgrounds across all 50 US states and territories. '
          'Dynamic map that loads sites as you explore — no radius limits.',
      features: [
        '🏕️  Campgrounds, BLM & National Forests',
        '⛽  RV-friendly fuel & dump stations',
        '🔥  Real-time NASA wildfire alerts',
        '📶  Cell signal & solar heatmaps',
      ],
      gradient: [Color(0xFF0D1526), Color(0xFF0A2040)],
      accentColor: Color(0xFF00FF88),
    ),
    _Slide(
      emoji: '🆘',
      title: 'SOS & Safety First',
      subtitle: 'Never Get Stranded',
      description:
          'One-tap PANIC button sends your GPS coordinates to emergency '
          'contacts. Dead Man\'s Switch auto-alerts if you miss a check-in.',
      features: [
        '🚨  Panic button with GPS transmission',
        '⏱️  Dead Man\'s Switch (24h check-in)',
        '🌩️  NOAA severe weather alerts',
        '🐻  Community bear/road hazard reports',
      ],
      gradient: [Color(0xFF1A0808), Color(0xFF2A0A0A)],
      accentColor: Color(0xFFFF1744),
    ),
    _Slide(
      emoji: '🚐',
      title: 'RV Command Center',
      subtitle: 'Built for Overlanders',
      description:
          'Enter your RV dimensions once. The app filters campsites, warns '
          'about low bridges, and calculates mud risk before you arrive.',
      features: [
        '📏  RV dimension clearance guard',
        '☀️  Solar panel efficiency estimator',
        '🌧️  Weather impact & mud risk score',
        '📥  Full offline mode — no signal needed',
      ],
      gradient: [Color(0xFF061A2A), Color(0xFF0A1A30)],
      accentColor: Color(0xFF00B4FF),
    ),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await OnboardingScreen.markDone();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PermissionRequestScreen()),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── PageView ──────────────────────────────────────────────────
          PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _slides.length,
            itemBuilder: (_, i) => _SlideView(slide: _slides[i], index: i),
          ),

          // ── Dot Indicators ─────────────────────────────────────────────
          Positioned(
            bottom: 130,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i
                        ? _slides[_page].accentColor
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

          // ── Navigation Buttons ─────────────────────────────────────────
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Skip
                TextButton(
                  onPressed: _finish,
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                ),
                // Next / Get Started
                GestureDetector(
                  onTap: _next,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _slides[_page].accentColor,
                          _slides[_page].accentColor.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _slides[_page].accentColor.withValues(
                            alpha: 0.4,
                          ),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      _page == _slides.length - 1 ? 'Get Started 🚀' : 'Next →',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slide Data Model ─────────────────────────────────────────────────────────
class _Slide {
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final List<String> features;
  final List<Color> gradient;
  final Color accentColor;

  const _Slide({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
    required this.gradient,
    required this.accentColor,
  });
}

// ─── Slide View ───────────────────────────────────────────────────────────────
class _SlideView extends StatelessWidget {
  final _Slide slide;
  final int index;
  const _SlideView({required this.slide, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: slide.gradient,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // ── Big Emoji ────────────────────────────────────────────────
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: slide.accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: slide.accentColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: slide.accentColor.withValues(alpha: 0.25),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        slide.emoji,
                        style: const TextStyle(fontSize: 56),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // ── Subtitle ─────────────────────────────────────────────────
              FadeInLeft(
                delay: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: slide.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: slide.accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    slide.subtitle,
                    style: TextStyle(
                      color: slide.accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Title ─────────────────────────────────────────────────────
              FadeInLeft(
                delay: const Duration(milliseconds: 300),
                child: Text(
                  slide.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Description ───────────────────────────────────────────────
              FadeIn(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  slide.description,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Features ─────────────────────────────────────────────────
              ...slide.features.asMap().entries.map(
                (entry) => FadeInLeft(
                  delay: Duration(milliseconds: 500 + entry.key * 80),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: slide.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
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
      ),
    );
  }
}
