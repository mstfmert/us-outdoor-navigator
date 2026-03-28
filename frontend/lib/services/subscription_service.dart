// subscription_service.dart — RevenueCat IAP Wrapper
// ✅ Explorer Haftalık $9.99 | ✅ Nomad Yıllık $59.99
// ✅ Eyalet kilidi | ✅ ChangeNotifier
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/subscription.dart';
import '../config/app_config.dart';

class SubscriptionService extends ChangeNotifier {
  SubscriptionInfo _info = SubscriptionInfo.free;
  bool _isLoading = false;
  String? _error;
  List<Package> _availablePackages = [];

  SubscriptionInfo get info => _info;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPremium => _info.isPremium;
  List<Package> get availablePackages => _availablePackages;

  // ── RevenueCat Başlatma ─────────────────────────────────────────────────
  Future<void> initialize() async {
    try {
      final apiKey = Platform.isAndroid
          ? AppConfig.revenueCatApiKeyAndroid
          : AppConfig.revenueCatApiKeyIos;

      // Sadece gerçek RC key varsa başlat
      if (apiKey.contains('YOUR_RC_KEY')) {
        debugPrint('⚠️ RevenueCat: API key ayarlanmamış — demo mode');
        _info = SubscriptionInfo.free;
        notifyListeners();
        return;
      }

      await Purchases.configure(PurchasesConfiguration(apiKey));
      await _refreshCustomerInfo();
      await _loadOfferings();

      // Listener: abonelik değişirse güncelle
      Purchases.addCustomerInfoUpdateListener((info) {
        _updateFromCustomerInfo(info);
      });
    } catch (e) {
      debugPrint('⚠️ RevenueCat init hatası: $e');
    }
  }

  // ── Müşteri bilgisi güncelle ────────────────────────────────────────────
  Future<void> _refreshCustomerInfo() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _updateFromCustomerInfo(customerInfo);
    } catch (e) {
      debugPrint('⚠️ getCustomerInfo hatası: $e');
    }
  }

  void _updateFromCustomerInfo(CustomerInfo info) {
    final entitlement = info.entitlements.all[kEntitlementPro];
    final isActive = entitlement?.isActive ?? false;
    final productId = entitlement?.productIdentifier ?? '';

    SubscriptionPlan plan = SubscriptionPlan.free;
    if (isActive) {
      plan = productId.contains('yearly') || productId.contains('nomad')
          ? SubscriptionPlan.nomad
          : SubscriptionPlan.explorer;
    }

    _info = SubscriptionInfo(
      plan: plan,
      status: isActive ? SubscriptionStatus.active : SubscriptionStatus.expired,
      productId: productId,
      expiresAt: entitlement?.expirationDate != null
          ? DateTime.tryParse(entitlement!.expirationDate!)
          : null,
    );
    notifyListeners();
  }

  // ── Offerings yükle ────────────────────────────────────────────────────
  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current != null) {
        _availablePackages = current.availablePackages;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ getOfferings hatası: $e');
    }
  }

  // ── Satın Al ────────────────────────────────────────────────────────────
  Future<bool> purchase(Package package) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await Purchases.purchasePackage(package);
      _updateFromCustomerInfo(result);
      _isLoading = false;
      notifyListeners();
      return _info.isPremium;
    } on PurchasesError catch (e) {
      // PurchasesError.code: PurchasesErrorCode enum değeri (purchases_flutter v8.x)
      _isLoading = false;
      if (e.code != PurchasesErrorCode.purchaseCancelledError) {
        _error = _errorMessage(e.code);
      }
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'Purchase failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // ── Satın Alımları Geri Yükle ─────────────────────────────────────────
  Future<bool> restorePurchases() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final info = await Purchases.restorePurchases();
      _updateFromCustomerInfo(info);
      _isLoading = false;
      notifyListeners();
      return _info.isPremium;
    } catch (e) {
      _isLoading = false;
      _error = 'Restore failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // ── Özellik Erişim Kontrolü ────────────────────────────────────────────
  bool canAccess(ProFeature feature) {
    if (_info.isPremium) return true;
    // Ücretsiz özellikler — Pro gerektirmeyenler yok burada,
    // tüm ProFeature enum değerleri premium gerektirir
    return false;
  }

  bool canAccessState(String stateCode) {
    if (_info.isPremium) return true;
    return kFreeStates.contains(stateCode.toUpperCase());
  }

  // ── Demo Mode (Test için) ──────────────────────────────────────────────
  void enableDemoProMode() {
    _info = const SubscriptionInfo(
      plan: SubscriptionPlan.nomad,
      status: SubscriptionStatus.active,
      productId: 'demo_nomad',
    );
    notifyListeners();
  }

  void disableDemoMode() {
    _info = SubscriptionInfo.free;
    notifyListeners();
  }

  String _errorMessage(PurchasesErrorCode code) => switch (code) {
    PurchasesErrorCode.networkError => 'Network error. Check your connection.',
    PurchasesErrorCode.productAlreadyPurchasedError =>
      'Already purchased. Tap "Restore" to recover.',
    PurchasesErrorCode.purchaseNotAllowedError =>
      'Purchase not allowed on this device.',
    _ => 'Purchase failed. Please try again.',
  };
}
