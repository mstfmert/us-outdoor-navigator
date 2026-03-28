// profile_screen.dart — User Profile & Account Management
// ✅ Apple Required: Account Deletion | ✅ Privacy/Terms links | ✅ App info
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';
import 'data_credits_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  static void show(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _appVersion = '1.0.0';
  String _buildNumber = '1';
  bool _analyticsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await PackageInfo.fromPlatform();
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _appVersion = info.version;
        _buildNumber = info.buildNumber;
        _analyticsEnabled = prefs.getBool('analytics_enabled') ?? true;
      });
    }
  }

  Future<void> _toggleAnalytics(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analytics_enabled', val);
    setState(() => _analyticsEnabled = val);
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1526),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFF1744), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Color(0xFFFF1744), size: 24),
            SizedBox(width: 10),
            Text(
              'Delete Account & Data',
              style: TextStyle(color: Colors.white, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete:',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...[
              '• All your community reports',
              '• SOS history and contacts',
              '• App settings and preferences',
              '• Cached offline data',
            ].map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  t,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A0808),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '⚠️ This action cannot be undone.',
                style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF1744),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete Everything',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    final apiService = context.read<ApiService>();
    try {
      // Gerçek cihaz userId'sini oku (map_screen ile aynı format)
      final prefs = await SharedPreferences.getInstance();
      final userId =
          prefs.getString('device_user_id') ?? 'user_device_anonymous';
      // Backend'e silme isteği gönder
      await apiService.deleteAccount(userId: userId);

      // Yerel verileri temizle (aynı prefs instance'ı kullan)
      await prefs.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Account and all data deleted successfully.'),
          backgroundColor: Color(0xFF00FF88),
          duration: Duration(seconds: 3),
        ),
      );

      // Onboarding'e yönlendir — clear sonrası false flag yaz
      await prefs.setBool('onboarding_done_v1', false);
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1526),
        title: const Text(
          'Profile & Settings',
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
          // ── App Header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D1526), Color(0xFF0A2040)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00FF88).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Center(
                    child: Text('🏕️', style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'US Outdoor Navigator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'v$_appVersion (build $_buildNumber)',
                        style: const TextStyle(
                          color: Color(0xFF00FF88),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Survival & Comfort Edition',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Privacy & Legal ────────────────────────────────────────────
          _sectionHeader('Privacy & Legal'),
          _tile(
            icon: Icons.privacy_tip_outlined,
            iconColor: const Color(0xFF00FF88),
            title: 'Privacy Policy',
            subtitle: 'How we use your data',
            onTap: () => PrivacyPolicyScreen.show(context),
          ),
          _tile(
            icon: Icons.gavel_outlined,
            iconColor: const Color(0xFF00B4FF),
            title: 'Terms of Service',
            subtitle: 'Usage rules & liability',
            onTap: () => TermsScreen.show(context),
          ),
          _tile(
            icon: Icons.open_in_new,
            iconColor: Colors.white38,
            title: 'Full Privacy Policy (Web)',
            subtitle: 'usoutdoor.app/privacy',
            onTap: () => _launchUrl('https://usoutdoor.app/privacy'),
          ),
          _tile(
            icon: Icons.dataset_outlined,
            iconColor: const Color(0xFF00E5FF),
            title: 'Data Credits',
            subtitle: 'NASA · NOAA · OpenStreetMap · OSM',
            onTap: () => DataCreditsScreen.show(context),
          ),

          const SizedBox(height: 8),

          // ── App Settings ───────────────────────────────────────────────
          _sectionHeader('App Settings'),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1526),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: SwitchListTile(
              value: _analyticsEnabled,
              onChanged: _toggleAnalytics,
              title: const Text(
                'Usage Analytics',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              subtitle: Text(
                'Help improve the app (anonymized)',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              secondary: const Icon(
                Icons.analytics_outlined,
                color: Color(0xFFFFD600),
              ),
              activeColor: const Color(0xFF00FF88),
              inactiveThumbColor: Colors.white38,
            ),
          ),

          const SizedBox(height: 8),

          // ── Support ────────────────────────────────────────────────────
          _sectionHeader('Support'),
          _tile(
            icon: Icons.email_outlined,
            iconColor: const Color(0xFFFF6B00),
            title: 'Contact Support',
            subtitle: 'support@usoutdoor.app',
            onTap: () => _launchUrl('mailto:support@usoutdoor.app'),
          ),
          _tile(
            icon: Icons.bug_report_outlined,
            iconColor: Colors.purple,
            title: 'Report a Bug',
            subtitle: 'Help us fix issues',
            onTap: () => _launchUrl(
              'mailto:bugs@usoutdoor.app?subject=Bug Report v$_appVersion',
            ),
          ),

          const SizedBox(height: 16),

          // ── DANGER ZONE ────────────────────────────────────────────────
          _sectionHeader('Danger Zone', color: const Color(0xFFFF1744)),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D0808),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF1744).withValues(alpha: 0.3),
              ),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.delete_forever,
                color: Color(0xFFFF1744),
              ),
              title: const Text(
                'Delete My Account & Data',
                style: TextStyle(
                  color: Color(0xFFFF1744),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                'Permanently removes all your data — Apple/Google required',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Color(0xFFFF1744),
              ),
              onTap: _showDeleteAccountDialog,
            ),
          ),
          const SizedBox(height: 32),

          // ── Footer ────────────────────────────────────────────────────
          Center(
            child: Text(
              'US Outdoor Navigator v$_appVersion\n'
              '© 2026 · Made with ❤️ for the outdoors community',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], fontSize: 11),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, {Color? color}) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4, left: 4),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
        color: color ?? Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    ),
  );

  Widget _tile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF0D1526),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white10),
    ),
    child: ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.white24,
        size: 18,
      ),
      onTap: onTap,
    ),
  );
}
