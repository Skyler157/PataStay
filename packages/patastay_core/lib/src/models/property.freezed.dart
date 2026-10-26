// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'property.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PropertyImage {

 String? get id; String get storagePath; String? get thumbnailPath; int get displayOrder; String? get caption;
/// Create a copy of PropertyImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PropertyImageCopyWith<PropertyImage> get copyWith => _$PropertyImageCopyWithImpl<PropertyImage>(this as PropertyImage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PropertyImage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PropertyImage&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.storagePath, _this.storagePath) || other.storagePath == _this.storagePath)&&(identical(other.thumbnailPath, _this.thumbnailPath) || other.thumbnailPath == _this.thumbnailPath)&&(identical(other.displayOrder, _this.displayOrder) || other.displayOrder == _this.displayOrder)&&(identical(other.caption, _this.caption) || other.caption == _this.caption));
}


@override
int get hashCode {
  final _this = this as PropertyImage;
  return Object.hash(runtimeType,_this.id,_this.storagePath,_this.thumbnailPath,_this.displayOrder,_this.caption);
}

@override
String toString() {
  final _this = this as PropertyImage;
  return 'PropertyImage(id: ${_this.id}, storagePath: ${_this.storagePath}, thumbnailPath: ${_this.thumbnailPath}, displayOrder: ${_this.displayOrder}, caption: ${_this.caption})';
}


}

/// @nodoc
abstract mixin class $PropertyImageCopyWith<$Res>  {
  factory $PropertyImageCopyWith(PropertyImage value, $Res Function(PropertyImage) _then) = _$PropertyImageCopyWithImpl;
@useResult
$Res call({
 String? id, String storagePath, String? thumbnailPath, int displayOrder, String? caption
});




}
/// @nodoc
class _$PropertyImageCopyWithImpl<$Res>
    implements $PropertyImageCopyWith<$Res> {
  _$PropertyImageCopyWithImpl(this._self, this._then);

  final PropertyImage _self;
  final $Res Function(PropertyImage) _then;

/// Create a copy of PropertyImage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? storagePath = null,Object? thumbnailPath = freezed,Object? displayOrder = null,Object? caption = freezed,}) {
  return _then(PropertyImage(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PropertyImage].
extension PropertyImagePatterns on PropertyImage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PropertyImage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PropertyImage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PropertyImage value)  $default,){
final _that = this;
switch (_that) {
case _PropertyImage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PropertyImage value)?  $default,){
final _that = this;
switch (_that) {
case _PropertyImage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String storagePath,  String? thumbnailPath,  int displayOrder,  String? caption)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PropertyImage() when $default != null:
return $default(_that.id,_that.storagePath,_that.thumbnailPath,_that.displayOrder,_that.caption);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String storagePath,  String? thumbnailPath,  int displayOrder,  String? caption)  $default,) {final _that = this;
switch (_that) {
case _PropertyImage():
return $default(_that.id,_that.storagePath,_that.thumbnailPath,_that.displayOrder,_that.caption);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String storagePath,  String? thumbnailPath,  int displayOrder,  String? caption)?  $default,) {final _that = this;
switch (_that) {
case _PropertyImage() when $default != null:
return $default(_that.id,_that.storagePath,_that.thumbnailPath,_that.displayOrder,_that.caption);case _:
  return null;

}
}

}

/// @nodoc


class _PropertyImage extends PropertyImage {
  const _PropertyImage({this.id, required this.storagePath, this.thumbnailPath, this.displayOrder = 0, this.caption}): super._();
  

@override final  String? id;
@override final  String storagePath;
@override final  String? thumbnailPath;
@override@JsonKey() final  int displayOrder;
@override final  String? caption;

/// Create a copy of PropertyImage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PropertyImageCopyWith<_PropertyImage> get copyWith => __$PropertyImageCopyWithImpl<_PropertyImage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PropertyImage&&(identical(other.id, id) || other.id == id)&&(identical(other.storagePath, storagePath) || other.storagePath == storagePath)&&(identical(other.thumbnailPath, thumbnailPath) || other.thumbnailPath == thumbnailPath)&&(identical(other.displayOrder, displayOrder) || other.displayOrder == displayOrder)&&(identical(other.caption, caption) || other.caption == caption));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,storagePath,thumbnailPath,displayOrder,caption);
}

@override
String toString() {
    return 'PropertyImage(id: $id, storagePath: $storagePath, thumbnailPath: $thumbnailPath, displayOrder: $displayOrder, caption: $caption)';
}


}

