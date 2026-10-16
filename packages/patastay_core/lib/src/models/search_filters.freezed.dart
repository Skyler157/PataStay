// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_filters.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchFilters {

 String get query; Set<String> get neighbourhoodIds; double? get minPrice; double? get maxPrice; Set<PropertyType> get propertyTypes; int? get guests; int? get minBedrooms; Set<String> get amenityIds; bool get verifiedOnly; bool get recentlyConfirmed; bool get featuredOnly; DateTime? get checkIn; DateTime? get checkOut; SearchSort get sort;/// "Near me": the guest's position (never stored) and search radius.
 double? get nearLatitude; double? get nearLongitude; double get radiusKm;
/// Create a copy of SearchFilters
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchFiltersCopyWith<SearchFilters> get copyWith => _$SearchFiltersCopyWithImpl<SearchFilters>(this as SearchFilters, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SearchFilters;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchFilters&&(identical(other.query, _this.query) || other.query == _this.query)&&const DeepCollectionEquality().equals(other.neighbourhoodIds, _this.neighbourhoodIds)&&(identical(other.minPrice, _this.minPrice) || other.minPrice == _this.minPrice)&&(identical(other.maxPrice, _this.maxPrice) || other.maxPrice == _this.maxPrice)&&const DeepCollectionEquality().equals(other.propertyTypes, _this.propertyTypes)&&(identical(other.guests, _this.guests) || other.guests == _this.guests)&&(identical(other.minBedrooms, _this.minBedrooms) || other.minBedrooms == _this.minBedrooms)&&const DeepCollectionEquality().equals(other.amenityIds, _this.amenityIds)&&(identical(other.verifiedOnly, _this.verifiedOnly) || other.verifiedOnly == _this.verifiedOnly)&&(identical(other.recentlyConfirmed, _this.recentlyConfirmed) || other.recentlyConfirmed == _this.recentlyConfirmed)&&(identical(other.featuredOnly, _this.featuredOnly) || other.featuredOnly == _this.featuredOnly)&&(identical(other.checkIn, _this.checkIn) || other.checkIn == _this.checkIn)&&(identical(other.checkOut, _this.checkOut) || other.checkOut == _this.checkOut)&&(identical(other.sort, _this.sort) || other.sort == _this.sort)&&(identical(other.nearLatitude, _this.nearLatitude) || other.nearLatitude == _this.nearLatitude)&&(identical(other.nearLongitude, _this.nearLongitude) || other.nearLongitude == _this.nearLongitude)&&(identical(other.radiusKm, _this.radiusKm) || other.radiusKm == _this.radiusKm));
}


@override
int get hashCode {
  final _this = this as SearchFilters;
  return Object.hash(runtimeType,_this.query,const DeepCollectionEquality().hash(_this.neighbourhoodIds),_this.minPrice,_this.maxPrice,const DeepCollectionEquality().hash(_this.propertyTypes),_this.guests,_this.minBedrooms,const DeepCollectionEquality().hash(_this.amenityIds),_this.verifiedOnly,_this.recentlyConfirmed,_this.featuredOnly,_this.checkIn,_this.checkOut,_this.sort,_this.nearLatitude,_this.nearLongitude,_this.radiusKm);
}

@override
String toString() {
  final _this = this as SearchFilters;
  return 'SearchFilters(query: ${_this.query}, neighbourhoodIds: ${_this.neighbourhoodIds}, minPrice: ${_this.minPrice}, maxPrice: ${_this.maxPrice}, propertyTypes: ${_this.propertyTypes}, guests: ${_this.guests}, minBedrooms: ${_this.minBedrooms}, amenityIds: ${_this.amenityIds}, verifiedOnly: ${_this.verifiedOnly}, recentlyConfirmed: ${_this.recentlyConfirmed}, featuredOnly: ${_this.featuredOnly}, checkIn: ${_this.checkIn}, checkOut: ${_this.checkOut}, sort: ${_this.sort}, nearLatitude: ${_this.nearLatitude}, nearLongitude: ${_this.nearLongitude}, radiusKm: ${_this.radiusKm})';
}


}

