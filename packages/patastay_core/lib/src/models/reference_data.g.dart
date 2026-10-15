// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reference_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Neighbourhood _$NeighbourhoodFromJson(Map<String, dynamic> json) =>
    _Neighbourhood(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      city: json['city'] as String? ?? 'Nairobi',
      county: json['county'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isPopular: json['is_popular'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$NeighbourhoodToJson(_Neighbourhood instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'city': instance.city,
      'county': instance.county,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'is_popular': instance.isPopular,
      'sort_order': instance.sortOrder,
    };

_Amenity _$AmenityFromJson(Map<String, dynamic> json) => _Amenity(
  id: json['id'] as String,
  name: json['name'] as String,
  slug: json['slug'] as String,
  category: json['category'] as String? ?? 'general',
  icon: json['icon'] as String?,
  isKey: json['is_key'] as bool? ?? false,
  sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AmenityToJson(_Amenity instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'slug': instance.slug,
  'category': instance.category,
  'icon': instance.icon,
  'is_key': instance.isKey,
  'sort_order': instance.sortOrder,
};