/// @nodoc
abstract mixin class _$PropertyImageCopyWith<$Res> implements $PropertyImageCopyWith<$Res> {
  factory _$PropertyImageCopyWith(_PropertyImage value, $Res Function(_PropertyImage) _then) = __$PropertyImageCopyWithImpl;
@override @useResult
$Res call({
 String? id, String storagePath, String? thumbnailPath, int displayOrder, String? caption
});




}
/// @nodoc
class __$PropertyImageCopyWithImpl<$Res>
    implements _$PropertyImageCopyWith<$Res> {
  __$PropertyImageCopyWithImpl(this._self, this._then);

  final _PropertyImage _self;
  final $Res Function(_PropertyImage) _then;

/// Create a copy of PropertyImage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? storagePath = null,Object? thumbnailPath = freezed,Object? displayOrder = null,Object? caption = freezed,}) {
  return _then(_PropertyImage(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,storagePath: null == storagePath ? _self.storagePath : storagePath // ignore: cast_nullable_to_non_nullable
as String,thumbnailPath: freezed == thumbnailPath ? _self.thumbnailPath : thumbnailPath // ignore: cast_nullable_to_non_nullable
as String?,displayOrder: null == displayOrder ? _self.displayOrder : displayOrder // ignore: cast_nullable_to_non_nullable
as int,caption: freezed == caption ? _self.caption : caption // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$UnavailableRange {

 String? get id; DateTime get startsOn; DateTime get endsOn; String? get note;
/// Create a copy of UnavailableRange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnavailableRangeCopyWith<UnavailableRange> get copyWith => _$UnavailableRangeCopyWithImpl<UnavailableRange>(this as UnavailableRange, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UnavailableRange;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnavailableRange&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.startsOn, _this.startsOn) || other.startsOn == _this.startsOn)&&(identical(other.endsOn, _this.endsOn) || other.endsOn == _this.endsOn)&&(identical(other.note, _this.note) || other.note == _this.note));
}


@override
int get hashCode {
  final _this = this as UnavailableRange;
  return Object.hash(runtimeType,_this.id,_this.startsOn,_this.endsOn,_this.note);
}

@override
String toString() {
  final _this = this as UnavailableRange;
  return 'UnavailableRange(id: ${_this.id}, startsOn: ${_this.startsOn}, endsOn: ${_this.endsOn}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $UnavailableRangeCopyWith<$Res>  {
  factory $UnavailableRangeCopyWith(UnavailableRange value, $Res Function(UnavailableRange) _then) = _$UnavailableRangeCopyWithImpl;
@useResult
$Res call({
 String? id, DateTime startsOn, DateTime endsOn, String? note
});




}
/// @nodoc
class _$UnavailableRangeCopyWithImpl<$Res>
    implements $UnavailableRangeCopyWith<$Res> {
  _$UnavailableRangeCopyWithImpl(this._self, this._then);

  final UnavailableRange _self;
  final $Res Function(UnavailableRange) _then;

/// Create a copy of UnavailableRange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? startsOn = null,Object? endsOn = null,Object? note = freezed,}) {
  return _then(UnavailableRange(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,startsOn: null == startsOn ? _self.startsOn : startsOn // ignore: cast_nullable_to_non_nullable
as DateTime,endsOn: null == endsOn ? _self.endsOn : endsOn // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UnavailableRange].
extension UnavailableRangePatterns on UnavailableRange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnavailableRange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnavailableRange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnavailableRange value)  $default,){
final _that = this;
switch (_that) {
case _UnavailableRange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnavailableRange value)?  $default,){
final _that = this;
switch (_that) {
case _UnavailableRange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  DateTime startsOn,  DateTime endsOn,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnavailableRange() when $default != null:
return $default(_that.id,_that.startsOn,_that.endsOn,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  DateTime startsOn,  DateTime endsOn,  String? note)  $default,) {final _that = this;
switch (_that) {
case _UnavailableRange():
return $default(_that.id,_that.startsOn,_that.endsOn,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  DateTime startsOn,  DateTime endsOn,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _UnavailableRange() when $default != null:
return $default(_that.id,_that.startsOn,_that.endsOn,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _UnavailableRange implements UnavailableRange {
  const _UnavailableRange({this.id, required this.startsOn, required this.endsOn, this.note});
  

@override final  String? id;
@override final  DateTime startsOn;
@override final  DateTime endsOn;
@override final  String? note;

/// Create a copy of UnavailableRange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnavailableRangeCopyWith<_UnavailableRange> get copyWith => __$UnavailableRangeCopyWithImpl<_UnavailableRange>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnavailableRange&&(identical(other.id, id) || other.id == id)&&(identical(other.startsOn, startsOn) || other.startsOn == startsOn)&&(identical(other.endsOn, endsOn) || other.endsOn == endsOn)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,startsOn,endsOn,note);
}

@override
String toString() {
    return 'UnavailableRange(id: $id, startsOn: $startsOn, endsOn: $endsOn, note: $note)';
}


}

/// @nodoc
abstract mixin class _$UnavailableRangeCopyWith<$Res> implements $UnavailableRangeCopyWith<$Res> {
  factory _$UnavailableRangeCopyWith(_UnavailableRange value, $Res Function(_UnavailableRange) _then) = __$UnavailableRangeCopyWithImpl;
@override @useResult
$Res call({
 String? id, DateTime startsOn, DateTime endsOn, String? note
});




}
/// @nodoc
class __$UnavailableRangeCopyWithImpl<$Res>
    implements _$UnavailableRangeCopyWith<$Res> {
  __$UnavailableRangeCopyWithImpl(this._self, this._then);

  final _UnavailableRange _self;
  final $Res Function(_UnavailableRange) _then;

/// Create a copy of UnavailableRange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? startsOn = null,Object? endsOn = null,Object? note = freezed,}) {
  return _then(_UnavailableRange(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,startsOn: null == startsOn ? _self.startsOn : startsOn // ignore: cast_nullable_to_non_nullable
as DateTime,endsOn: null == endsOn ? _self.endsOn : endsOn // ignore: cast_nullable_to_non_nullable
as DateTime,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$Property {

 String get id; int get listingNumber; String get title; PropertyType? get propertyType; Neighbourhood? get neighbourhood;/// Approximate public location (100–300 m from the real address).
 double? get latitude; double? get longitude;/// Distance from the guest for "Near me" results (approximate).
 double? get distanceKm; double get nightlyRate; double get cleaningFee; double get refundableDeposit; int? get bedrooms; double? get bathrooms; int? get maximumGuests; int get minimumNights; DateTime? get verifiedAt; DateTime? get availabilityConfirmedAt; bool get isFeatured; bool get isSeed; DateTime get createdAt; List<PropertyImage> get images; List<Amenity> get amenities; String get description; String? get addressOrAreaDescription; String? get checkInTime; String? get checkOutTime; String? get checkInInformation; String? get checkOutInformation; String? get houseRules; String? get availabilityNote; List<UnavailableRange> get unavailableDates;
/// Create a copy of Property
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PropertyCopyWith<Property> get copyWith => _$PropertyCopyWithImpl<Property>(this as Property, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Property;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Property&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.listingNumber, _this.listingNumber) || other.listingNumber == _this.listingNumber)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.propertyType, _this.propertyType) || other.propertyType == _this.propertyType)&&(identical(other.neighbourhood, _this.neighbourhood) || other.neighbourhood == _this.neighbourhood)&&(identical(other.latitude, _this.latitude) || other.latitude == _this.latitude)&&(identical(other.longitude, _this.longitude) || other.longitude == _this.longitude)&&(identical(other.distanceKm, _this.distanceKm) || other.distanceKm == _this.distanceKm)&&(identical(other.nightlyRate, _this.nightlyRate) || other.nightlyRate == _this.nightlyRate)&&(identical(other.cleaningFee, _this.cleaningFee) || other.cleaningFee == _this.cleaningFee)&&(identical(other.refundableDeposit, _this.refundableDeposit) || other.refundableDeposit == _this.refundableDeposit)&&(identical(other.bedrooms, _this.bedrooms) || other.bedrooms == _this.bedrooms)&&(identical(other.bathrooms, _this.bathrooms) || other.bathrooms == _this.bathrooms)&&(identical(other.maximumGuests, _this.maximumGuests) || other.maximumGuests == _this.maximumGuests)&&(identical(other.minimumNights, _this.minimumNights) || other.minimumNights == _this.minimumNights)&&(identical(other.verifiedAt, _this.verifiedAt) || other.verifiedAt == _this.verifiedAt)&&(identical(other.availabilityConfirmedAt, _this.availabilityConfirmedAt) || other.availabilityConfirmedAt == _this.availabilityConfirmedAt)&&(identical(other.isFeatured, _this.isFeatured) || other.isFeatured == _this.isFeatured)&&(identical(other.isSeed, _this.isSeed) || other.isSeed == _this.isSeed)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&const DeepCollectionEquality().equals(other.images, _this.images)&&const DeepCollectionEquality().equals(other.amenities, _this.amenities)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.addressOrAreaDescription, _this.addressOrAreaDescription) || other.addressOrAreaDescription == _this.addressOrAreaDescription)&&(identical(other.checkInTime, _this.checkInTime) || other.checkInTime == _this.checkInTime)&&(identical(other.checkOutTime, _this.checkOutTime) || other.checkOutTime == _this.checkOutTime)&&(identical(other.checkInInformation, _this.checkInInformation) || other.checkInInformation == _this.checkInInformation)&&(identical(other.checkOutInformation, _this.checkOutInformation) || other.checkOutInformation == _this.checkOutInformation)&&(identical(other.houseRules, _this.houseRules) || other.houseRules == _this.houseRules)&&(identical(other.availabilityNote, _this.availabilityNote) || other.availabilityNote == _this.availabilityNote)&&const DeepCollectionEquality().equals(other.unavailableDates, _this.unavailableDates));
}


@override
int get hashCode {
  final _this = this as Property;
  return Object.hashAll([runtimeType,_this.id,_this.listingNumber,_this.title,_this.propertyType,_this.neighbourhood,_this.latitude,_this.longitude,_this.distanceKm,_this.nightlyRate,_this.cleaningFee,_this.refundableDeposit,_this.bedrooms,_this.bathrooms,_this.maximumGuests,_this.minimumNights,_this.verifiedAt,_this.availabilityConfirmedAt,_this.isFeatured,_this.isSeed,_this.createdAt,const DeepCollectionEquality().hash(_this.images),const DeepCollectionEquality().hash(_this.amenities),_this.description,_this.addressOrAreaDescription,_this.checkInTime,_this.checkOutTime,_this.checkInInformation,_this.checkOutInformation,_this.houseRules,_this.availabilityNote,const DeepCollectionEquality().hash(_this.unavailableDates)]);
}

@override
String toString() {
  final _this = this as Property;
  return 'Property(id: ${_this.id}, listingNumber: ${_this.listingNumber}, title: ${_this.title}, propertyType: ${_this.propertyType}, neighbourhood: ${_this.neighbourhood}, latitude: ${_this.latitude}, longitude: ${_this.longitude}, distanceKm: ${_this.distanceKm}, nightlyRate: ${_this.nightlyRate}, cleaningFee: ${_this.cleaningFee}, refundableDeposit: ${_this.refundableDeposit}, bedrooms: ${_this.bedrooms}, bathrooms: ${_this.bathrooms}, maximumGuests: ${_this.maximumGuests}, minimumNights: ${_this.minimumNights}, verifiedAt: ${_this.verifiedAt}, availabilityConfirmedAt: ${_this.availabilityConfirmedAt}, isFeatured: ${_this.isFeatured}, isSeed: ${_this.isSeed}, createdAt: ${_this.createdAt}, images: ${_this.images}, amenities: ${_this.amenities}, description: ${_this.description}, addressOrAreaDescription: ${_this.addressOrAreaDescription}, checkInTime: ${_this.checkInTime}, checkOutTime: ${_this.checkOutTime}, checkInInformation: ${_this.checkInInformation}, checkOutInformation: ${_this.checkOutInformation}, houseRules: ${_this.houseRules}, availabilityNote: ${_this.availabilityNote}, unavailableDates: ${_this.unavailableDates})';
}


}

/// @nodoc
abstract mixin class $PropertyCopyWith<$Res>  {
  factory $PropertyCopyWith(Property value, $Res Function(Property) _then) = _$PropertyCopyWithImpl;
@useResult
$Res call({
 String id, int listingNumber, String title, PropertyType? propertyType, Neighbourhood? neighbourhood, double? latitude, double? longitude, double? distanceKm, double nightlyRate, double cleaningFee, double refundableDeposit, int? bedrooms, double? bathrooms, int? maximumGuests, int minimumNights, DateTime? verifiedAt, DateTime? availabilityConfirmedAt, bool isFeatured, bool isSeed, DateTime createdAt, List<PropertyImage> images, List<Amenity> amenities, String description, String? addressOrAreaDescription, String? checkInTime, String? checkOutTime, String? checkInInformation, String? checkOutInformation, String? houseRules, String? availabilityNote, List<UnavailableRange> unavailableDates
});


$NeighbourhoodCopyWith<$Res>? get neighbourhood;

}
/// @nodoc
class _$PropertyCopyWithImpl<$Res>
    implements $PropertyCopyWith<$Res> {
  _$PropertyCopyWithImpl(this._self, this._then);

  final Property _self;
  final $Res Function(Property) _then;

/// Create a copy of Property
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? listingNumber = null,Object? title = null,Object? propertyType = freezed,Object? neighbourhood = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? distanceKm = freezed,Object? nightlyRate = null,Object? cleaningFee = null,Object? refundableDeposit = null,Object? bedrooms = freezed,Object? bathrooms = freezed,Object? maximumGuests = freezed,Object? minimumNights = null,Object? verifiedAt = freezed,Object? availabilityConfirmedAt = freezed,Object? isFeatured = null,Object? isSeed = null,Object? createdAt = null,Object? images = null,Object? amenities = null,Object? description = null,Object? addressOrAreaDescription = freezed,Object? checkInTime = freezed,Object? checkOutTime = freezed,Object? checkInInformation = freezed,Object? checkOutInformation = freezed,Object? houseRules = freezed,Object? availabilityNote = freezed,Object? unavailableDates = null,}) {
  return _then(Property(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,listingNumber: null == listingNumber ? _self.listingNumber : listingNumber // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,propertyType: freezed == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as PropertyType?,neighbourhood: freezed == neighbourhood ? _self.neighbourhood : neighbourhood // ignore: cast_nullable_to_non_nullable
as Neighbourhood?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,nightlyRate: null == nightlyRate ? _self.nightlyRate : nightlyRate // ignore: cast_nullable_to_non_nullable
as double,cleaningFee: null == cleaningFee ? _self.cleaningFee : cleaningFee // ignore: cast_nullable_to_non_nullable
as double,refundableDeposit: null == refundableDeposit ? _self.refundableDeposit : refundableDeposit // ignore: cast_nullable_to_non_nullable
as double,bedrooms: freezed == bedrooms ? _self.bedrooms : bedrooms // ignore: cast_nullable_to_non_nullable
as int?,bathrooms: freezed == bathrooms ? _self.bathrooms : bathrooms // ignore: cast_nullable_to_non_nullable
as double?,maximumGuests: freezed == maximumGuests ? _self.maximumGuests : maximumGuests // ignore: cast_nullable_to_non_nullable
as int?,minimumNights: null == minimumNights ? _self.minimumNights : minimumNights // ignore: cast_nullable_to_non_nullable
as int,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,availabilityConfirmedAt: freezed == availabilityConfirmedAt ? _self.availabilityConfirmedAt : availabilityConfirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,isSeed: null == isSeed ? _self.isSeed : isSeed // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<PropertyImage>,amenities: null == amenities ? _self.amenities : amenities // ignore: cast_nullable_to_non_nullable
as List<Amenity>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,addressOrAreaDescription: freezed == addressOrAreaDescription ? _self.addressOrAreaDescription : addressOrAreaDescription // ignore: cast_nullable_to_non_nullable
as String?,checkInTime: freezed == checkInTime ? _self.checkInTime : checkInTime // ignore: cast_nullable_to_non_nullable
as String?,checkOutTime: freezed == checkOutTime ? _self.checkOutTime : checkOutTime // ignore: cast_nullable_to_non_nullable
as String?,checkInInformation: freezed == checkInInformation ? _self.checkInInformation : checkInInformation // ignore: cast_nullable_to_non_nullable
as String?,checkOutInformation: freezed == checkOutInformation ? _self.checkOutInformation : checkOutInformation // ignore: cast_nullable_to_non_nullable
as String?,houseRules: freezed == houseRules ? _self.houseRules : houseRules // ignore: cast_nullable_to_non_nullable
as String?,availabilityNote: freezed == availabilityNote ? _self.availabilityNote : availabilityNote // ignore: cast_nullable_to_non_nullable
as String?,unavailableDates: null == unavailableDates ? _self.unavailableDates : unavailableDates // ignore: cast_nullable_to_non_nullable
as List<UnavailableRange>,
  ));
}
/// Create a copy of Property
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NeighbourhoodCopyWith<$Res>? get neighbourhood {
    if (_self.neighbourhood == null) {
    return null;
  }

  return $NeighbourhoodCopyWith<$Res>(_self.neighbourhood!, (value) {
    return _then(_self.copyWith(neighbourhood: value));
  });
}
}


/// Adds pattern-matching-related methods to [Property].
extension PropertyPatterns on Property {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Property value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Property() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Property value)  $default,){
final _that = this;
switch (_that) {
case _Property():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Property value)?  $default,){
final _that = this;
switch (_that) {
case _Property() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int listingNumber,  String title,  PropertyType? propertyType,  Neighbourhood? neighbourhood,  double? latitude,  double? longitude,  double? distanceKm,  double nightlyRate,  double cleaningFee,  double refundableDeposit,  int? bedrooms,  double? bathrooms,  int? maximumGuests,  int minimumNights,  DateTime? verifiedAt,  DateTime? availabilityConfirmedAt,  bool isFeatured,  bool isSeed,  DateTime createdAt,  List<PropertyImage> images,  List<Amenity> amenities,  String description,  String? addressOrAreaDescription,  String? checkInTime,  String? checkOutTime,  String? checkInInformation,  String? checkOutInformation,  String? houseRules,  String? availabilityNote,  List<UnavailableRange> unavailableDates)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Property() when $default != null:
return $default(_that.id,_that.listingNumber,_that.title,_that.propertyType,_that.neighbourhood,_that.latitude,_that.longitude,_that.distanceKm,_that.nightlyRate,_that.cleaningFee,_that.refundableDeposit,_that.bedrooms,_that.bathrooms,_that.maximumGuests,_that.minimumNights,_that.verifiedAt,_that.availabilityConfirmedAt,_that.isFeatured,_that.isSeed,_that.createdAt,_that.images,_that.amenities,_that.description,_that.addressOrAreaDescription,_that.checkInTime,_that.checkOutTime,_that.checkInInformation,_that.checkOutInformation,_that.houseRules,_that.availabilityNote,_that.unavailableDates);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int listingNumber,  String title,  PropertyType? propertyType,  Neighbourhood? neighbourhood,  double? latitude,  double? longitude,  double? distanceKm,  double nightlyRate,  double cleaningFee,  double refundableDeposit,  int? bedrooms,  double? bathrooms,  int? maximumGuests,  int minimumNights,  DateTime? verifiedAt,  DateTime? availabilityConfirmedAt,  bool isFeatured,  bool isSeed,  DateTime createdAt,  List<PropertyImage> images,  List<Amenity> amenities,  String description,  String? addressOrAreaDescription,  String? checkInTime,  String? checkOutTime,  String? checkInInformation,  String? checkOutInformation,  String? houseRules,  String? availabilityNote,  List<UnavailableRange> unavailableDates)  $default,) {final _that = this;
switch (_that) {
case _Property():
return $default(_that.id,_that.listingNumber,_that.title,_that.propertyType,_that.neighbourhood,_that.latitude,_that.longitude,_that.distanceKm,_that.nightlyRate,_that.cleaningFee,_that.refundableDeposit,_that.bedrooms,_that.bathrooms,_that.maximumGuests,_that.minimumNights,_that.verifiedAt,_that.availabilityConfirmedAt,_that.isFeatured,_that.isSeed,_that.createdAt,_that.images,_that.amenities,_that.description,_that.addressOrAreaDescription,_that.checkInTime,_that.checkOutTime,_that.checkInInformation,_that.checkOutInformation,_that.houseRules,_that.availabilityNote,_that.unavailableDates);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int listingNumber,  String title,  PropertyType? propertyType,  Neighbourhood? neighbourhood,  double? latitude,  double? longitude,  double? distanceKm,  double nightlyRate,  double cleaningFee,  double refundableDeposit,  int? bedrooms,  double? bathrooms,  int? maximumGuests,  int minimumNights,  DateTime? verifiedAt,  DateTime? availabilityConfirmedAt,  bool isFeatured,  bool isSeed,  DateTime createdAt,  List<PropertyImage> images,  List<Amenity> amenities,  String description,  String? addressOrAreaDescription,  String? checkInTime,  String? checkOutTime,  String? checkInInformation,  String? checkOutInformation,  String? houseRules,  String? availabilityNote,  List<UnavailableRange> unavailableDates)?  $default,) {final _that = this;
switch (_that) {
case _Property() when $default != null:
return $default(_that.id,_that.listingNumber,_that.title,_that.propertyType,_that.neighbourhood,_that.latitude,_that.longitude,_that.distanceKm,_that.nightlyRate,_that.cleaningFee,_that.refundableDeposit,_that.bedrooms,_that.bathrooms,_that.maximumGuests,_that.minimumNights,_that.verifiedAt,_that.availabilityConfirmedAt,_that.isFeatured,_that.isSeed,_that.createdAt,_that.images,_that.amenities,_that.description,_that.addressOrAreaDescription,_that.checkInTime,_that.checkOutTime,_that.checkInInformation,_that.checkOutInformation,_that.houseRules,_that.availabilityNote,_that.unavailableDates);case _:
  return null;

}
}

}

