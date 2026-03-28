// privacy_policy_screen.dart — GDPR/CCPA/Apple Privacy Compliant
// Required for App Store & Play Store submission
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static void show(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1526),
        title: const Text(
          'Privacy Policy',
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
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _PolicyContent(),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Last Updated: March 28, 2026', isDate: true),
        _section(
          'US Outdoor Navigator ("the App") is committed to protecting your '
          'privacy. This Privacy Policy explains how we collect, use, and '
          'safeguard your information when you use our application.',
          isIntro: true,
        ),
        _heading('1. Information We Collect'),
        _bullet(
          'Location Data',
          'We access your device\'s GPS location to provide campground '
              'proximity results and the SOS emergency feature. Location data is '
              'processed locally on your device and is NOT stored on our servers '
              'unless you explicitly trigger an SOS event.',
        ),
        _bullet(
          'SOS Data',
          'When you activate the SOS Panic Button, your GPS coordinates, '
              'timestamp, and optional message are transmitted to emergency '
              'contacts you designate. This data is stored for 30 days to ensure '
              'emergency resolution, then permanently deleted.',
        ),
        _bullet(
          'Community Reports',
          'Bear sightings, road closures, and other reports you submit include '
              'your anonymous device ID and location. No personally identifiable '
              'information is attached.',
        ),
        _bullet(
          'Usage Analytics',
          'We use Firebase Analytics to understand app usage patterns (screens '
              'visited, features used). This data is anonymized and aggregated. '
              'No individual user behavior is tracked.',
        ),
        _bullet(
          'Crash Reports',
          'Firebase Crashlytics collects crash logs to help us fix bugs. '
              'These logs do not contain personal information.',
        ),
        _heading('2. How We Use Your Information'),
        _text(
          '• Provide campground search results based on your location\n'
          '• Transmit GPS data during SOS emergencies to your chosen contacts\n'
          '• Display relevant wildfire and weather alerts near you\n'
          '• Improve app performance and fix technical issues\n'
          '• Generate anonymized usage statistics',
        ),
        _heading('3. Data Sharing'),
        _text(
          'We do NOT sell your personal data. We share data only in the '
          'following limited circumstances:\n\n'
          '• Emergency services: SOS coordinates shared with your designated '
          'emergency contact and optionally with 911/SAR services\n'
          '• Service providers: Firebase (Google) for analytics/crash reporting '
          '— governed by Google\'s Privacy Policy\n'
          '• Legal requirements: When required by law or court order',
        ),
        _heading('4. Data Retention'),
        _text(
          '• Location data: Processed in real-time, not stored\n'
          '• SOS records: 30 days after resolution\n'
          '• Community reports: 90 days\n'
          '• Analytics data: 14 months (Firebase default)\n'
          '• Account data: Until you request deletion',
        ),
        _heading('5. Your Rights (CCPA / GDPR)'),
        _text(
          'You have the right to:\n'
          '• Access data we hold about you\n'
          '• Request deletion of your data\n'
          '• Opt out of analytics collection\n'
          '• Withdraw location permissions at any time via device Settings\n\n'
          'To exercise these rights, use the "Delete My Account & Data" '
          'option in Profile → Settings, or contact: privacy@usoutdoor.app',
        ),
        _heading('6. Children\'s Privacy'),
        _text(
          'US Outdoor Navigator is not directed to children under 13. We do '
          'not knowingly collect data from children. If you believe a child '
          'has provided us data, contact us immediately.',
        ),
        _heading('7. Security'),
        _text(
          'All data in transit is encrypted using TLS 1.3. SOS transmissions '
          'use end-to-end encryption. We implement industry-standard security '
          'measures to protect your information.',
        ),
        _heading('8. Changes to This Policy'),
        _text(
          'We may update this policy. Significant changes will be communicated '
          'via an in-app notification. Continued use of the app after changes '
          'constitutes acceptance.',
        ),
        _heading('9. Contact'),
        _text(
          'US Outdoor Navigator\n'
          'Email: privacy@usoutdoor.app\n'
          'Website: https://usoutdoor.app/privacy\n'
          'For data deletion requests: https://usoutdoor.app/delete-account',
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _heading(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF00FF88),
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _text(String text) {
    return Text(
      text,
      style: TextStyle(color: Colors.grey[300], fontSize: 14, height: 1.7),
    );
  }

  Widget _section(String text, {bool isDate = false, bool isIntro = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isIntro ? 8 : 16),
      child: Text(
        text,
        style: TextStyle(
          color: isDate ? Colors.white38 : Colors.grey[300],
          fontSize: isDate ? 12 : 14,
          height: 1.6,
          fontStyle: isDate ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }

  Widget _bullet(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: Color(0xFF00FF88), fontSize: 14),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: desc,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