/// @nodoc
abstract mixin class $SearchFiltersCopyWith<$Res>  {
  factory $SearchFiltersCopyWith(SearchFilters value, $Res Function(SearchFilters) _then) = _$SearchFiltersCopyWithImpl;
@useResult
$Res call({
 String query, Set<String> neighbourhoodIds, double? minPrice, double? maxPrice, Set<PropertyType> propertyTypes, int? guests, int? minBedrooms, Set<String> amenityIds, bool verifiedOnly, bool recentlyConfirmed, bool featuredOnly, DateTime? checkIn, DateTime? checkOut, SearchSort sort, double? nearLatitude, double? nearLongitude, double radiusKm
});




}
/// @nodoc
class _$SearchFiltersCopyWithImpl<$Res>
    implements $SearchFiltersCopyWith<$Res> {
  _$SearchFiltersCopyWithImpl(this._self, this._then);

  final SearchFilters _self;
  final $Res Function(SearchFilters) _then;

/// Create a copy of SearchFilters
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? neighbourhoodIds = null,Object? minPrice = freezed,Object? maxPrice = freezed,Object? propertyTypes = null,Object? guests = freezed,Object? minBedrooms = freezed,Object? amenityIds = null,Object? verifiedOnly = null,Object? recentlyConfirmed = null,Object? featuredOnly = null,Object? checkIn = freezed,Object? checkOut = freezed,Object? sort = null,Object? nearLatitude = freezed,Object? nearLongitude = freezed,Object? radiusKm = null,}) {
  return _then(SearchFilters(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,neighbourhoodIds: null == neighbourhoodIds ? _self.neighbourhoodIds : neighbourhoodIds // ignore: cast_nullable_to_non_nullable
as Set<String>,minPrice: freezed == minPrice ? _self.minPrice : minPrice // ignore: cast_nullable_to_non_nullable
as double?,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as double?,propertyTypes: null == propertyTypes ? _self.propertyTypes : propertyTypes // ignore: cast_nullable_to_non_nullable
as Set<PropertyType>,guests: freezed == guests ? _self.guests : guests // ignore: cast_nullable_to_non_nullable
as int?,minBedrooms: freezed == minBedrooms ? _self.minBedrooms : minBedrooms // ignore: cast_nullable_to_non_nullable
as int?,amenityIds: null == amenityIds ? _self.amenityIds : amenityIds // ignore: cast_nullable_to_non_nullable
as Set<String>,verifiedOnly: null == verifiedOnly ? _self.verifiedOnly : verifiedOnly // ignore: cast_nullable_to_non_nullable
as bool,recentlyConfirmed: null == recentlyConfirmed ? _self.recentlyConfirmed : recentlyConfirmed // ignore: cast_nullable_to_non_nullable
as bool,featuredOnly: null == featuredOnly ? _self.featuredOnly : featuredOnly // ignore: cast_nullable_to_non_nullable
as bool,checkIn: freezed == checkIn ? _self.checkIn : checkIn // ignore: cast_nullable_to_non_nullable
as DateTime?,checkOut: freezed == checkOut ? _self.checkOut : checkOut // ignore: cast_nullable_to_non_nullable
as DateTime?,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as SearchSort,nearLatitude: freezed == nearLatitude ? _self.nearLatitude : nearLatitude // ignore: cast_nullable_to_non_nullable
as double?,nearLongitude: freezed == nearLongitude ? _self.nearLongitude : nearLongitude // ignore: cast_nullable_to_non_nullable
as double?,radiusKm: null == radiusKm ? _self.radiusKm : radiusKm // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchFilters].
extension SearchFiltersPatterns on SearchFilters {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchFilters value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchFilters() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchFilters value)  $default,){
final _that = this;
switch (_that) {
case _SearchFilters():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchFilters value)?  $default,){
final _that = this;
switch (_that) {
case _SearchFilters() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  Set<String> neighbourhoodIds,  double? minPrice,  double? maxPrice,  Set<PropertyType> propertyTypes,  int? guests,  int? minBedrooms,  Set<String> amenityIds,  bool verifiedOnly,  bool recentlyConfirmed,  bool featuredOnly,  DateTime? checkIn,  DateTime? checkOut,  SearchSort sort,  double? nearLatitude,  double? nearLongitude,  double radiusKm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchFilters() when $default != null:
return $default(_that.query,_that.neighbourhoodIds,_that.minPrice,_that.maxPrice,_that.propertyTypes,_that.guests,_that.minBedrooms,_that.amenityIds,_that.verifiedOnly,_that.recentlyConfirmed,_that.featuredOnly,_that.checkIn,_that.checkOut,_that.sort,_that.nearLatitude,_that.nearLongitude,_that.radiusKm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  Set<String> neighbourhoodIds,  double? minPrice,  double? maxPrice,  Set<PropertyType> propertyTypes,  int? guests,  int? minBedrooms,  Set<String> amenityIds,  bool verifiedOnly,  bool recentlyConfirmed,  bool featuredOnly,  DateTime? checkIn,  DateTime? checkOut,  SearchSort sort,  double? nearLatitude,  double? nearLongitude,  double radiusKm)  $default,) {final _that = this;
switch (_that) {
case _SearchFilters():
return $default(_that.query,_that.neighbourhoodIds,_that.minPrice,_that.maxPrice,_that.propertyTypes,_that.guests,_that.minBedrooms,_that.amenityIds,_that.verifiedOnly,_that.recentlyConfirmed,_that.featuredOnly,_that.checkIn,_that.checkOut,_that.sort,_that.nearLatitude,_that.nearLongitude,_that.radiusKm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  Set<String> neighbourhoodIds,  double? minPrice,  double? maxPrice,  Set<PropertyType> propertyTypes,  int? guests,  int? minBedrooms,  Set<String> amenityIds,  bool verifiedOnly,  bool recentlyConfirmed,  bool featuredOnly,  DateTime? checkIn,  DateTime? checkOut,  SearchSort sort,  double? nearLatitude,  double? nearLongitude,  double radiusKm)?  $default,) {final _that = this;
switch (_that) {
case _SearchFilters() when $default != null:
return $default(_that.query,_that.neighbourhoodIds,_that.minPrice,_that.maxPrice,_that.propertyTypes,_that.guests,_that.minBedrooms,_that.amenityIds,_that.verifiedOnly,_that.recentlyConfirmed,_that.featuredOnly,_that.checkIn,_that.checkOut,_that.sort,_that.nearLatitude,_that.nearLongitude,_that.radiusKm);case _:
  return null;

}
}

}

/// @nodoc


class _SearchFilters extends SearchFilters {
  const _SearchFilters({this.query = '',  Set<String> neighbourhoodIds = const {}, this.minPrice, this.maxPrice,  Set<PropertyType> propertyTypes = const {}, this.guests, this.minBedrooms,  Set<String> amenityIds = const {}, this.verifiedOnly = false, this.recentlyConfirmed = false, this.featuredOnly = false, this.checkIn, this.checkOut, this.sort = SearchSort.recommended, this.nearLatitude, this.nearLongitude, this.radiusKm = 5}): _neighbourhoodIds = neighbourhoodIds,_propertyTypes = propertyTypes,_amenityIds = amenityIds,super._();
  

@override@JsonKey() final  String query;
 final  Set<String> _neighbourhoodIds;
@override@JsonKey() Set<String> get neighbourhoodIds {
  if (_neighbourhoodIds is EqualUnmodifiableSetView) return _neighbourhoodIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_neighbourhoodIds);
}

@override final  double? minPrice;
@override final  double? maxPrice;
 final  Set<PropertyType> _propertyTypes;
@override@JsonKey() Set<PropertyType> get propertyTypes {
  if (_propertyTypes is EqualUnmodifiableSetView) return _propertyTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_propertyTypes);
}

@override final  int? guests;
@override final  int? minBedrooms;
 final  Set<String> _amenityIds;
@override@JsonKey() Set<String> get amenityIds {
  if (_amenityIds is EqualUnmodifiableSetView) return _amenityIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_amenityIds);
}

@override@JsonKey() final  bool verifiedOnly;
@override@JsonKey() final  bool recentlyConfirmed;
@override@JsonKey() final  bool featuredOnly;
@override final  DateTime? checkIn;
@override final  DateTime? checkOut;
@override@JsonKey() final  SearchSort sort;
/// "Near me": the guest's position (never stored) and search radius.
@override final  double? nearLatitude;
@override final  double? nearLongitude;
@override@JsonKey() final  double radiusKm;

/// Create a copy of SearchFilters
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchFiltersCopyWith<_SearchFilters> get copyWith => __$SearchFiltersCopyWithImpl<_SearchFilters>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchFilters&&(identical(other.query, query) || other.query == query)&&const DeepCollectionEquality().equals(other.neighbourhoodIds, _neighbourhoodIds)&&(identical(other.minPrice, minPrice) || other.minPrice == minPrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&const DeepCollectionEquality().equals(other.propertyTypes, _propertyTypes)&&(identical(other.guests, guests) || other.guests == guests)&&(identical(other.minBedrooms, minBedrooms) || other.minBedrooms == minBedrooms)&&const DeepCollectionEquality().equals(other.amenityIds, _amenityIds)&&(identical(other.verifiedOnly, verifiedOnly) || other.verifiedOnly == verifiedOnly)&&(identical(other.recentlyConfirmed, recentlyConfirmed) || other.recentlyConfirmed == recentlyConfirmed)&&(identical(other.featuredOnly, featuredOnly) || other.featuredOnly == featuredOnly)&&(identical(other.checkIn, checkIn) || other.checkIn == checkIn)&&(identical(other.checkOut, checkOut) || other.checkOut == checkOut)&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.nearLatitude, nearLatitude) || other.nearLatitude == nearLatitude)&&(identical(other.nearLongitude, nearLongitude) || other.nearLongitude == nearLongitude)&&(identical(other.radiusKm, radiusKm) || other.radiusKm == radiusKm));
}