/// @nodoc


class _Property extends Property {
  const _Property({required this.id, required this.listingNumber, required this.title, this.propertyType, this.neighbourhood, this.latitude, this.longitude, this.distanceKm, required this.nightlyRate, this.cleaningFee = 0, this.refundableDeposit = 0, this.bedrooms, this.bathrooms, this.maximumGuests, this.minimumNights = 1, this.verifiedAt, this.availabilityConfirmedAt, this.isFeatured = false, this.isSeed = false, required this.createdAt,  List<PropertyImage> images = const [],  List<Amenity> amenities = const [], this.description = '', this.addressOrAreaDescription, this.checkInTime, this.checkOutTime, this.checkInInformation, this.checkOutInformation, this.houseRules, this.availabilityNote,  List<UnavailableRange> unavailableDates = const []}): _images = images,_amenities = amenities,_unavailableDates = unavailableDates,super._();
  

@override final  String id;
@override final  int listingNumber;
@override final  String title;
@override final  PropertyType? propertyType;
@override final  Neighbourhood? neighbourhood;
/// Approximate public location (100–300 m from the real address).
@override final  double? latitude;
@override final  double? longitude;
/// Distance from the guest for "Near me" results (approximate).
@override final  double? distanceKm;
@override final  double nightlyRate;
@override@JsonKey() final  double cleaningFee;
@override@JsonKey() final  double refundableDeposit;
@override final  int? bedrooms;
@override final  double? bathrooms;
@override final  int? maximumGuests;
@override@JsonKey() final  int minimumNights;
@override final  DateTime? verifiedAt;
@override final  DateTime? availabilityConfirmedAt;
@override@JsonKey() final  bool isFeatured;
@override@JsonKey() final  bool isSeed;
@override final  DateTime createdAt;
 final  List<PropertyImage> _images;
@override@JsonKey() List<PropertyImage> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

