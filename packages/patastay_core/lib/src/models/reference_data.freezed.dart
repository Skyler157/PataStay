// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reference_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Neighbourhood {

 String get id; String get name; String get slug; String get city; String? get county; double? get latitude; double? get longitude; bool get isPopular; int get sortOrder;
/// Create a copy of Neighbourhood
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NeighbourhoodCopyWith<Neighbourhood> get copyWith => _$NeighbourhoodCopyWithImpl<Neighbourhood>(this as Neighbourhood, _$identity);

  /// Serializes this Neighbourhood to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Neighbourhood;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Neighbourhood&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.slug, _this.slug) || other.slug == _this.slug)&&(identical(other.city, _this.city) || other.city == _this.city)&&(identical(other.county, _this.county) || other.county == _this.county)&&(identical(other.latitude, _this.latitude) || other.latitude == _this.latitude)&&(identical(other.longitude, _this.longitude) || other.longitude == _this.longitude)&&(identical(other.isPopular, _this.isPopular) || other.isPopular == _this.isPopular)&&(identical(other.sortOrder, _this.sortOrder) || other.sortOrder == _this.sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Neighbourhood;
  return Object.hash(runtimeType,_this.id,_this.name,_this.slug,_this.city,_this.county,_this.latitude,_this.longitude,_this.isPopular,_this.sortOrder);
}

@override
String toString() {
  final _this = this as Neighbourhood;
  return 'Neighbourhood(id: ${_this.id}, name: ${_this.name}, slug: ${_this.slug}, city: ${_this.city}, county: ${_this.county}, latitude: ${_this.latitude}, longitude: ${_this.longitude}, isPopular: ${_this.isPopular}, sortOrder: ${_this.sortOrder})';
}


}

/// @nodoc
abstract mixin class $NeighbourhoodCopyWith<$Res>  {
  factory $NeighbourhoodCopyWith(Neighbourhood value, $Res Function(Neighbourhood) _then) = _$NeighbourhoodCopyWithImpl;
@useResult
$Res call({
 String id, String name, String slug, String city, String? county, double? latitude, double? longitude, bool isPopular, int sortOrder
});




}
/// @nodoc
class _$NeighbourhoodCopyWithImpl<$Res>
    implements $NeighbourhoodCopyWith<$Res> {
  _$NeighbourhoodCopyWithImpl(this._self, this._then);

  final Neighbourhood _self;
  final $Res Function(Neighbourhood) _then;

/// Create a copy of Neighbourhood
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? city = null,Object? county = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? isPopular = null,Object? sortOrder = null,}) {
  return _then(Neighbourhood(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,county: freezed == county ? _self.county : county // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,isPopular: null == isPopular ? _self.isPopular : isPopular // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Neighbourhood].
extension NeighbourhoodPatterns on Neighbourhood {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Neighbourhood value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Neighbourhood() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Neighbourhood value)  $default,){
final _that = this;
switch (_that) {
case _Neighbourhood():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Neighbourhood value)?  $default,){
final _that = this;
switch (_that) {
case _Neighbourhood() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String slug,  String city,  String? county,  double? latitude,  double? longitude,  bool isPopular,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Neighbourhood() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.city,_that.county,_that.latitude,_that.longitude,_that.isPopular,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String slug,  String city,  String? county,  double? latitude,  double? longitude,  bool isPopular,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _Neighbourhood():
return $default(_that.id,_that.name,_that.slug,_that.city,_that.county,_that.latitude,_that.longitude,_that.isPopular,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String slug,  String city,  String? county,  double? latitude,  double? longitude,  bool isPopular,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _Neighbourhood() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.city,_that.county,_that.latitude,_that.longitude,_that.isPopular,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Neighbourhood implements Neighbourhood {
  const _Neighbourhood({required this.id, required this.name, required this.slug, this.city = 'Nairobi', this.county, this.latitude, this.longitude, this.isPopular = false, this.sortOrder = 0});
  factory _Neighbourhood.fromJson(Map<String, dynamic> json) => _$NeighbourhoodFromJson(json);

@override final  String id;
@override final  String name;
@override final  String slug;
@override@JsonKey() final  String city;
@override final  String? county;
@override final  double? latitude;
@override final  double? longitude;
@override@JsonKey() final  bool isPopular;
@override@JsonKey() final  int sortOrder;

/// Create a copy of Neighbourhood
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NeighbourhoodCopyWith<_Neighbourhood> get copyWith => __$NeighbourhoodCopyWithImpl<_Neighbourhood>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NeighbourhoodToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Neighbourhood&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.city, city) || other.city == city)&&(identical(other.county, county) || other.county == county)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.isPopular, isPopular) || other.isPopular == isPopular)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,slug,city,county,latitude,longitude,isPopular,sortOrder);
}

