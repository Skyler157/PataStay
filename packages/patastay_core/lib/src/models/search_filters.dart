import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'search_filters.freezed.dart';

enum SearchSort {
  recommended('Recommended'),
  priceLow('Price: low to high'),
  priceHigh('Price: high to low'),
  newest('Newest'),
  nearest('Nearest first');

  const SearchSort(this.label);
  final String label;
}

/// Budget presets in KES per night, shown as one-tap chips. Ranges reflect
/// typical Nairobi short-stay prices (see docs/ARCHITECTURE.md research).
class BudgetBand {
  const BudgetBand(this.label, {this.min, this.max});

  final String label;
  final double? min;
  final double? max;

  static const presets = [
    BudgetBand('Under 2K', max: 2000),
    BudgetBand('2K – 4K', min: 2000, max: 4000),
    BudgetBand('4K – 7K', min: 4000, max: 7000),
    BudgetBand('7K+', min: 7000),
  ];
}

@freezed
abstract class SearchFilters with _$SearchFilters {
  const SearchFilters._();

  const factory SearchFilters({
    @Default('') String query,
    @Default({}) Set<String> neighbourhoodIds,
    double? minPrice,
    double? maxPrice,
    @Default({}) Set<PropertyType> propertyTypes,
    int? guests,
    int? minBedrooms,
    @Default({}) Set<String> amenityIds,
    @Default(false) bool verifiedOnly,
    @Default(false) bool recentlyConfirmed,
    @Default(false) bool featuredOnly,
    DateTime? checkIn,
    DateTime? checkOut,
    @Default(SearchSort.recommended) SearchSort sort,

    /// "Near me": the guest's position (never stored) and search radius.
    double? nearLatitude,
    double? nearLongitude,
    @Default(5) double radiusKm,
  }) = _SearchFilters;

  static const radiusChoices = [2.0, 5.0, 10.0, 20.0];

  bool get hasDates => checkIn != null && checkOut != null;
  bool get isNearMe => nearLatitude != null && nearLongitude != null;

  SearchFilters withoutNearMe() =>
      copyWith(nearLatitude: null, nearLongitude: null, sort: sort == SearchSort.nearest ? SearchSort.recommended : sort);

  /// Number of filters set in the filter sheet (for the "Filters · 3" chip).
  int get advancedCount =>
      neighbourhoodIds.length +
      propertyTypes.length +
      amenityIds.length +
      (minBedrooms != null ? 1 : 0) +
      (verifiedOnly ? 1 : 0) +
      (recentlyConfirmed ? 1 : 0);

  bool matchesBudget(BudgetBand band) => minPrice == band.min && maxPrice == band.max;

  Map<String, dynamic> toRpcParams() {
    String? day(DateTime? d) =>
        d == null ? null : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return {
      'p_query': query.trim().isEmpty ? null : query.trim(),
      'p_neighbourhood_ids': neighbourhoodIds.isEmpty ? null : neighbourhoodIds.toList(),
      'p_min_price': minPrice,
      'p_max_price': maxPrice,
      'p_property_types': propertyTypes.isEmpty ? null : propertyTypes.map((t) => t.dbValue).toList(),
      'p_min_guests': guests,
      'p_min_bedrooms': minBedrooms,
      'p_amenity_ids': amenityIds.isEmpty ? null : amenityIds.toList(),
      'p_verified_only': verifiedOnly,
      'p_confirmed_within_days': recentlyConfirmed ? 7 : null,
      'p_featured_only': featuredOnly,
      'p_check_in': hasDates ? day(checkIn) : null,
      'p_check_out': hasDates ? day(checkOut) : null,
    };
  }

  Map<String, dynamic> toNearbyParams({required int limit, required int offset}) => {
        ...toRpcParams(),
        'p_latitude': nearLatitude,
        'p_longitude': nearLongitude,
        'p_radius_km': radiusKm,
        'p_limit': limit,
        'p_offset': offset,
      };
}