 final  List<Amenity> _amenities;
@override@JsonKey() List<Amenity> get amenities {
  if (_amenities is EqualUnmodifiableListView) return _amenities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_amenities);
}

@override@JsonKey() final  String description;
@override final  String? addressOrAreaDescription;
@override final  String? checkInTime;
@override final  String? checkOutTime;
@override final  String? checkInInformation;
@override final  String? checkOutInformation;
@override final  String? houseRules;
@override final  String? availabilityNote;
 final  List<UnavailableRange> _unavailableDates;
@override@JsonKey() List<UnavailableRange> get unavailableDates {
  if (_unavailableDates is EqualUnmodifiableListView) return _unavailableDates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_unavailableDates);
}


/// Create a copy of Property
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PropertyCopyWith<_Property> get copyWith => __$PropertyCopyWithImpl<_Property>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Property&&(identical(other.id, id) || other.id == id)&&(identical(other.listingNumber, listingNumber) || other.listingNumber == listingNumber)&&(identical(other.title, title) || other.title == title)&&(identical(other.propertyType, propertyType) || other.propertyType == propertyType)&&(identical(other.neighbourhood, neighbourhood) || other.neighbourhood == neighbourhood)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.nightlyRate, nightlyRate) || other.nightlyRate == nightlyRate)&&(identical(other.cleaningFee, cleaningFee) || other.cleaningFee == cleaningFee)&&(identical(other.refundableDeposit, refundableDeposit) || other.refundableDeposit == refundableDeposit)&&(identical(other.bedrooms, bedrooms) || other.bedrooms == bedrooms)&&(identical(other.bathrooms, bathrooms) || other.bathrooms == bathrooms)&&(identical(other.maximumGuests, maximumGuests) || other.maximumGuests == maximumGuests)&&(identical(other.minimumNights, minimumNights) || other.minimumNights == minimumNights)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt)&&(identical(other.availabilityConfirmedAt, availabilityConfirmedAt) || other.availabilityConfirmedAt == availabilityConfirmedAt)&&(identical(other.isFeatured, isFeatured) || other.isFeatured == isFeatured)&&(identical(other.isSeed, isSeed) || other.isSeed == isSeed)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.images, _images)&&const DeepCollectionEquality().equals(other.amenities, _amenities)&&(identical(other.description, description) || other.description == description)&&(identical(other.addressOrAreaDescription, addressOrAreaDescription) || other.addressOrAreaDescription == addressOrAreaDescription)&&(identical(other.checkInTime, checkInTime) || other.checkInTime == checkInTime)&&(identical(other.checkOutTime, checkOutTime) || other.checkOutTime == checkOutTime)&&(identical(other.checkInInformation, checkInInformation) || other.checkInInformation == checkInInformation)&&(identical(other.checkOutInformation, checkOutInformation) || other.checkOutInformation == checkOutInformation)&&(identical(other.houseRules, houseRules) || other.houseRules == houseRules)&&(identical(other.availabilityNote, availabilityNote) || other.availabilityNote == availabilityNote)&&const DeepCollectionEquality().equals(other.unavailableDates, _unavailableDates));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,listingNumber,title,propertyType,neighbourhood,latitude,longitude,distanceKm,nightlyRate,cleaningFee,refundableDeposit,bedrooms,bathrooms,maximumGuests,minimumNights,verifiedAt,availabilityConfirmedAt,isFeatured,isSeed,createdAt,const DeepCollectionEquality().hash(_images),const DeepCollectionEquality().hash(_amenities),description,addressOrAreaDescription,checkInTime,checkOutTime,checkInInformation,checkOutInformation,houseRules,availabilityNote,const DeepCollectionEquality().hash(_unavailableDates)]);
}

