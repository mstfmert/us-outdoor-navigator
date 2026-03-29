// app_config.dart — Dynamic API URL Configuration
// ✅ --dart-define ile override edilebilir
// ✅ Platform bazlı akıllı fallback
// ✅ Railway/Render production URL desteği
//
// Kullanım:
//   Local:       flutter run
//   Production:  flutter build apk --dart-define=API_URL=https://your-app.railway.app
//   Test:        flutter run --dart-define=API_URL=https://your-app.railway.app

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'dart:io' show Platform;

class AppConfig {
  AppConfig._(); // Singleton — instantiate edilemez

  // ── Dart-define ile override ──────────────────────────────────────────
  // flutter build apk --dart-define=API_URL=https://us-outdoor.railway.app
  static const String _dartDefineUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: '',
  );

  // ── Production Cloud URL ──────────────────────────────────────────────
  // Railway.app, Render.com veya kendi sunucun deploy edildikten sonra buraya ekle
  static const String productionUrl =
      'https://us-outdoor-api-production.up.railway.app';
  // ✅ Railway deploy: us-outdoor-api — 28 Mart 2026

  // ── API Base URL (Akıllı Seçim) ───────────────────────────────────────
  static String get apiBaseUrl {
    // 1. --dart-define ile override varsa onu kullan
    if (_dartDefineUrl.isNotEmpty) return _dartDefineUrl;

    // 2. Production build ise cloud URL'i kullan
    if (!kDebugMode) return productionUrl;

    // 3. Debug mode: Web her zaman production'a bağlanır
    //    (localhost:8000 web'de CORS hatası verir ve backend web'de çalışmaz)
    if (kIsWeb) return productionUrl;
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
      // iOS Simulator, Windows, macOS, Linux
      return 'http://localhost:8000';
    } catch (_) {
      return 'http://localhost:8000';
    }
  }

  // ── App Metadata ──────────────────────────────────────────────────────
  static const String appName = 'US Outdoor Navigator';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';
  static const String supportEmail = 'support@usoutdoor.app';

  // Privacy & Terms → Backend API endpoint'lerinden serve edilir
  // Railway deploy sonrası: https://<your-app>.railway.app/privacy
  static String get privacyUrl => '$apiBaseUrl/privacy';
  static String get termsUrl => '$apiBaseUrl/terms';
  static String get deleteAccountUrl => '$apiBaseUrl/delete_account';

  // ── Feature Flags ─────────────────────────────────────────────────────
  static const bool enableFirebase =
      true; // ✅ Firebase aktif — us-outdoor-navigator-app
  static const bool enableCrashlytics = true;
  static const bool enableAnalytics = true;

  // ── RevenueCat ────────────────────────────────────────────────────────
  // RevenueCat dashboard'dan al: https://app.revenuecat.com
  // → Project Settings → API Keys → Public SDK Key
  //
  // Android key: "goog_" ile başlar
  // iOS key:     "appl_" ile başlar
  //
  // Güvenli kullanım (build time inject):
  //   flutter build appbundle \
  //     --dart-define=RC_KEY_ANDROID=goog_xxxx \
  //     --dart-define=RC_KEY_IOS=appl_xxxx
  static const String revenueCatApiKeyAndroid = String.fromEnvironment(
    'RC_KEY_ANDROID',
    defaultValue: 'test_lGzVKmhObemwqQDgnqfKbmiMPbG',
  );
  static const String revenueCatApiKeyIos = String.fromEnvironment(
    'RC_KEY_IOS',
    defaultValue: 'test_lGzVKmhObemwqQDgnqfKbmiMPbG',
  );

  // ── Subscription Plans ────────────────────────────────────────────────
  // RevenueCat + Play Store / App Store'da tam paket adı kullan
  static const String explorerProductId = 'com.mert.usoutdoor.explorer_weekly';
  static const String nomadProductId = 'com.mert.usoutdoor.nomad_yearly';
  static const String explorerPrice = '\$9.99/week';
  static const String nomadPrice = '\$59.99/year';
  static const String nomadMonthlyEquiv = '\$5.00/month';
  static const String nomadSavings = 'Save 50% vs weekly';

  // ── Free Tier States (CA, AZ, UT) ─────────────────────────────────────
  static const Set<String> freeStates = {'CA', 'AZ', 'UT'};
  static const String freeStatesLabel = 'California, Arizona & Utah';

  // ── API Timeouts ──────────────────────────────────────────────────────
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration sosTimeout = Duration(seconds: 8);
  static const Duration routeTimeout = Duration(seconds: 25);

  // ── Harita Defaults ───────────────────────────────────────────────────
  // Joshua Tree, CA — varsayılan başlangıç koordinatı
  static const double defaultLat = 33.8734;
  static const double defaultLon = -115.9010;
  static const double defaultZoom = 9.0;
}
