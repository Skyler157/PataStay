import 'package:freezed_annotation/freezed_annotation.dart';

part 'reference_data.freezed.dart';
part 'reference_data.g.dart';

/// Configurable neighbourhood (admin-managed table, never hardcoded in UI).
@freezed
abstract class Neighbourhood with _$Neighbourhood {
  const factory Neighbourhood({
    required String id,
    required String name,
    required String slug,
    @Default('Nairobi') String city,
    String? county,
    double? latitude,
    double? longitude,
    @Default(false) bool isPopular,
    @Default(0) int sortOrder,
  }) = _Neighbourhood;

  factory Neighbourhood.fromJson(Map<String, dynamic> json) => _$NeighbourhoodFromJson(json);
}

@freezed
abstract class Amenity with _$Amenity {
  const factory Amenity({
    required String id,
    required String name,
    required String slug,
    @Default('general') String category,
    String? icon,
    @Default(false) bool isKey,
    @Default(0) int sortOrder,
  }) = _Amenity;

  factory Amenity.fromJson(Map<String, dynamic> json) => _$AmenityFromJson(json);
}