@override
String toString() {
    return 'Property(id: $id, listingNumber: $listingNumber, title: $title, propertyType: $propertyType, neighbourhood: $neighbourhood, latitude: $latitude, longitude: $longitude, distanceKm: $distanceKm, nightlyRate: $nightlyRate, cleaningFee: $cleaningFee, refundableDeposit: $refundableDeposit, bedrooms: $bedrooms, bathrooms: $bathrooms, maximumGuests: $maximumGuests, minimumNights: $minimumNights, verifiedAt: $verifiedAt, availabilityConfirmedAt: $availabilityConfirmedAt, isFeatured: $isFeatured, isSeed: $isSeed, createdAt: $createdAt, images: $images, amenities: $amenities, description: $description, addressOrAreaDescription: $addressOrAreaDescription, checkInTime: $checkInTime, checkOutTime: $checkOutTime, checkInInformation: $checkInInformation, checkOutInformation: $checkOutInformation, houseRules: $houseRules, availabilityNote: $availabilityNote, unavailableDates: $unavailableDates)';
}


}

/// @nodoc
abstract mixin class _$PropertyCopyWith<$Res> implements $PropertyCopyWith<$Res> {
  factory _$PropertyCopyWith(_Property value, $Res Function(_Property) _then) = __$PropertyCopyWithImpl;
@override @useResult
$Res call({
 String id, int listingNumber, String title, PropertyType? propertyType, Neighbourhood? neighbourhood, double? latitude, double? longitude, double? distanceKm, double nightlyRate, double cleaningFee, double refundableDeposit, int? bedrooms, double? bathrooms, int? maximumGuests, int minimumNights, DateTime? verifiedAt, DateTime? availabilityConfirmedAt, bool isFeatured, bool isSeed, DateTime createdAt, List<PropertyImage> images, List<Amenity> amenities, String description, String? addressOrAreaDescription, String? checkInTime, String? checkOutTime, String? checkInInformation, String? checkOutInformation, String? houseRules, String? availabilityNote, List<UnavailableRange> unavailableDates
});


@override $NeighbourhoodCopyWith<$Res>? get neighbourhood;

}
/// @nodoc
class __$PropertyCopyWithImpl<$Res>
    implements _$PropertyCopyWith<$Res> {
  __$PropertyCopyWithImpl(this._self, this._then);

  final _Property _self;
  final $Res Function(_Property) _then;

/// Create a copy of Property
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? listingNumber = null,Object? title = null,Object? propertyType = freezed,Object? neighbourhood = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? distanceKm = freezed,Object? nightlyRate = null,Object? cleaningFee = null,Object? refundableDeposit = null,Object? bedrooms = freezed,Object? bathrooms = freezed,Object? maximumGuests = freezed,Object? minimumNights = null,Object? verifiedAt = freezed,Object? availabilityConfirmedAt = freezed,Object? isFeatured = null,Object? isSeed = null,Object? createdAt = null,Object? images = null,Object? amenities = null,Object? description = null,Object? addressOrAreaDescription = freezed,Object? checkInTime = freezed,Object? checkOutTime = freezed,Object? checkInInformation = freezed,Object? checkOutInformation = freezed,Object? houseRules = freezed,Object? availabilityNote = freezed,Object? unavailableDates = null,}) {
  return _then(_Property(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,listingNumber: null == listingNumber ? _self.listingNumber : listingNumber // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,propertyType: freezed == propertyType ? _self.propertyType : propertyType // ignore: cast_nullable_to_non_nullable
as PropertyType?,neighbourhood: freezed == neighbourhood ? _self.neighbourhood : neighbourhood // ignore: cast_nullable_to_non_nullable
as Neighbourhood?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,nightlyRate: null == nightlyRate ? _self.nightlyRate : nightlyRate // ignore: cast_nullable_to_non_nullable
as double,cleaningFee: null == cleaningFee ? _self.cleaningFee : cleaningFee // ignore: cast_nullable_to_non_nullable
as double,refundableDeposit: null == refundableDeposit ? _self.refundableDeposit : refundableDeposit // ignore: cast_nullable_to_non_nullable
as double,bedrooms: freezed == bedrooms ? _self.bedrooms : bedrooms // ignore: cast_nullable_to_non_nullable
as int?,bathrooms: freezed == bathrooms ? _self.bathrooms : bathrooms // ignore: cast_nullable_to_non_nullable
as double?,maximumGuests: freezed == maximumGuests ? _self.maximumGuests : maximumGuests // ignore: cast_nullable_to_non_nullable
as int?,minimumNights: null == minimumNights ? _self.minimumNights : minimumNights // ignore: cast_nullable_to_non_nullable
as int,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,availabilityConfirmedAt: freezed == availabilityConfirmedAt ? _self.availabilityConfirmedAt : availabilityConfirmedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isFeatured: null == isFeatured ? _self.isFeatured : isFeatured // ignore: cast_nullable_to_non_nullable
as bool,isSeed: null == isSeed ? _self.isSeed : isSeed // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<PropertyImage>,amenities: null == amenities ? _self._amenities : amenities // ignore: cast_nullable_to_non_nullable
as List<Amenity>,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,addressOrAreaDescription: freezed == addressOrAreaDescription ? _self.addressOrAreaDescription : addressOrAreaDescription // ignore: cast_nullable_to_non_nullable
as String?,checkInTime: freezed == checkInTime ? _self.checkInTime : checkInTime // ignore: cast_nullable_to_non_nullable
as String?,checkOutTime: freezed == checkOutTime ? _self.checkOutTime : checkOutTime // ignore: cast_nullable_to_non_nullable
as String?,checkInInformation: freezed == checkInInformation ? _self.checkInInformation : checkInInformation // ignore: cast_nullable_to_non_nullable
as String?,checkOutInformation: freezed == checkOutInformation ? _self.checkOutInformation : checkOutInformation // ignore: cast_nullable_to_non_nullable
as String?,houseRules: freezed == houseRules ? _self.houseRules : houseRules // ignore: cast_nullable_to_non_nullable
as String?,availabilityNote: freezed == availabilityNote ? _self.availabilityNote : availabilityNote // ignore: cast_nullable_to_non_nullable
as String?,unavailableDates: null == unavailableDates ? _self._unavailableDates : unavailableDates // ignore: cast_nullable_to_non_nullable
as List<UnavailableRange>,
  ));
}

