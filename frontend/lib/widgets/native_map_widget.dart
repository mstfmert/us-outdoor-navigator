// Conditional export: web'de stub, native'de gerçek Mapbox implementasyonu
export 'native_map_widget_stub.dart'
    if (dart.library.io) 'native_map_widget_real.dart';
