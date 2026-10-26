import 'enums.dart';
import 'property.dart';

/// A listing as its host sees it: the public details plus status,
/// moderation feedback and the private contact number and exact pin.
class HostListing {
  const HostListing({
    required this.property,
    required this.status,
    this.rejectionReason,
    this.submittedAt,
    this.approvedAt,
    this.updatedAt,
    this.amenityIds = const {},
    this.contactPhone,
    this.whatsappPhone,
    this.exactLatitude,
    this.exactLongitude,
  });

  final Property property;
  final PropertyStatus status;

  /// Why an admin rejected or suspended the listing.
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final DateTime? updatedAt;
  final Set<String> amenityIds;

  /// Private: only the host and admins can read these.
  final String? contactPhone;
  final String? whatsappPhone;
  final double? exactLatitude;
  final double? exactLongitude;

  String get id => property.id;
  String get reference => property.reference;
  String get displayTitle => property.title.trim().isEmpty ? 'Untitled listing' : property.title;

  bool get hasExactLocation => exactLatitude != null && exactLongitude != null;
  bool get isLive => status == PropertyStatus.published;

  /// Hosts can edit anything except suspended or archived listings.
  bool get canEdit => status != PropertyStatus.suspended && status != PropertyStatus.archived;
  bool get canSubmit => status == PropertyStatus.draft || status == PropertyStatus.rejected;
  bool get canPause => status == PropertyStatus.published;
  bool get canResume => status == PropertyStatus.paused && approvedAt != null;

  /// Drafts and rejected listings that were never approved can be deleted.
  bool get canDelete => canSubmit && approvedAt == null;
  bool get canArchive => status != PropertyStatus.suspended && status != PropertyStatus.archived;

  static const minimumPhotos = 3;

  /// What is still needed before submission. Mirrors the checks in
  /// submit_property_for_review(), which remain the source of truth.
  List<String> get missingForSubmission {
    final p = property;
    return [
      if (p.title.trim().length < 10) 'A title of at least 10 characters',
      if (p.description.trim().length < 50) 'A description of at least 50 characters',
      if (p.propertyType == null) 'The type of place',
      if (p.neighbourhood == null) 'The neighbourhood',
      if (p.nightlyRate <= 0) 'The nightly rate',
      if (p.bedrooms == null) 'The number of bedrooms',
      if (p.bathrooms == null) 'The number of bathrooms',
      if (p.maximumGuests == null) 'The maximum number of guests',
      if (contactPhone == null || contactPhone!.isEmpty) 'A contact phone number',
      if (p.images.length < minimumPhotos)
        'At least $minimumPhotos photos (${p.images.length} added)',
    ];
  }

  bool get readyToSubmit => missingForSubmission.isEmpty;

  /// Rough progress for the dashboard: share of checklist items done.
  double get completeness {
    const total = 10;
    return (total - missingForSubmission.length) / total;
  }

  static HostListing fromRow(Map<String, dynamic> row) {
    final contact = row['property_contacts'];
    final location = row['property_locations'];
    final amenityIds = ((row['property_amenities'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map((r) => (r['amenities'] as Map<String, dynamic>?)?['id'] as String?)
        .whereType<String>()
        .toSet();
    DateTime? date(String key) => row[key] == null ? null : DateTime.parse(row[key] as String);
    return HostListing(
      property: Property.fromRow(row),
      status: PropertyStatus.values.firstWhere((s) => s.dbValue == row['status'], orElse: () => PropertyStatus.draft),
      rejectionReason: row['rejection_reason'] as String?,
      submittedAt: date('submitted_at'),
      approvedAt: date('approved_at'),
      updatedAt: date('updated_at'),
      amenityIds: amenityIds,
      contactPhone: contact is Map<String, dynamic> ? contact['phone'] as String? : null,
      whatsappPhone: contact is Map<String, dynamic> ? contact['whatsapp_phone'] as String? : null,
      exactLatitude: location is Map<String, dynamic> ? (location['latitude'] as num?)?.toDouble() : null,
      exactLongitude: location is Map<String, dynamic> ? (location['longitude'] as num?)?.toDouble() : null,
    );
  }
}

/// Per-listing counts from owner_listing_stats(). No personal data.
class ListingStats {
  const ListingStats({this.views = 0, this.contactClicks = 0, this.favourites = 0, this.enquiries = 0, this.newEnquiries = 0});

  final int views;
  final int contactClicks;
  final int favourites;
  final int enquiries;
  final int newEnquiries;

  static ListingStats fromRow(Map<String, dynamic> r) {
    int n(String k) => (r[k] as num?)?.toInt() ?? 0;
    return ListingStats(
      views: n('views'),
      contactClicks: n('contact_clicks'),
      favourites: n('favourites'),
      enquiries: n('enquiries'),
      newEnquiries: n('new_enquiries'),
    );
  }
}
