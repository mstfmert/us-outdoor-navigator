import 'campground.dart';

/// Kamp alanı filtreleme kriterleri
class CampFilter {
  final double minRating; // 0–5 yıldız (0 = tümü)
  final bool requireElectric; // Elektrik bağlantısı zorunlu mu?
  final bool requireWater; // Su erişimi zorunlu mu?
  final double minRvLength; // Minimum RV uzunluk limiti (feet)
  final double maxPricePerNight; // Maksimum gece ücreti ($)

  const CampFilter({
    this.minRating = 0.0,
    this.requireElectric = false,
    this.requireWater = false,
    this.minRvLength = 0.0,
    this.maxPricePerNight = 500.0,
  });

  bool get isActive =>
      minRating > 0 ||
      requireElectric ||
      requireWater ||
      minRvLength > 0 ||
      maxPricePerNight < 500;

  /// Kamp listesini bu filtreye göre süz
  List<Campground> apply(List<Campground> camps) {
    return camps.where((c) {
      if (requireWater && !c.hasWater) return false;
      if (requireElectric &&
          !c.amenities.any(
            (a) =>
                a.toLowerCase().contains('electric') ||
                a.toLowerCase().contains('hookup'),
          ))
        return false;
      if (c.maxRvLength < minRvLength) return false;
      if (c.pricePerNight > maxPricePerNight) return false;
      return true;
    }).toList();
  }

  CampFilter copyWith({
    double? minRating,
    bool? requireElectric,
    bool? requireWater,
    double? minRvLength,
    double? maxPricePerNight,
  }) {
    return CampFilter(
      minRating: minRating ?? this.minRating,
      requireElectric: requireElectric ?? this.requireElectric,
      requireWater: requireWater ?? this.requireWater,
      minRvLength: minRvLength ?? this.minRvLength,
      maxPricePerNight: maxPricePerNight ?? this.maxPricePerNight,
    );
  }
}
