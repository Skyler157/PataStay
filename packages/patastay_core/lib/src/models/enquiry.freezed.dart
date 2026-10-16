// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'enquiry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Enquiry {

 String get id; String get propertyId; DateTime get checkIn; DateTime get checkOut; int get guestCount; String get guestName; String get guestContact; String? get message; EnquiryStatus get status; String? get ownerResponse; DateTime? get seenAt; DateTime? get respondedAt; DateTime? get ownerReportedBookingAt; DateTime? get guestReportedBookingAt; DateTime get createdAt; String? get propertyTitle; int? get listingNumber; PropertyImage? get propertyCover;
/// Create a copy of Enquiry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnquiryCopyWith<Enquiry> get copyWith => _$EnquiryCopyWithImpl<Enquiry>(this as Enquiry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Enquiry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Enquiry&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.propertyId, _this.propertyId) || other.propertyId == _this.propertyId)&&(identical(other.checkIn, _this.checkIn) || other.checkIn == _this.checkIn)&&(identical(other.checkOut, _this.checkOut) || other.checkOut == _this.checkOut)&&(identical(other.guestCount, _this.guestCount) || other.guestCount == _this.guestCount)&&(identical(other.guestName, _this.guestName) || other.guestName == _this.guestName)&&(identical(other.guestContact, _this.guestContact) || other.guestContact == _this.guestContact)&&(identical(other.message, _this.message) || other.message == _this.message)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.ownerResponse, _this.ownerResponse) || other.ownerResponse == _this.ownerResponse)&&(identical(other.seenAt, _this.seenAt) || other.seenAt == _this.seenAt)&&(identical(other.respondedAt, _this.respondedAt) || other.respondedAt == _this.respondedAt)&&(identical(other.ownerReportedBookingAt, _this.ownerReportedBookingAt) || other.ownerReportedBookingAt == _this.ownerReportedBookingAt)&&(identical(other.guestReportedBookingAt, _this.guestReportedBookingAt) || other.guestReportedBookingAt == _this.guestReportedBookingAt)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.propertyTitle, _this.propertyTitle) || other.propertyTitle == _this.propertyTitle)&&(identical(other.listingNumber, _this.listingNumber) || other.listingNumber == _this.listingNumber)&&(identical(other.propertyCover, _this.propertyCover) || other.propertyCover == _this.propertyCover));
}


@override
int get hashCode {
  final _this = this as Enquiry;
  return Object.hash(runtimeType,_this.id,_this.propertyId,_this.checkIn,_this.checkOut,_this.guestCount,_this.guestName,_this.guestContact,_this.message,_this.status,_this.ownerResponse,_this.seenAt,_this.respondedAt,_this.ownerReportedBookingAt,_this.guestReportedBookingAt,_this.createdAt,_this.propertyTitle,_this.listingNumber,_this.propertyCover);
}

@override
String toString() {
  final _this = this as Enquiry;
  return 'Enquiry(id: ${_this.id}, propertyId: ${_this.propertyId}, checkIn: ${_this.checkIn}, checkOut: ${_this.checkOut}, guestCount: ${_this.guestCount}, guestName: ${_this.guestName}, guestContact: ${_this.guestContact}, message: ${_this.message}, status: ${_this.status}, ownerResponse: ${_this.ownerResponse}, seenAt: ${_this.seenAt}, respondedAt: ${_this.respondedAt}, ownerReportedBookingAt: ${_this.ownerReportedBookingAt}, guestReportedBookingAt: ${_this.guestReportedBookingAt}, createdAt: ${_this.createdAt}, propertyTitle: ${_this.propertyTitle}, listingNumber: ${_this.listingNumber}, propertyCover: ${_this.propertyCover})';
}


}

