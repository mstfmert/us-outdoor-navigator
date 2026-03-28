// subscription.dart — US Outdoor Navigator Subscription Model
// RevenueCat entitlement ve plan yönetimi

enum SubscriptionPlan {
  free,
  explorer, // Haftalık $9.99
  nomad, // Yıllık $59.99
}

enum SubscriptionStatus { active, expired, trial, unknown }

class SubscriptionInfo {
  final SubscriptionPlan plan;
  final SubscriptionStatus status;
  final DateTime? expiresAt;
  final bool isInTrial;
  final String productId;

  const SubscriptionInfo({
    required this.plan,
    required this.status,
    this.expiresAt,
    this.isInTrial = false,
    this.productId = '',
  });

  bool get isPremium =>
      (plan == SubscriptionPlan.explorer || plan == SubscriptionPlan.nomad) &&
      status == SubscriptionStatus.active;

  bool get isActive => status == SubscriptionStatus.active || isInTrial;

  String get planLabel => switch (plan) {
    SubscriptionPlan.explorer => 'Explorer',
    SubscriptionPlan.nomad => 'Nomad Pro',
    SubscriptionPlan.free => 'Free',
  };

  String get planEmoji => switch (plan) {
    SubscriptionPlan.explorer => '⚡',
    SubscriptionPlan.nomad => '🚀',
    SubscriptionPlan.free => '🆓',
  };

  static const SubscriptionInfo free = SubscriptionInfo(
    plan: SubscriptionPlan.free,
    status: SubscriptionStatus.active,
    productId: '',
  );

  SubscriptionInfo copyWith({
    SubscriptionPlan? plan,
    SubscriptionStatus? status,
    DateTime? expiresAt,
    bool? isInTrial,
    String? productId,
  }) {
    return SubscriptionInfo(
      plan: plan ?? this.plan,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      isInTrial: isInTrial ?? this.isInTrial,
      productId: productId ?? this.productId,
    );
  }
}

/// Özellik kilitleri — SADECE gerçekten Pro gerektiren özellikler
/// ⚠️  SOS, Wildfire (NASA), WeatherSentinel ÜCRETSIZ — burada YOK
/// Apple/Google policy: güvenlik özellikleri hiçbir zaman paywallda olamaz
enum ProFeature {
  statesAboveFree, // 48 eyalet (CA/AZ/UT ücretsiz)
  offlineMapDownload, // Offline harita indirme
  blmBoundaries, // BLM sınır çizgileri
  digitalLeveling, // Karavancı terazisi (sensör)
  starlinkArView, // Starlink AR (kamera)
  fuelSaverEngine, // Smart Stop yakıt tasarrufu
}

/// ÜCRETSİZ güvenlik özellikleri — ProGate bu özelliklere asla kapatamaz
/// Apple/Google store policy gereği güvenlik özellikleri paywall arkasında olamaz
const Set<String> kFreeFeatures = {
  'sos',
  'wildfire',
  'weather_alerts',
  'night_weather',
  'community_reports',
};

/// Ücretsiz kullanıcılar için erişilebilir eyaletler
const Set<String> kFreeStates = {'CA', 'AZ', 'UT'};

/// RevenueCat Entitlement ID
const String kEntitlementPro = 'pro_access';

/// RevenueCat Product IDs
const String kProductExplorer = 'us_outdoor_explorer_weekly';
const String kProductNomad = 'us_outdoor_nomad_yearly';
