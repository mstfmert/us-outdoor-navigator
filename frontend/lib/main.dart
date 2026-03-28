// main.dart — US Outdoor Navigator v1.0.0
// ✅ Onboarding routing | ✅ Firebase init | ✅ Dark theme
// ✅ RevenueCat SubscriptionService | ✅ Feature gates
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/map_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/api_service.dart';
import 'services/cache_service.dart';
import 'services/subscription_service.dart';
import 'models/app_state.dart';

// Firebase — google-services.json / GoogleService-Info.plist gerektirir
// Bkz. FIREBASE_SETUP.md
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── System UI Overlay (statusbar dark tema) ────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0E17),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // ── Yalnızca portre modu ───────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ── Firebase Init (google-services.json / GoogleService-Info.plist) ───
  // try-catch: dosya yoksa uygulama yine de çalışır — crash yok
  try {
    await Firebase.initializeApp();
    // Crashlytics: Flutter hatalarını otomatik yakala
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // Analytics: uygulama açılışını kaydet
    await FirebaseAnalytics.instance.logAppOpen();
    debugPrint('✅ Firebase Crashlytics + Analytics aktif');
  } catch (e) {
    // google-services.json henüz eklenmemişse sessizce devam et
    debugPrint('⚠️ Firebase başlatılamadı (google-services.json eksik): $e');
  }

  // ── CacheService başlat ────────────────────────────────────────────────
  final cacheService = CacheService();
  await cacheService.init();

  // ── RevenueCat SubscriptionService başlat ─────────────────────────────
  final subscriptionService = SubscriptionService();
  await subscriptionService.initialize();

  // ── Onboarding gösterilmeli mi? ────────────────────────────────────────
  final showOnboarding = await OnboardingScreen.shouldShow();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        Provider<CacheService>(create: (_) => cacheService),
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider<SubscriptionService>(
          create: (_) => subscriptionService,
        ),
      ],
      child: USOutdoorNavigatorApp(showOnboarding: showOnboarding),
    ),
  );
}

class USOutdoorNavigatorApp extends StatelessWidget {
  final bool showOnboarding;
  const USOutdoorNavigatorApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'US Outdoor Navigator',
      debugShowCheckedModeBanner: false,

      // ── Tam Neon-Dark Tema ────────────────────────────────────────────
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00FF88),
          brightness: Brightness.dark,
          primary: const Color(0xFF00FF88),
          surface: const Color(0xFF0D1526),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0E17),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1526),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF0D1526),
          modalBackgroundColor: Color(0xFF0D1526),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF0D1526),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1E3A5F),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00FF88),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      // ── Home: Onboarding veya harita ────────────────────────────────────
      home: showOnboarding ? const OnboardingScreen() : const MapScreen(),
    );
  }
}