/// @nodoc
abstract mixin class $EnquiryCopyWith<$Res>  {
  factory $EnquiryCopyWith(Enquiry value, $Res Function(Enquiry) _then) = _$EnquiryCopyWithImpl;
@useResult
$Res call({
 String id, String propertyId, DateTime checkIn, DateTime checkOut, int guestCount, String guestName, String guestContact, String? message, EnquiryStatus status, String? ownerResponse, DateTime? seenAt, DateTime? respondedAt, DateTime? ownerReportedBookingAt, DateTime? guestReportedBookingAt, DateTime createdAt, String? propertyTitle, int? listingNumber, PropertyImage? propertyCover
});


$PropertyImageCopyWith<$Res>? get propertyCover;

}
/// @nodoc
class _$EnquiryCopyWithImpl<$Res>
    implements $EnquiryCopyWith<$Res> {
  _$EnquiryCopyWithImpl(this._self, this._then);

  final Enquiry _self;
  final $Res Function(Enquiry) _then;

/// Create a copy of Enquiry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? propertyId = null,Object? checkIn = null,Object? checkOut = null,Object? guestCount = null,Object? guestName = null,Object? guestContact = null,Object? message = freezed,Object? status = null,Object? ownerResponse = freezed,Object? seenAt = freezed,Object? respondedAt = freezed,Object? ownerReportedBookingAt = freezed,Object? guestReportedBookingAt = freezed,Object? createdAt = null,Object? propertyTitle = freezed,Object? listingNumber = freezed,Object? propertyCover = freezed,}) {
  return _then(Enquiry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,checkIn: null == checkIn ? _self.checkIn : checkIn // ignore: cast_nullable_to_non_nullable
as DateTime,checkOut: null == checkOut ? _self.checkOut : checkOut // ignore: cast_nullable_to_non_nullable
as DateTime,guestCount: null == guestCount ? _self.guestCount : guestCount // ignore: cast_nullable_to_non_nullable
as int,guestName: null == guestName ? _self.guestName : guestName // ignore: cast_nullable_to_non_nullable
as String,guestContact: null == guestContact ? _self.guestContact : guestContact // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EnquiryStatus,ownerResponse: freezed == ownerResponse ? _self.ownerResponse : ownerResponse // ignore: cast_nullable_to_non_nullable
as String?,seenAt: freezed == seenAt ? _self.seenAt : seenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,ownerReportedBookingAt: freezed == ownerReportedBookingAt ? _self.ownerReportedBookingAt : ownerReportedBookingAt // ignore: cast_nullable_to_non_nullable
as DateTime?,guestReportedBookingAt: freezed == guestReportedBookingAt ? _self.guestReportedBookingAt : guestReportedBookingAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,propertyTitle: freezed == propertyTitle ? _self.propertyTitle : propertyTitle // ignore: cast_nullable_to_non_nullable
as String?,listingNumber: freezed == listingNumber ? _self.listingNumber : listingNumber // ignore: cast_nullable_to_non_nullable
as int?,propertyCover: freezed == propertyCover ? _self.propertyCover : propertyCover // ignore: cast_nullable_to_non_nullable
as PropertyImage?,
  ));
}
/// Create a copy of Enquiry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PropertyImageCopyWith<$Res>? get propertyCover {
    if (_self.propertyCover == null) {
    return null;
  }

  return $PropertyImageCopyWith<$Res>(_self.propertyCover!, (value) {
    return _then(_self.copyWith(propertyCover: value));
  });
}
}


