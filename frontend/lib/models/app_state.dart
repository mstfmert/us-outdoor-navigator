import 'package:flutter/foundation.dart';
import 'campground.dart';
import 'fire_point.dart';
import 'location.dart';
import 'poi_point.dart';
import 'camp_filter.dart';
import 'community_report.dart';

class AppState with ChangeNotifier {
  // ── Konum & Veri ───────────────────────────────────────────────────────────
  Location? _currentLocation;
  List<Campground> _campgrounds = [];
  List<FirePoint> _firePoints = [];
  List<PoiPoint> _poiPoints = [];
  List<CommunityReport> _communityReports = [];

  // ── Filtre ─────────────────────────────────────────────────────────────────
  CampFilter _campFilter = const CampFilter();

  // ── Durum ──────────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _error;
  String _safetyStatus = 'UNKNOWN';
  String _safetyMessage = '';
  bool _isEvacuationWarning = false;
  bool _isOfflineMode = false;

  // ── Seçimler ───────────────────────────────────────────────────────────────
  Campground? _selectedCampground;
  PoiPoint? _selectedPoi;

  // ── Harita Layer Toggle'ları ────────────────────────────────────────────────
  bool _showCampgrounds = true;
  bool _showFires = true;
  bool _showFuel = false;
  bool _showEvCharge = false;
  bool _showMarkets = false;
  bool _showRvRepair = false;
  bool _showRoadWork = false;
  bool _showCommunityReports = true;
  bool _showSolarHeatmap = false;
  bool _showCellHeatmap = false;
  bool _showBlmOverlay = false;
  bool _showTerrain3d = false;

  // ── Getters ────────────────────────────────────────────────────────────────
  Location? get currentLocation => _currentLocation;
  List<Campground> get campgrounds => _campgrounds;
  List<CommunityReport> get communityReports => _communityReports;

  /// Filtrelenmiş kamp listesi — harita ve panel bu getter'ı kullanır
  List<Campground> get filteredCampgrounds => _campFilter.apply(_campgrounds);

  List<FirePoint> get firePoints => _firePoints;
  List<PoiPoint> get poiPoints => _poiPoints;
  CampFilter get campFilter => _campFilter;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get safetyStatus => _safetyStatus;
  String get safetyMessage => _safetyMessage;
  Campground? get selectedCampground => _selectedCampground;
  PoiPoint? get selectedPoi => _selectedPoi;
  bool get isEvacuationWarning => _isEvacuationWarning;
  bool get isOfflineMode => _isOfflineMode;

  // Layer toggles
  bool get showCampgrounds => _showCampgrounds;
  bool get showFires => _showFires;
  bool get showFuel => _showFuel;
  bool get showEvCharge => _showEvCharge;
  bool get showMarkets => _showMarkets;
  bool get showRvRepair => _showRvRepair;
  bool get showRoadWork => _showRoadWork;
  bool get showCommunityReports => _showCommunityReports;
  bool get showSolarHeatmap => _showSolarHeatmap;
  bool get showCellHeatmap => _showCellHeatmap;
  bool get showBlmOverlay => _showBlmOverlay;
  bool get showTerrain3d => _showTerrain3d;

  // ── Konum & Veri Setters ────────────────────────────────────────────────────
  void setCurrentLocation(Location location) {
    _currentLocation = location;
    notifyListeners();
  }

  void setCampgrounds(List<Campground> campgrounds) {
    _campgrounds = campgrounds;
    notifyListeners();
  }

  void setFirePoints(List<FirePoint> firePoints) {
    _firePoints = firePoints;
    notifyListeners();
  }

  void setPoiPoints(List<PoiPoint> poiPoints) {
    _poiPoints = poiPoints;
    notifyListeners();
  }

  void addPoiPoints(List<PoiPoint> points) {
    // Duplicate önleme — id bazlı
    final existing = {for (final p in _poiPoints) p.id};
    final newPoints = points.where((p) => !existing.contains(p.id)).toList();
    if (newPoints.isEmpty) return;
    _poiPoints = [..._poiPoints, ...newPoints];
    notifyListeners();
  }

  // ── Filtre ────────────────────────────────────────────────────────────────
  void setCampFilter(CampFilter filter) {
    _campFilter = filter;
    notifyListeners();
  }

  // ── Topluluk Raporları ────────────────────────────────────────────────────
  void addCommunityReport(CommunityReport report) {
    _communityReports = [report, ..._communityReports];
    notifyListeners();
  }

  void setCommunityReports(List<CommunityReport> reports) {
    _communityReports = reports;
    notifyListeners();
  }

  // ── Durum Setters ──────────────────────────────────────────────────────────
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setSafetyStatus(String status, String message) {
    _safetyStatus = status;
    _safetyMessage = message;
    _isEvacuationWarning = status == 'DANGER';
    notifyListeners();
  }

  // ── Seçim ─────────────────────────────────────────────────────────────────
  void selectCampground(Campground? campground) {
    _selectedCampground = campground;
    _selectedPoi = null;
    notifyListeners();
  }

  void selectPoi(PoiPoint? poi) {
    _selectedPoi = poi;
    _selectedCampground = null;
    notifyListeners();
  }

  void clearSelection() {
    _selectedCampground = null;
    _selectedPoi = null;
    notifyListeners();
  }

  // ── Offline ────────────────────────────────────────────────────────────────
  /// Backend health check sonucuna göre offline/online modunu ayarla.
  void setOfflineMode(bool offline) {
    if (_isOfflineMode != offline) {
      _isOfflineMode = offline;
      notifyListeners();
    }
  }

  void toggleOfflineMode() {
    _isOfflineMode = !_isOfflineMode;
    notifyListeners();
  }

  // ── Layer Toggles ─────────────────────────────────────────────────────────
  void toggleLayer(String layer) {
    switch (layer) {
      case 'campgrounds':
        _showCampgrounds = !_showCampgrounds;
      case 'fires':
        _showFires = !_showFires;
      case 'fuel':
        _showFuel = !_showFuel;
      case 'ev':
        _showEvCharge = !_showEvCharge;
      case 'markets':
        _showMarkets = !_showMarkets;
      case 'repair':
        _showRvRepair = !_showRvRepair;
      case 'roads':
        _showRoadWork = !_showRoadWork;
      case 'reports':
        _showCommunityReports = !_showCommunityReports;
      case 'solar_heat':
        _showSolarHeatmap = !_showSolarHeatmap;
      case 'cell_heat':
        _showCellHeatmap = !_showCellHeatmap;
      case 'blm':
        _showBlmOverlay = !_showBlmOverlay;
      case 'terrain3d':
        _showTerrain3d = !_showTerrain3d;
    }
    notifyListeners();
  }

  // ── Reset ─────────────────────────────────────────────────────────────────
  void reset() {
    _currentLocation = null;
    _campgrounds = [];
    _firePoints = [];
    _poiPoints = [];
    _communityReports = [];
    _campFilter = const CampFilter();
    _isLoading = false;
    _error = null;
    _safetyStatus = 'UNKNOWN';
    _safetyMessage = '';
    _selectedCampground = null;
    _selectedPoi = null;
    _isEvacuationWarning = false;
    _isOfflineMode = false;
    notifyListeners();
  }
}