/// Create a copy of Property
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NeighbourhoodCopyWith<$Res>? get neighbourhood {
    if (_self.neighbourhood == null) {
    return null;
  }

  return $NeighbourhoodCopyWith<$Res>(_self.neighbourhood!, (value) {
    return _then(_self.copyWith(neighbourhood: value));
  });
}
}

/// @nodoc
mixin _$HostSummary {

 String get displayName; DateTime get memberSince; int get publishedListings; int get verifiedListings;/// Median reply time; only set once the host has answered 5+ enquiries.
 double? get typicalResponseHours;
/// Create a copy of HostSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HostSummaryCopyWith<HostSummary> get copyWith => _$HostSummaryCopyWithImpl<HostSummary>(this as HostSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as HostSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HostSummary&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.memberSince, _this.memberSince) || other.memberSince == _this.memberSince)&&(identical(other.publishedListings, _this.publishedListings) || other.publishedListings == _this.publishedListings)&&(identical(other.verifiedListings, _this.verifiedListings) || other.verifiedListings == _this.verifiedListings)&&(identical(other.typicalResponseHours, _this.typicalResponseHours) || other.typicalResponseHours == _this.typicalResponseHours));
}


@override
int get hashCode {
  final _this = this as HostSummary;
  return Object.hash(runtimeType,_this.displayName,_this.memberSince,_this.publishedListings,_this.verifiedListings,_this.typicalResponseHours);
}