/// Adds pattern-matching-related methods to [Enquiry].
extension EnquiryPatterns on Enquiry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Enquiry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Enquiry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Enquiry value)  $default,){
final _that = this;
switch (_that) {
case _Enquiry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Enquiry value)?  $default,){
final _that = this;
switch (_that) {
case _Enquiry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String propertyId,  DateTime checkIn,  DateTime checkOut,  int guestCount,  String guestName,  String guestContact,  String? message,  EnquiryStatus status,  String? ownerResponse,  DateTime? seenAt,  DateTime? respondedAt,  DateTime? ownerReportedBookingAt,  DateTime? guestReportedBookingAt,  DateTime createdAt,  String? propertyTitle,  int? listingNumber,  PropertyImage? propertyCover)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Enquiry() when $default != null:
return $default(_that.id,_that.propertyId,_that.checkIn,_that.checkOut,_that.guestCount,_that.guestName,_that.guestContact,_that.message,_that.status,_that.ownerResponse,_that.seenAt,_that.respondedAt,_that.ownerReportedBookingAt,_that.guestReportedBookingAt,_that.createdAt,_that.propertyTitle,_that.listingNumber,_that.propertyCover);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String propertyId,  DateTime checkIn,  DateTime checkOut,  int guestCount,  String guestName,  String guestContact,  String? message,  EnquiryStatus status,  String? ownerResponse,  DateTime? seenAt,  DateTime? respondedAt,  DateTime? ownerReportedBookingAt,  DateTime? guestReportedBookingAt,  DateTime createdAt,  String? propertyTitle,  int? listingNumber,  PropertyImage? propertyCover)  $default,) {final _that = this;
switch (_that) {
case _Enquiry():
return $default(_that.id,_that.propertyId,_that.checkIn,_that.checkOut,_that.guestCount,_that.guestName,_that.guestContact,_that.message,_that.status,_that.ownerResponse,_that.seenAt,_that.respondedAt,_that.ownerReportedBookingAt,_that.guestReportedBookingAt,_that.createdAt,_that.propertyTitle,_that.listingNumber,_that.propertyCover);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String propertyId,  DateTime checkIn,  DateTime checkOut,  int guestCount,  String guestName,  String guestContact,  String? message,  EnquiryStatus status,  String? ownerResponse,  DateTime? seenAt,  DateTime? respondedAt,  DateTime? ownerReportedBookingAt,  DateTime? guestReportedBookingAt,  DateTime createdAt,  String? propertyTitle,  int? listingNumber,  PropertyImage? propertyCover)?  $default,) {final _that = this;
switch (_that) {
case _Enquiry() when $default != null:
return $default(_that.id,_that.propertyId,_that.checkIn,_that.checkOut,_that.guestCount,_that.guestName,_that.guestContact,_that.message,_that.status,_that.ownerResponse,_that.seenAt,_that.respondedAt,_that.ownerReportedBookingAt,_that.guestReportedBookingAt,_that.createdAt,_that.propertyTitle,_that.listingNumber,_that.propertyCover);case _:
  return null;

}
}

}

/// @nodoc


class _Enquiry extends Enquiry {
  const _Enquiry({required this.id, required this.propertyId, required this.checkIn, required this.checkOut, required this.guestCount, required this.guestName, required this.guestContact, this.message, required this.status, this.ownerResponse, this.seenAt, this.respondedAt, this.ownerReportedBookingAt, this.guestReportedBookingAt, required this.createdAt, this.propertyTitle, this.listingNumber, this.propertyCover}): super._();
  

@override final  String id;
@override final  String propertyId;
@override final  DateTime checkIn;
@override final  DateTime checkOut;
@override final  int guestCount;
@override final  String guestName;
@override final  String guestContact;
@override final  String? message;
@override final  EnquiryStatus status;
@override final  String? ownerResponse;
@override final  DateTime? seenAt;
@override final  DateTime? respondedAt;
@override final  DateTime? ownerReportedBookingAt;
@override final  DateTime? guestReportedBookingAt;
@override final  DateTime createdAt;
@override final  String? propertyTitle;
@override final  int? listingNumber;
@override final  PropertyImage? propertyCover;

/// Create a copy of Enquiry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnquiryCopyWith<_Enquiry> get copyWith => __$EnquiryCopyWithImpl<_Enquiry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Enquiry&&(identical(other.id, id) || other.id == id)&&(identical(other.propertyId, propertyId) || other.propertyId == propertyId)&&(identical(other.checkIn, checkIn) || other.checkIn == checkIn)&&(identical(other.checkOut, checkOut) || other.checkOut == checkOut)&&(identical(other.guestCount, guestCount) || other.guestCount == guestCount)&&(identical(other.guestName, guestName) || other.guestName == guestName)&&(identical(other.guestContact, guestContact) || other.guestContact == guestContact)&&(identical(other.message, message) || other.message == message)&&(identical(other.status, status) || other.status == status)&&(identical(other.ownerResponse, ownerResponse) || other.ownerResponse == ownerResponse)&&(identical(other.seenAt, seenAt) || other.seenAt == seenAt)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt)&&(identical(other.ownerReportedBookingAt, ownerReportedBookingAt) || other.ownerReportedBookingAt == ownerReportedBookingAt)&&(identical(other.guestReportedBookingAt, guestReportedBookingAt) || other.guestReportedBookingAt == guestReportedBookingAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.propertyTitle, propertyTitle) || other.propertyTitle == propertyTitle)&&(identical(other.listingNumber, listingNumber) || other.listingNumber == listingNumber)&&(identical(other.propertyCover, propertyCover) || other.propertyCover == propertyCover));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,propertyId,checkIn,checkOut,guestCount,guestName,guestContact,message,status,ownerResponse,seenAt,respondedAt,ownerReportedBookingAt,guestReportedBookingAt,createdAt,propertyTitle,listingNumber,propertyCover);
}