@override
int get hashCode {
    return Object.hash(runtimeType,query,const DeepCollectionEquality().hash(_neighbourhoodIds),minPrice,maxPrice,const DeepCollectionEquality().hash(_propertyTypes),guests,minBedrooms,const DeepCollectionEquality().hash(_amenityIds),verifiedOnly,recentlyConfirmed,featuredOnly,checkIn,checkOut,sort,nearLatitude,nearLongitude,radiusKm);
}

@override
String toString() {
    return 'SearchFilters(query: $query, neighbourhoodIds: $neighbourhoodIds, minPrice: $minPrice, maxPrice: $maxPrice, propertyTypes: $propertyTypes, guests: $guests, minBedrooms: $minBedrooms, amenityIds: $amenityIds, verifiedOnly: $verifiedOnly, recentlyConfirmed: $recentlyConfirmed, featuredOnly: $featuredOnly, checkIn: $checkIn, checkOut: $checkOut, sort: $sort, nearLatitude: $nearLatitude, nearLongitude: $nearLongitude, radiusKm: $radiusKm)';
}


}

/// @nodoc
abstract mixin class _$SearchFiltersCopyWith<$Res> implements $SearchFiltersCopyWith<$Res> {
  factory _$SearchFiltersCopyWith(_SearchFilters value, $Res Function(_SearchFilters) _then) = __$SearchFiltersCopyWithImpl;
@override @useResult
$Res call({
 String query, Set<String> neighbourhoodIds, double? minPrice, double? maxPrice, Set<PropertyType> propertyTypes, int? guests, int? minBedrooms, Set<String> amenityIds, bool verifiedOnly, bool recentlyConfirmed, bool featuredOnly, DateTime? checkIn, DateTime? checkOut, SearchSort sort, double? nearLatitude, double? nearLongitude, double radiusKm
});




}
/// @nodoc
class __$SearchFiltersCopyWithImpl<$Res>
    implements _$SearchFiltersCopyWith<$Res> {
  __$SearchFiltersCopyWithImpl(this._self, this._then);

  final _SearchFilters _self;
  final $Res Function(_SearchFilters) _then;

/// Create a copy of SearchFilters
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? neighbourhoodIds = null,Object? minPrice = freezed,Object? maxPrice = freezed,Object? propertyTypes = null,Object? guests = freezed,Object? minBedrooms = freezed,Object? amenityIds = null,Object? verifiedOnly = null,Object? recentlyConfirmed = null,Object? featuredOnly = null,Object? checkIn = freezed,Object? checkOut = freezed,Object? sort = null,Object? nearLatitude = freezed,Object? nearLongitude = freezed,Object? radiusKm = null,}) {
  return _then(_SearchFilters(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,neighbourhoodIds: null == neighbourhoodIds ? _self._neighbourhoodIds : neighbourhoodIds // ignore: cast_nullable_to_non_nullable
as Set<String>,minPrice: freezed == minPrice ? _self.minPrice : minPrice // ignore: cast_nullable_to_non_nullable
as double?,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as double?,propertyTypes: null == propertyTypes ? _self._propertyTypes : propertyTypes // ignore: cast_nullable_to_non_nullable
as Set<PropertyType>,guests: freezed == guests ? _self.guests : guests // ignore: cast_nullable_to_non_nullable
as int?,minBedrooms: freezed == minBedrooms ? _self.minBedrooms : minBedrooms // ignore: cast_nullable_to_non_nullable
as int?,amenityIds: null == amenityIds ? _self._amenityIds : amenityIds // ignore: cast_nullable_to_non_nullable
as Set<String>,verifiedOnly: null == verifiedOnly ? _self.verifiedOnly : verifiedOnly // ignore: cast_nullable_to_non_nullable
as bool,recentlyConfirmed: null == recentlyConfirmed ? _self.recentlyConfirmed : recentlyConfirmed // ignore: cast_nullable_to_non_nullable
as bool,featuredOnly: null == featuredOnly ? _self.featuredOnly : featuredOnly // ignore: cast_nullable_to_non_nullable
as bool,checkIn: freezed == checkIn ? _self.checkIn : checkIn // ignore: cast_nullable_to_non_nullable
as DateTime?,checkOut: freezed == checkOut ? _self.checkOut : checkOut // ignore: cast_nullable_to_non_nullable
as DateTime?,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as SearchSort,nearLatitude: freezed == nearLatitude ? _self.nearLatitude : nearLatitude // ignore: cast_nullable_to_non_nullable
as double?,nearLongitude: freezed == nearLongitude ? _self.nearLongitude : nearLongitude // ignore: cast_nullable_to_non_nullable
as double?,radiusKm: null == radiusKm ? _self.radiusKm : radiusKm // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
