// MapService — Mapbox konfigürasyonu ve yardımcı sabitler
// Gerçek harita mantığı native_map_widget_real.dart içindedir.
//
// Token inject: flutter build appbundle --dart-define=MAPBOX_TOKEN=pk.eyJ...
// local.properties: MAPBOX_DOWNLOADS_TOKEN=pk.eyJ... (gitignore'da)

class MapService {
  // ─── Mapbox Erişim Token ──────────────────────────────────────────────────
  // Güvenli kullanım: --dart-define=MAPBOX_TOKEN=pk.eyJ... ile inject et
  // Asla kaynak koduna token yazma!
  static const String accessToken = String.fromEnvironment(
    'MAPBOX_TOKEN',
    defaultValue: 'YOUR_MAPBOX_PUBLIC_TOKEN_HERE',
  );

  // ─── Mapbox Harita Stili ──────────────────────────────────────────────────
  static const String styleUrl = 'mapbox://styles/mapbox/dark-v11';

  // ─── Kamera Zoom Seviyeleri ───────────────────────────────────────────────
  // Zoom 11 → bireysel kamp ikonları görünür (cluster badge değil)
  // Zoom  9 → tüm kamplar tek badge'e kümelenir, kullanıcı göremez
  static const double defaultZoom = 11.0;
  static const double minZoom = 3.0;
  static const double maxZoom = 18.0;
}
