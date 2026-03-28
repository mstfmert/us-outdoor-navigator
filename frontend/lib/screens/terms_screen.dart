// terms_screen.dart — Terms of Service (App Store Required)
import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static void show(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1526),
        title: const Text(
          'Terms of Service',
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
        child: _TermsContent(),
      ),
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _text('Last Updated: March 28, 2026', isDate: true),
        const SizedBox(height: 12),
        _text(
          'By downloading or using US Outdoor Navigator ("App"), you agree to '
          'these Terms of Service. Please read them carefully.',
          isIntro: true,
        ),
        _heading('1. Acceptance of Terms'),
        _text(
          'By accessing the App, you confirm you are at least 18 years old '
          '(or have parental consent), and you agree to be bound by these terms.',
        ),
        _heading('2. SOS & Emergency Features — IMPORTANT'),
        _warning(
          'The SOS/Panic feature is intended as a SUPPLEMENTAL safety tool. '
          'It is NOT a replacement for official emergency services (911). '
          'Always call 911 in a life-threatening emergency.\n\n'
          'US Outdoor Navigator is NOT liable for any SOS transmission failures '
          'due to lack of cellular/internet connectivity, device failure, or '
          'third-party service outages.',
        ),
        _heading('3. Accuracy of Data'),
        _text(
          'Campground information, wildfire data, and weather alerts are sourced '
          'from Recreation.gov, NASA FIRMS, and NOAA/NWS. While we strive for '
          'accuracy, conditions change rapidly. Always verify campsite '
          'availability and safety conditions with official sources before '
          'visiting. The App is provided "as is" without warranties.',
        ),
        _heading('4. User-Generated Content'),
        _text(
          'Community reports (bear sightings, road closures, etc.) are submitted '
          'by users. We do not verify their accuracy. Do not rely solely on '
          'community reports for safety decisions. By submitting content, you '
          'grant us a non-exclusive license to display it in the App.',
        ),
        _heading('5. Prohibited Uses'),
        _text(
          'You may not:\n'
          '• Submit false emergency reports or fake SOS alerts\n'
          '• Use the App for commercial data harvesting\n'
          '• Attempt to reverse engineer or hack the App\n'
          '• Violate any applicable laws while using the App\n\n'
          'Abuse of the SOS feature may result in permanent account ban and '
          'may be reported to law enforcement.',
        ),
        _heading('6. Subscription & Payments'),
        _text(
          'The App is currently free to use. Future premium features may be '
          'offered as optional in-app purchases, governed by App Store/Google '
          'Play payment terms. All purchases are final unless required by law.',
        ),
        _heading('7. Intellectual Property'),
        _text(
          'The App, its design, and all content (excluding user-generated '
          'content) are owned by US Outdoor Navigator. The campground database '
          'is compiled from public Recreation.gov data (public domain).',
        ),
        _heading('8. Limitation of Liability'),
        _text(
          'To the maximum extent permitted by law, US Outdoor Navigator shall '
          'not be liable for any indirect, incidental, or consequential damages '
          'arising from your use of the App, including injuries, property damage, '
          'or emergency response failures.',
        ),
        _heading('9. Governing Law'),
        _text(
          'These Terms are governed by the laws of the State of California, '
          'United States, without regard to conflict of law provisions.',
        ),
        _heading('10. Changes'),
        _text(
          'We may update these Terms. Material changes will be notified via '
          'in-app alert. Continued use after changes constitutes acceptance.',
        ),
        _heading('11. Contact'),
        _text(
          'US Outdoor Navigator\n'
          'Email: legal@usoutdoor.app\n'
          'Website: https://usoutdoor.app/terms',
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _heading(String text) => Padding(
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

  Widget _text(String text, {bool isDate = false, bool isIntro = false}) =>
      Padding(
        padding: EdgeInsets.only(bottom: isIntro ? 4 : 0),
        child: Text(
          text,
          style: TextStyle(
            color: isDate ? Colors.white38 : Colors.grey[300],
            fontSize: isDate ? 12 : 14,
            height: 1.7,
            fontStyle: isDate ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      );

  Widget _warning(String text) => Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF1A0808),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.5)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('⚠️ ', style: TextStyle(fontSize: 18)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFFF6B6B),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ),
      ],
    ),
  );
}
