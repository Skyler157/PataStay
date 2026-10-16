import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'reference_data.dart';

part 'property.freezed.dart';

@freezed
abstract class PropertyImage with _$PropertyImage {
  const PropertyImage._();

  const factory PropertyImage({
    required String storagePath,
    String? thumbnailPath,
    @Default(0) int displayOrder,
    String? caption,
  }) = _PropertyImage;

  /// Development seed images have no real file; the UI shows a labelled placeholder.
  bool get isPlaceholder => storagePath.startsWith('seed/');

  static PropertyImage fromRow(Map<String, dynamic> row) => PropertyImage(
        storagePath: row['storage_path'] as String,
        thumbnailPath: row['thumbnail_path'] as String?,
        displayOrder: (row['display_order'] as num?)?.toInt() ?? 0,
        caption: row['caption'] as String?,
      );
}

@freezed
abstract class UnavailableRange with _$UnavailableRange {
  const factory UnavailableRange({required DateTime startsOn, required DateTime endsOn, String? note}) =
      _UnavailableRange;
}

/// A published listing as guests see it. Card queries fill the summary fields;
/// the details query also fills description, rules and availability.
@freezed
abstract class Property with _$Property {
  const Property._();

  const factory Property({
    required String id,
    required int listingNumber,
    required String title,
    PropertyType? propertyType,
    Neighbourhood? neighbourhood,

    /// Approximate public location (100–300 m from the real address).
    double? latitude,
    double? longitude,

    /// Distance from the guest for "Near me" results (approximate).
    double? distanceKm,
    required double nightlyRate,
    @Default(0) double cleaningFee,
    @Default(0) double refundableDeposit,
    int? bedrooms,
    double? bathrooms,
    int? maximumGuests,
    @Default(1) int minimumNights,
    DateTime? verifiedAt,
    DateTime? availabilityConfirmedAt,
    @Default(false) bool isFeatured,
    @Default(false) bool isSeed,
    required DateTime createdAt,
    @Default([]) List<PropertyImage> images,
    @Default([]) List<Amenity> amenities,
    // Details-only fields.
    @Default('') String description,
    String? addressOrAreaDescription,
    String? checkInTime,
    String? checkOutTime,
    String? checkInInformation,
    String? checkOutInformation,
    String? houseRules,
    String? availabilityNote,
    @Default([]) List<UnavailableRange> unavailableDates,
  }) = _Property;

  /// Public reference guests quote to hosts, e.g. PS-1001.
  String get reference => 'PS-$listingNumber';
  bool get isVerified => verifiedAt != null;
  bool get hasLocation => latitude != null && longitude != null;

  /// "About 1.2 km away" / "About 800 m away".
  String? get distanceLabel {
    final km = distanceKm;
    if (km == null) return null;
    if (km < 1) return 'About ${((km * 1000) / 100).round() * 100} m away';
    return 'About ${km < 10 ? km.toStringAsFixed(1) : km.round()} km away';
  }
  PropertyImage? get coverImage => images.isEmpty ? null : images.first;

  /// Key amenities, the ones worth showing on a compact card.
  List<Amenity> get keyAmenities => amenities.where((a) => a.isKey).toList();

  /// True when the host has not confirmed availability in [days] days.
  bool isStale({int days = 14, DateTime? now}) {
    final confirmed = availabilityConfirmedAt;
    if (confirmed == null) return true;
    return (now ?? DateTime.now()).difference(confirmed).inDays >= days;
  }

  String get roomsSummary {
    final parts = <String>[];
    if (bedrooms != null) parts.add(bedrooms == 0 ? 'Studio' : '$bedrooms bedroom${bedrooms == 1 ? '' : 's'}');
    if (maximumGuests != null) parts.add('$maximumGuests guest${maximumGuests == 1 ? '' : 's'}');
    if (bathrooms != null) {
      final b = bathrooms! % 1 == 0 ? bathrooms!.toInt().toString() : bathrooms!.toString();
      parts.add('$b bath${bathrooms == 1 ? '' : 's'}');
    }
    return parts.join(' · ');
  }

  bool isUnavailableOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return unavailableDates.any((r) => !d.isBefore(r.startsOn) && !d.isAfter(r.endsOn));
  }

  static Property fromRow(Map<String, dynamic> row) {
    final images = ((row['property_images'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(PropertyImage.fromRow)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final amenities = ((row['property_amenities'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map((r) => r['amenities'])
        .whereType<Map<String, dynamic>>()
        .map(Amenity.fromJson)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final unavailable = ((row['property_unavailable_dates'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map((r) => UnavailableRange(
              startsOn: DateTime.parse(r['starts_on'] as String),
              endsOn: DateTime.parse(r['ends_on'] as String),
              note: r['note'] as String?,
            ))
        .toList()
      ..sort((a, b) => a.startsOn.compareTo(b.startsOn));
    final hood = row['neighbourhoods'];

    DateTime? date(String key) => row[key] == null ? null : DateTime.parse(row[key] as String);
    double money(String key) => (row[key] as num?)?.toDouble() ?? 0;

    return Property(
      id: row['id'] as String,
      listingNumber: (row['listing_number'] as num).toInt(),
      title: row['title'] as String? ?? '',
      propertyType: PropertyType.values.where((t) => t.dbValue == row['property_type']).firstOrNull,
      neighbourhood: hood is Map<String, dynamic> ? Neighbourhood.fromJson(hood) : null,
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      nightlyRate: money('nightly_rate'),
      cleaningFee: money('cleaning_fee'),
      refundableDeposit: money('refundable_deposit'),
      bedrooms: (row['bedrooms'] as num?)?.toInt(),
      bathrooms: (row['bathrooms'] as num?)?.toDouble(),
      maximumGuests: (row['maximum_guests'] as num?)?.toInt(),
      minimumNights: (row['minimum_nights'] as num?)?.toInt() ?? 1,
      verifiedAt: date('verified_at'),
      availabilityConfirmedAt: date('availability_confirmed_at'),
      isFeatured: row['is_featured'] as bool? ?? false,
      isSeed: row['is_seed'] as bool? ?? false,
      createdAt: DateTime.parse(row['created_at'] as String),
      images: images,
      amenities: amenities,
      description: row['description'] as String? ?? '',
      addressOrAreaDescription: row['address_or_area_description'] as String?,
      checkInTime: row['check_in_time'] as String?,
      checkOutTime: row['check_out_time'] as String?,
      checkInInformation: row['check_in_information'] as String?,
      checkOutInformation: row['check_out_information'] as String?,
      houseRules: row['house_rules'] as String?,
      availabilityNote: row['availability_note'] as String?,
      unavailableDates: unavailable,
    );
  }
}

/// Public host details (first name only; never contact details).
@freezed
abstract class HostSummary with _$HostSummary {
  const factory HostSummary({
    required String displayName,
    required DateTime memberSince,
    @Default(0) int publishedListings,
    @Default(0) int verifiedListings,
  }) = _HostSummary;
}

class ContactDetails {
  const ContactDetails({required this.phone, required this.whatsappPhone});

  final String phone;
  final String whatsappPhone;
}