@override
String toString() {
  final _this = this as HostSummary;
  return 'HostSummary(displayName: ${_this.displayName}, memberSince: ${_this.memberSince}, publishedListings: ${_this.publishedListings}, verifiedListings: ${_this.verifiedListings}, typicalResponseHours: ${_this.typicalResponseHours})';
}


}

/// @nodoc
abstract mixin class $HostSummaryCopyWith<$Res>  {
  factory $HostSummaryCopyWith(HostSummary value, $Res Function(HostSummary) _then) = _$HostSummaryCopyWithImpl;
@useResult
$Res call({
 String displayName, DateTime memberSince, int publishedListings, int verifiedListings, double? typicalResponseHours
});




}
/// @nodoc
class _$HostSummaryCopyWithImpl<$Res>
    implements $HostSummaryCopyWith<$Res> {
  _$HostSummaryCopyWithImpl(this._self, this._then);

  final HostSummary _self;
  final $Res Function(HostSummary) _then;

/// Create a copy of HostSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? displayName = null,Object? memberSince = null,Object? publishedListings = null,Object? verifiedListings = null,Object? typicalResponseHours = freezed,}) {
  return _then(HostSummary(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,memberSince: null == memberSince ? _self.memberSince : memberSince // ignore: cast_nullable_to_non_nullable
as DateTime,publishedListings: null == publishedListings ? _self.publishedListings : publishedListings // ignore: cast_nullable_to_non_nullable
as int,verifiedListings: null == verifiedListings ? _self.verifiedListings : verifiedListings // ignore: cast_nullable_to_non_nullable
as int,typicalResponseHours: freezed == typicalResponseHours ? _self.typicalResponseHours : typicalResponseHours // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [HostSummary].
extension HostSummaryPatterns on HostSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HostSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HostSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HostSummary value)  $default,){
final _that = this;
switch (_that) {
case _HostSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HostSummary value)?  $default,){
final _that = this;
switch (_that) {
case _HostSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String displayName,  DateTime memberSince,  int publishedListings,  int verifiedListings,  double? typicalResponseHours)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HostSummary() when $default != null:
return $default(_that.displayName,_that.memberSince,_that.publishedListings,_that.verifiedListings,_that.typicalResponseHours);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String displayName,  DateTime memberSince,  int publishedListings,  int verifiedListings,  double? typicalResponseHours)  $default,) {final _that = this;
switch (_that) {
case _HostSummary():
return $default(_that.displayName,_that.memberSince,_that.publishedListings,_that.verifiedListings,_that.typicalResponseHours);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String displayName,  DateTime memberSince,  int publishedListings,  int verifiedListings,  double? typicalResponseHours)?  $default,) {final _that = this;
switch (_that) {
case _HostSummary() when $default != null:
return $default(_that.displayName,_that.memberSince,_that.publishedListings,_that.verifiedListings,_that.typicalResponseHours);case _:
  return null;

}
}

}

