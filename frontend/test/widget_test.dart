// US Outdoor Navigator — Smoke Test v1.0.0
import 'package:flutter_test/flutter_test.dart';
import 'package:us_outdoor_navigator/main.dart';
import 'package:provider/provider.dart';
import 'package:us_outdoor_navigator/services/api_service.dart';
import 'package:us_outdoor_navigator/services/cache_service.dart';
import 'package:us_outdoor_navigator/models/app_state.dart';

void main() {
  testWidgets('App smoke test — USOutdoorNavigatorApp başlatılabilmeli', (
    WidgetTester tester,
  ) async {
    final cacheService = CacheService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiService>(create: (_) => ApiService()),
          Provider<CacheService>(create: (_) => cacheService),
          ChangeNotifierProvider(create: (_) => AppState()),
        ],
        child: const USOutdoorNavigatorApp(showOnboarding: false),
      ),
    );
    // Hata olmadan ilk frame render edilebilmeli
    expect(tester.takeException(), isNull);
  });
}