@override
String toString() {
    return 'Enquiry(id: $id, propertyId: $propertyId, checkIn: $checkIn, checkOut: $checkOut, guestCount: $guestCount, guestName: $guestName, guestContact: $guestContact, message: $message, status: $status, ownerResponse: $ownerResponse, seenAt: $seenAt, respondedAt: $respondedAt, ownerReportedBookingAt: $ownerReportedBookingAt, guestReportedBookingAt: $guestReportedBookingAt, createdAt: $createdAt, propertyTitle: $propertyTitle, listingNumber: $listingNumber, propertyCover: $propertyCover)';
}


}

/// @nodoc
abstract mixin class _$EnquiryCopyWith<$Res> implements $EnquiryCopyWith<$Res> {
  factory _$EnquiryCopyWith(_Enquiry value, $Res Function(_Enquiry) _then) = __$EnquiryCopyWithImpl;
@override @useResult
$Res call({
 String id, String propertyId, DateTime checkIn, DateTime checkOut, int guestCount, String guestName, String guestContact, String? message, EnquiryStatus status, String? ownerResponse, DateTime? seenAt, DateTime? respondedAt, DateTime? ownerReportedBookingAt, DateTime? guestReportedBookingAt, DateTime createdAt, String? propertyTitle, int? listingNumber, PropertyImage? propertyCover
});


@override $PropertyImageCopyWith<$Res>? get propertyCover;

}
/// @nodoc
class __$EnquiryCopyWithImpl<$Res>
    implements _$EnquiryCopyWith<$Res> {
  __$EnquiryCopyWithImpl(this._self, this._then);

  final _Enquiry _self;
  final $Res Function(_Enquiry) _then;

/// Create a copy of Enquiry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? propertyId = null,Object? checkIn = null,Object? checkOut = null,Object? guestCount = null,Object? guestName = null,Object? guestContact = null,Object? message = freezed,Object? status = null,Object? ownerResponse = freezed,Object? seenAt = freezed,Object? respondedAt = freezed,Object? ownerReportedBookingAt = freezed,Object? guestReportedBookingAt = freezed,Object? createdAt = null,Object? propertyTitle = freezed,Object? listingNumber = freezed,Object? propertyCover = freezed,}) {
  return _then(_Enquiry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,propertyId: null == propertyId ? _self.propertyId : propertyId // ignore: cast_nullable_to_non_nullable
as String,checkIn: null == checkIn ? _self.checkIn : checkIn // ignore: cast_nullable_to_non_nullable
as DateTime,checkOut: null == checkOut ? _self.checkOut : checkOut // ignore: cast_nullable_to_non_nullable
as DateTime,guestCount: null == guestCount ? _self.guestCount : guestCount // ignore: cast_nullable_to_non_nullable
as int,guestName: null == guestName ? _self.guestName : guestName // ignore: cast_nullable_to_non_nullable
as String,guestContact: null == guestContact ? _self.guestContact : guestContact // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as EnquiryStatus,ownerResponse: freezed == ownerResponse ? _self.ownerResponse : ownerResponse // ignore: cast_nullable_to_non_nullable
as String?,seenAt: freezed == seenAt ? _self.seenAt : seenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,ownerReportedBookingAt: freezed == ownerReportedBookingAt ? _self.ownerReportedBookingAt : ownerReportedBookingAt // ignore: cast_nullable_to_non_nullable
as DateTime?,guestReportedBookingAt: freezed == guestReportedBookingAt ? _self.guestReportedBookingAt : guestReportedBookingAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,propertyTitle: freezed == propertyTitle ? _self.propertyTitle : propertyTitle // ignore: cast_nullable_to_non_nullable
as String?,listingNumber: freezed == listingNumber ? _self.listingNumber : listingNumber // ignore: cast_nullable_to_non_nullable
as int?,propertyCover: freezed == propertyCover ? _self.propertyCover : propertyCover // ignore: cast_nullable_to_non_nullable
as PropertyImage?,
  ));
}

/// Create a copy of Enquiry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PropertyImageCopyWith<$Res>? get propertyCover {
    if (_self.propertyCover == null) {
    return null;
  }

  return $PropertyImageCopyWith<$Res>(_self.propertyCover!, (value) {
    return _then(_self.copyWith(propertyCover: value));
  });
}
}

// dart format on