/// @nodoc


class _HostSummary extends HostSummary {
  const _HostSummary({required this.displayName, required this.memberSince, this.publishedListings = 0, this.verifiedListings = 0, this.typicalResponseHours}): super._();
  

@override final  String displayName;
@override final  DateTime memberSince;
@override@JsonKey() final  int publishedListings;
@override@JsonKey() final  int verifiedListings;
/// Median reply time; only set once the host has answered 5+ enquiries.
@override final  double? typicalResponseHours;

/// Create a copy of HostSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HostSummaryCopyWith<_HostSummary> get copyWith => __$HostSummaryCopyWithImpl<_HostSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HostSummary&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.memberSince, memberSince) || other.memberSince == memberSince)&&(identical(other.publishedListings, publishedListings) || other.publishedListings == publishedListings)&&(identical(other.verifiedListings, verifiedListings) || other.verifiedListings == verifiedListings)&&(identical(other.typicalResponseHours, typicalResponseHours) || other.typicalResponseHours == typicalResponseHours));
}


@override
int get hashCode {
    return Object.hash(runtimeType,displayName,memberSince,publishedListings,verifiedListings,typicalResponseHours);
}

@override
String toString() {
    return 'HostSummary(displayName: $displayName, memberSince: $memberSince, publishedListings: $publishedListings, verifiedListings: $verifiedListings, typicalResponseHours: $typicalResponseHours)';
}


}

/// @nodoc
abstract mixin class _$HostSummaryCopyWith<$Res> implements $HostSummaryCopyWith<$Res> {
  factory _$HostSummaryCopyWith(_HostSummary value, $Res Function(_HostSummary) _then) = __$HostSummaryCopyWithImpl;
@override @useResult
$Res call({
 String displayName, DateTime memberSince, int publishedListings, int verifiedListings, double? typicalResponseHours
});




}
/// @nodoc
class __$HostSummaryCopyWithImpl<$Res>
    implements _$HostSummaryCopyWith<$Res> {
  __$HostSummaryCopyWithImpl(this._self, this._then);

  final _HostSummary _self;
  final $Res Function(_HostSummary) _then;

/// Create a copy of HostSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? displayName = null,Object? memberSince = null,Object? publishedListings = null,Object? verifiedListings = null,Object? typicalResponseHours = freezed,}) {
  return _then(_HostSummary(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,memberSince: null == memberSince ? _self.memberSince : memberSince // ignore: cast_nullable_to_non_nullable
as DateTime,publishedListings: null == publishedListings ? _self.publishedListings : publishedListings // ignore: cast_nullable_to_non_nullable
as int,verifiedListings: null == verifiedListings ? _self.verifiedListings : verifiedListings // ignore: cast_nullable_to_non_nullable
as int,typicalResponseHours: freezed == typicalResponseHours ? _self.typicalResponseHours : typicalResponseHours // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
