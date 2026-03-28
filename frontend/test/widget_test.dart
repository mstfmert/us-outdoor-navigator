// US Outdoor Navigator — Smoke Test v1.0.0
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/cache_service.dart';
import 'package:frontend/models/app_state.dart';

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
