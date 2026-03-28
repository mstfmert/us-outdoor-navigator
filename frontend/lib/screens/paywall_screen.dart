// paywall_screen.dart — US Outdoor Navigator Pro Paywall
// ✅ Koyu lacivert + fosforlu yeşil | ✅ Explorer + Nomad planları
// ✅ RevenueCat entegre | ✅ Apple standards compliant
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../services/subscription_service.dart';
import '../config/app_config.dart';

class PaywallScreen extends StatefulWidget {
  final String? lockedFeatureName;
  final bool canDismiss;

  const PaywallScreen({
    super.key,
    this.lockedFeatureName,
    this.canDismiss = true,
  });

  static Future<bool> show(
    BuildContext context, {
    String? featureName,
    bool canDismiss = true,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PaywallScreen(
          lockedFeatureName: featureName,
          canDismiss: canDismiss,
        ),
      ),
    );
    return result ?? false;
  }

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedPlan = 1; // 0=Explorer, 1=Nomad (default: Nomad)

  static const _plans = [
    _PlanCard(
      id: 0,
      name: 'Explorer',
      emoji: '⚡',
      price: '\$9.99',
      period: 'per week',
      monthlyEquiv: '\$43/month',
      badge: '',
      accentColor: Color(0xFF00B4FF),
    ),
    _PlanCard(
      id: 1,
      name: 'Nomad Pro',
      emoji: '🚀',
      price: '\$59.99',
      period: 'per year',
      monthlyEquiv: '\$5.00/month',
      badge: 'BEST VALUE',
      accentColor: Color(0xFF00FF88),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070D1A),
      body: Consumer<SubscriptionService>(
        builder: (ctx, svc, _) {
          if (svc.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF88)),
            );
          }
          return _buildBody(svc);
        },
      ),
    );
  }

  Widget _buildBody(SubscriptionService svc) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildFeatureLock()),
          SliverToBoxAdapter(child: _buildProBenefits()),
          SliverToBoxAdapter(child: _buildPlanSelector(svc)),
          SliverToBoxAdapter(child: _buildCTA(svc)),
          SliverToBoxAdapter(child: _buildFooter(svc)),
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          if (widget.canDismiss)
            GestureDetector(
              onTap: () => Navigator.pop(context, false),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.close, color: Colors.white54, size: 20),
              ),
            ),
          const Spacer(),
          // Crown badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00FF88), Color(0xFF00B4FF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('👑', style: TextStyle(fontSize: 14)),
                SizedBox(width: 6),
                Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureLock() {
    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          children: [
            // Hero Icon
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                border: Border.all(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Text('🔐', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 20),
            if (widget.lockedFeatureName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '🔒  ${widget.lockedFeatureName}',
                  style: const TextStyle(
                    color: Color(0xFF00FF88),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Text(
              'Unlock the\nFull Wilderness',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Access all 50 US states, offline maps,\nand premium RV navigation tools.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProBenefits() {
    // ⚠️ SOS ve Wildfire (NASA) ÜCRETSİZ — burada YOK (Apple/Google policy)
    // Yalnızca gerçekten Pro gerektiren özellikler listelenir.
    const benefits = [
      ('🗺️', 'All 50 States', 'Campgrounds in all 50 US states + AK & HI'),
      ('🚐', 'RV Dimension Guard', 'Bridge & tunnel clearance on every route'),
      ('🌡️', 'Ground Risk Score', 'Mud & terrain passability after rainfall'),
      ('📐', 'Digital Level', 'Precision campsite leveling with gyroscope'),
      ('🛰️', 'Starlink AR View', 'AR satellite dish pointer & signal quality'),
      ('⛽', 'Fuel Saver', 'Smart Stop RV-friendly fuel optimizer'),
      ('🏔️', 'BLM Boundaries', 'Federal land & public land overlay on map'),
      ('📥', 'Offline Maps', 'Full offline mode — no cell signal needed'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EVERYTHING IN PRO',
            style: TextStyle(
              color: Color(0xFF00FF88),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),
          ...benefits.asMap().entries.map(
            (entry) => FadeInLeft(
              delay: Duration(milliseconds: 50 * entry.key),
              duration: const Duration(milliseconds: 400),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(entry.value.$1, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value.$2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            entry.value.$3,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF00FF88),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelector(SubscriptionService svc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CHOOSE YOUR PLAN',
            style: TextStyle(
              color: Color(0xFF00FF88),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),
          ..._plans.map((plan) => _buildPlanTile(plan)),
        ],
      ),
    );
  }

  Widget _buildPlanTile(_PlanCard plan) {
    final isSelected = _selectedPlan == plan.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? plan.accentColor.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.04),
          border: Border.all(
            color: isSelected
                ? plan.accentColor
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(plan.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.name,
                        style: TextStyle(
                          color: isSelected ? plan.accentColor : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (plan.badge.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: plan.accentColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            plan.badge,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    plan.monthlyEquiv,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  plan.price,
                  style: TextStyle(
                    color: isSelected ? plan.accentColor : Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  plan.period,
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                ),
              ],
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? plan.accentColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? plan.accentColor : Colors.grey.shade600,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.black, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTA(SubscriptionService svc) {
    final plan = _plans[_selectedPlan];
    final accentColor = plan.accentColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          if (svc.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                svc.error!,
                style: const TextStyle(color: Color(0xFFFF1744), fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          // Main CTA
          GestureDetector(
            onTap: () => _handlePurchase(svc),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: svc.isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : Text(
                      'Start ${plan.name} — ${plan.price}/${plan.period.split(' ').last}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Trial note
          Text(
            '3-day free trial • Cancel anytime',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(SubscriptionService svc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _footerLink('Restore Purchases', () => _handleRestore(svc)),
              _footerLink('Privacy Policy', () {}),
              _footerLink('Terms of Use', () {}),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Subscriptions auto-renew. Cancel anytime in App Store / Play Store settings.\nPayment charged to your account upon purchase confirmation.',
            style: TextStyle(color: Colors.grey[700], fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white38,
        ),
      ),
    );
  }

  Future<void> _handlePurchase(SubscriptionService svc) async {
    // RevenueCat key yoksa demo mode
    if (AppConfig.revenueCatApiKeyAndroid.contains('YOUR_RC_KEY')) {
      svc.enableDemoProMode();
      if (mounted) Navigator.pop(context, true);
      return;
    }

    final packages = svc.availablePackages;
    if (packages.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading products... Please wait.')),
        );
      }
      return;
    }

    final targetId = _selectedPlan == 0
        ? AppConfig.explorerProductId
        : AppConfig.nomadProductId;

    final pkg = packages.firstWhere(
      (p) => p.storeProduct.identifier == targetId,
      orElse: () => packages.first,
    );

    final success = await svc.purchase(pkg);
    if (success && mounted) Navigator.pop(context, true);
  }

  Future<void> _handleRestore(SubscriptionService svc) async {
    final success = await svc.restorePurchases();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '✅ Purchases restored successfully!'
              : '❌ No active subscription found.',
        ),
        backgroundColor: success
            ? const Color(0xFF00FF88)
            : const Color(0xFFFF1744),
      ),
    );
    if (success) Navigator.pop(context, true);
  }
}

class _PlanCard {
  final int id;
  final String name;
  final String emoji;
  final String price;
  final String period;
  final String monthlyEquiv;
  final String badge;
  final Color accentColor;

  const _PlanCard({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
    required this.period,
    required this.monthlyEquiv,
    required this.badge,
    required this.accentColor,
  });
}
