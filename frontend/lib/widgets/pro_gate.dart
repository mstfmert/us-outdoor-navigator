// pro_gate.dart — Feature Gate Widget
// Pro özellik kilidi: kullanıcı Premium değilse Paywall'a yönlendirir.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subscription_service.dart';
import '../models/subscription.dart';
import '../screens/paywall_screen.dart';

/// Bir widget'ı Pro özellik kilidiyle sarar.
/// isPremium=false ise widget üzerine kilit overlay koyar.
class ProGate extends StatelessWidget {
  final Widget child;
  final ProFeature feature;
  final String featureName;
  final bool showLockIcon;
  final Widget? lockedFallback;

  const ProGate({
    super.key,
    required this.child,
    required this.feature,
    required this.featureName,
    this.showLockIcon = true,
    this.lockedFallback,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (ctx, svc, _) {
        if (svc.canAccess(feature)) return child;
        return lockedFallback ?? _buildLockedOverlay(ctx, svc);
      },
    );
  }

  Widget _buildLockedOverlay(BuildContext context, SubscriptionService svc) {
    return GestureDetector(
      onTap: () => _openPaywall(context),
      child: Stack(
        children: [
          // Orijinal widget (blur effect ile)
          AbsorbPointer(child: Opacity(opacity: 0.3, child: child)),
          // Lock overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF070D1A).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showLockIcon) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00FF88).withValues(alpha: 0.15),
                        border: Border.all(
                          color: const Color(0xFF00FF88).withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF00FF88),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      featureName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pro Feature — Tap to Unlock',
                      style: TextStyle(
                        color: Color(0xFF00FF88),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPaywall(BuildContext context) async {
    await PaywallScreen.show(context, featureName: featureName);
  }
}

/// Daha basit: Sadece bir butonu Pro ile kilitler
class ProButton extends StatelessWidget {
  final Widget child;
  final ProFeature feature;
  final String featureName;
  final VoidCallback? onProAction;

  const ProButton({
    super.key,
    required this.child,
    required this.feature,
    required this.featureName,
    this.onProAction,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (ctx, svc, _) {
        if (svc.canAccess(feature)) {
          return GestureDetector(onTap: onProAction, child: child);
        }
        return GestureDetector(
          onTap: () => PaywallScreen.show(ctx, featureName: featureName),
          child: Stack(
            children: [
              child,
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00FF88),
                  ),
                  child: const Icon(Icons.lock, color: Colors.black, size: 10),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Eyalet kilidi kontrolü
class StateGate extends StatelessWidget {
  final String stateCode;
  final Widget child;

  const StateGate({super.key, required this.stateCode, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionService>(
      builder: (ctx, svc, _) {
        if (svc.canAccessState(stateCode)) return child;
        return ProGate(
          feature: ProFeature.statesAboveFree,
          featureName: '$stateCode — Pro Required',
          child: child,
        );
      },
    );
  }
}