@override
String toString() {
    return 'Neighbourhood(id: $id, name: $name, slug: $slug, city: $city, county: $county, latitude: $latitude, longitude: $longitude, isPopular: $isPopular, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$NeighbourhoodCopyWith<$Res> implements $NeighbourhoodCopyWith<$Res> {
  factory _$NeighbourhoodCopyWith(_Neighbourhood value, $Res Function(_Neighbourhood) _then) = __$NeighbourhoodCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String slug, String city, String? county, double? latitude, double? longitude, bool isPopular, int sortOrder
});




}
/// @nodoc
class __$NeighbourhoodCopyWithImpl<$Res>
    implements _$NeighbourhoodCopyWith<$Res> {
  __$NeighbourhoodCopyWithImpl(this._self, this._then);

  final _Neighbourhood _self;
  final $Res Function(_Neighbourhood) _then;

/// Create a copy of Neighbourhood
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? city = null,Object? county = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? isPopular = null,Object? sortOrder = null,}) {
  return _then(_Neighbourhood(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,county: freezed == county ? _self.county : county // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,isPopular: null == isPopular ? _self.isPopular : isPopular // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Amenity {

 String get id; String get name; String get slug; String get category; String? get icon; bool get isKey; int get sortOrder;
/// Create a copy of Amenity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AmenityCopyWith<Amenity> get copyWith => _$AmenityCopyWithImpl<Amenity>(this as Amenity, _$identity);

  /// Serializes this Amenity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Amenity;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Amenity&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.slug, _this.slug) || other.slug == _this.slug)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.isKey, _this.isKey) || other.isKey == _this.isKey)&&(identical(other.sortOrder, _this.sortOrder) || other.sortOrder == _this.sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Amenity;
  return Object.hash(runtimeType,_this.id,_this.name,_this.slug,_this.category,_this.icon,_this.isKey,_this.sortOrder);
}

@override
String toString() {
  final _this = this as Amenity;
  return 'Amenity(id: ${_this.id}, name: ${_this.name}, slug: ${_this.slug}, category: ${_this.category}, icon: ${_this.icon}, isKey: ${_this.isKey}, sortOrder: ${_this.sortOrder})';
}


}

/// @nodoc
abstract mixin class $AmenityCopyWith<$Res>  {
  factory $AmenityCopyWith(Amenity value, $Res Function(Amenity) _then) = _$AmenityCopyWithImpl;
@useResult
$Res call({
 String id, String name, String slug, String category, String? icon, bool isKey, int sortOrder
});




}
/// @nodoc
class _$AmenityCopyWithImpl<$Res>
    implements $AmenityCopyWith<$Res> {
  _$AmenityCopyWithImpl(this._self, this._then);

  final Amenity _self;
  final $Res Function(Amenity) _then;

/// Create a copy of Amenity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? category = null,Object? icon = freezed,Object? isKey = null,Object? sortOrder = null,}) {
  return _then(Amenity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,isKey: null == isKey ? _self.isKey : isKey // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Amenity].
extension AmenityPatterns on Amenity {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Amenity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Amenity() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Amenity value)  $default,){
final _that = this;
switch (_that) {
case _Amenity():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Amenity value)?  $default,){
final _that = this;
switch (_that) {
case _Amenity() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String slug,  String category,  String? icon,  bool isKey,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Amenity() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.category,_that.icon,_that.isKey,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String slug,  String category,  String? icon,  bool isKey,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _Amenity():
return $default(_that.id,_that.name,_that.slug,_that.category,_that.icon,_that.isKey,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String slug,  String category,  String? icon,  bool isKey,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _Amenity() when $default != null:
return $default(_that.id,_that.name,_that.slug,_that.category,_that.icon,_that.isKey,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Amenity implements Amenity {
  const _Amenity({required this.id, required this.name, required this.slug, this.category = 'general', this.icon, this.isKey = false, this.sortOrder = 0});
  factory _Amenity.fromJson(Map<String, dynamic> json) => _$AmenityFromJson(json);

@override final  String id;
@override final  String name;
@override final  String slug;
@override@JsonKey() final  String category;
@override final  String? icon;
@override@JsonKey() final  bool isKey;
@override@JsonKey() final  int sortOrder;

/// Create a copy of Amenity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AmenityCopyWith<_Amenity> get copyWith => __$AmenityCopyWithImpl<_Amenity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AmenityToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Amenity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.category, category) || other.category == category)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.isKey, isKey) || other.isKey == isKey)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,slug,category,icon,isKey,sortOrder);
}

@override
String toString() {
    return 'Amenity(id: $id, name: $name, slug: $slug, category: $category, icon: $icon, isKey: $isKey, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$AmenityCopyWith<$Res> implements $AmenityCopyWith<$Res> {
  factory _$AmenityCopyWith(_Amenity value, $Res Function(_Amenity) _then) = __$AmenityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String slug, String category, String? icon, bool isKey, int sortOrder
});




}
/// @nodoc
class __$AmenityCopyWithImpl<$Res>
    implements _$AmenityCopyWith<$Res> {
  __$AmenityCopyWithImpl(this._self, this._then);

  final _Amenity _self;
  final $Res Function(_Amenity) _then;

/// Create a copy of Amenity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? slug = null,Object? category = null,Object? icon = freezed,Object? isKey = null,Object? sortOrder = null,}) {
  return _then(_Amenity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,isKey: null == isKey ? _self.isKey : isKey // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
