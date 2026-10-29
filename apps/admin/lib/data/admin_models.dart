import 'package:patastay_core/patastay_core.dart';

DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);

/// Count from a PostgREST `relation(count)` embed.
int _count(Object? embed) {
  if (embed is List && embed.isNotEmpty) return ((embed.first as Map)['count'] as num?)?.toInt() ?? 0;
  return 0;
}

/// Columns that make up a [Profile] row.
const profileColumns =
    'id, full_name, email, phone, role, account_status, suspended_reason, deletion_requested_at, created_at, updated_at';

/// A listing as an administrator sees it: everything the host sees plus the
/// owner and activity counts.
class AdminListing {
  const AdminListing({
    required this.listing,
    this.owner,
    this.enquiryCount = 0,
    this.reportCount = 0,
    this.featuredUntil,
    this.risks = const [],
  });

  final HostListing listing;
  final Profile? owner;
  final int enquiryCount;
  final int reportCount;
  final DateTime? featuredUntil;

  /// Warning signs, most serious first.
  final List<RiskSignal> risks;

  bool get hasHighRisk => risks.any((r) => r.high);

  AdminListing withRisks(List<RiskSignal> risks) => AdminListing(
        listing: listing,
        owner: owner,
        enquiryCount: enquiryCount,
        reportCount: reportCount,
        featuredUntil: featuredUntil,
        risks: [...risks.where((r) => r.high), ...risks.where((r) => !r.high)],
      );

  String get id => listing.id;
  Property get property => listing.property;
  PropertyStatus get status => listing.status;

  static AdminListing fromRow(Map<String, dynamic> row) {
    final owner = row['owner'];
    return AdminListing(
      listing: HostListing.fromRow(row),
      owner: owner is Map<String, dynamic> ? Profile.fromJson(owner) : null,
      enquiryCount: _count(row['enquiries']),
      reportCount: _count(row['property_reports']),
      featuredUntil: _date(row['featured_until']),
    );
  }
}

class AdminUser {
  const AdminUser({required this.profile, this.listingCount = 0});

  final Profile profile;
  final int listingCount;

  /// The app promises deletion within 30 days of the request.
  DateTime? get deletionDueBy => profile.deletionRequestedAt?.add(const Duration(days: 30));

  /// Whole days left before [deletionDueBy], counting a part day as a day.
  int? deletionDaysLeft({DateTime? now}) {
    final due = deletionDueBy;
    if (due == null) return null;
    return (due.difference(now ?? DateTime.now()).inMinutes / (24 * 60)).ceil();
  }

  static AdminUser fromRow(Map<String, dynamic> row) =>
      AdminUser(profile: Profile.fromJson(row), listingCount: _count(row['properties']));
}

enum ReportStatus {
  open('open', 'Open'),
  investigating('investigating', 'Investigating'),
  resolved('resolved', 'Resolved'),
  dismissed('dismissed', 'Dismissed');

  const ReportStatus(this.dbValue, this.label);
  final String dbValue;
  final String label;

  bool get isActive => this == open || this == investigating;
}

class AdminReport {
  const AdminReport({
    required this.id,
    required this.propertyId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.description,
    this.resolutionNote,
    this.resolvedAt,
    this.listingNumber,
    this.propertyTitle,
    this.propertyStatus,
    this.reporterName,
    this.reporterEmail,
  });

  final String id;
  final String propertyId;
  final ReportReason reason;
  final ReportStatus status;
  final DateTime createdAt;
  final String? description;
  final String? resolutionNote;
  final DateTime? resolvedAt;
  final int? listingNumber;
  final String? propertyTitle;
  final PropertyStatus? propertyStatus;
  final String? reporterName;
  final String? reporterEmail;

  String get reference => listingNumber == null ? 'Listing' : 'PS-$listingNumber';

  static AdminReport fromRow(Map<String, dynamic> row) {
    final property = row['properties'] as Map<String, dynamic>?;
    final reporter = row['reporter'] as Map<String, dynamic>?;
    return AdminReport(
      id: row['id'] as String,
      propertyId: row['property_id'] as String,
      reason: ReportReason.values.firstWhere((r) => r.dbValue == row['reason'], orElse: () => ReportReason.other),
      status: ReportStatus.values.firstWhere((s) => s.dbValue == row['status'], orElse: () => ReportStatus.open),
      createdAt: DateTime.parse(row['created_at'] as String),
      description: row['description'] as String?,
      resolutionNote: row['resolution_note'] as String?,
      resolvedAt: _date(row['resolved_at']),
      listingNumber: (property?['listing_number'] as num?)?.toInt(),
      propertyTitle: property?['title'] as String?,
      propertyStatus: property == null
          ? null
          : PropertyStatus.values.firstWhere((s) => s.dbValue == property['status'], orElse: () => PropertyStatus.draft),
      reporterName: reporter?['full_name'] as String?,
      reporterEmail: reporter?['email'] as String?,
    );
  }
}

enum VerificationCheckType {
  ownerIdentity('owner_identity', 'Owner identity', 'National ID or passport matches the host', required: true),
  ownershipOrAuthority('ownership_or_authority', 'Right to let', 'Title deed, lease or written authority from the owner',
      required: true),
  siteVisit('site_visit', 'Site visit', 'Someone from PataStay visited the place'),
  videoWalkthrough('video_walkthrough', 'Video walkthrough', 'Live video call walking through the place'),
  photoAuthenticity('photo_authenticity', 'Photos are genuine', 'Photos match the place and are not copied'),
  contactVerified('contact_verified', 'Contact number', 'The number reaches the host'),
  priceConfirmed('price_confirmed', 'Price confirmed', 'The host confirmed the listed price and fees');

  const VerificationCheckType(this.dbValue, this.label, this.hint, {this.required = false});
  final String dbValue;
  final String label;
  final String hint;

  /// Identity and authority are always required; a site visit or a video
  /// walkthrough is also required (either one).
  final bool required;
}

enum VerificationResult {
  pass('pass', 'Passed'),
  fail('fail', 'Failed'),
  inconclusive('inconclusive', 'Inconclusive');

  const VerificationResult(this.dbValue, this.label);
  final String dbValue;
  final String label;
}

class VerificationCheck {
  const VerificationCheck({
    required this.id,
    required this.type,
    required this.result,
    required this.checkedAt,
    this.notes,
    this.adminName,
  });

  final String id;
  final VerificationCheckType type;
  final VerificationResult result;
  final DateTime checkedAt;
  final String? notes;
  final String? adminName;

  static VerificationCheck fromRow(Map<String, dynamic> row) => VerificationCheck(
        id: row['id'] as String,
        type: VerificationCheckType.values.firstWhere((t) => t.dbValue == row['check_type']),
        result: VerificationResult.values.firstWhere((r) => r.dbValue == row['result']),
        checkedAt: DateTime.parse(row['checked_at'] as String),
        notes: row['notes'] as String?,
        adminName: (row['profiles'] as Map<String, dynamic>?)?['full_name'] as String?,
      );
}

/// The latest result per check type decides; mirrors
/// admin_set_property_verified(), which remains the source of truth.
class VerificationSummary {
  VerificationSummary(List<VerificationCheck> checks) {
    for (final c in checks) {
      final current = latest[c.type];
      if (current == null || c.checkedAt.isAfter(current.checkedAt)) latest[c.type] = c;
    }
  }

  final Map<VerificationCheckType, VerificationCheck> latest = {};

  bool passed(VerificationCheckType t) => latest[t]?.result == VerificationResult.pass;

  List<String> get missing => [
        if (!passed(VerificationCheckType.ownerIdentity)) 'Owner identity',
        if (!passed(VerificationCheckType.ownershipOrAuthority)) 'Right to let',
        if (!passed(VerificationCheckType.siteVisit) && !passed(VerificationCheckType.videoWalkthrough))
          'A site visit or video walkthrough',
      ];

  bool get canVerify => missing.isEmpty;
}

class StatusChange {
  const StatusChange({required this.toStatus, required this.createdAt, this.fromStatus, this.reason, this.changedByName});

  final PropertyStatus? fromStatus;
  final PropertyStatus toStatus;
  final DateTime createdAt;
  final String? reason;
  final String? changedByName;

  static PropertyStatus? _status(Object? v) =>
      v == null ? null : PropertyStatus.values.firstWhere((s) => s.dbValue == v, orElse: () => PropertyStatus.draft);

  static StatusChange fromRow(Map<String, dynamic> row) => StatusChange(
        fromStatus: _status(row['from_status']),
        toStatus: _status(row['to_status'])!,
        createdAt: DateTime.parse(row['created_at'] as String),
        reason: row['reason'] as String?,
        changedByName: (row['profiles'] as Map<String, dynamic>?)?['full_name'] as String?,
      );
}

class DeletionRecord {
  const DeletionRecord({required this.role, required this.processedAt, this.requestedAt, this.listingsRemoved = 0});

  final UserRole role;
  final DateTime processedAt;
  final DateTime? requestedAt;
  final int listingsRemoved;

  static DeletionRecord fromRow(Map<String, dynamic> row) => DeletionRecord(
        role: UserRole.values.firstWhere((r) => r.dbValue == row['role'], orElse: () => UserRole.guest),
        processedAt: DateTime.parse(row['processed_at'] as String),
        requestedAt: _date(row['requested_at']),
        listingsRemoved: (row['listings_removed'] as num?)?.toInt() ?? 0,
      );
}

/// Filters for the users page.
enum UserFilter {
  all('Everyone'),
  hosts('Hosts'),
  guests('Guests'),
  admins('Admins'),
  suspended('Suspended'),
  deletionRequested('Deletion requested');

  const UserFilter(this.label);
  final String label;
}

/// A reason to look closer at a listing (from admin_listing_risks()).
class RiskSignal {
  const RiskSignal({required this.code, required this.high, required this.message});

  final String code;
  final bool high;
  final String message;

  static RiskSignal fromRow(Map<String, dynamic> row) => RiskSignal(
        code: row['code'] as String,
        high: row['severity'] == 'high',
        message: row['message'] as String,
      );
}

/// A live listing whose host has not confirmed availability recently.
class StaleListing {
  const StaleListing({
    required this.propertyId,
    required this.listingNumber,
    required this.title,
    this.isSeed = false,
    this.confirmedAt,
    this.hostName,
    this.hostWhatsapp,
    this.lastNudgedAt,
  });

  final String propertyId;
  final int listingNumber;
  final String title;
  final bool isSeed;
  final DateTime? confirmedAt;
  final String? hostName;
  final String? hostWhatsapp;
  final DateTime? lastNudgedAt;

  String get reference => 'PS-$listingNumber';

  static StaleListing fromRow(Map<String, dynamic> r) => StaleListing(
        propertyId: r['property_id'] as String,
        listingNumber: (r['listing_number'] as num).toInt(),
        title: r['title'] as String? ?? '',
        isSeed: r['is_seed'] as bool? ?? false,
        confirmedAt: _date(r['confirmed_at']),
        hostName: r['host_name'] as String?,
        hostWhatsapp: r['host_whatsapp'] as String?,
        lastNudgedAt: _date(r['last_nudged_at']),
      );
}

/// An enquiry the host has not answered within a day.
class UnansweredEnquiry {
  const UnansweredEnquiry({
    required this.enquiryId,
    required this.propertyId,
    required this.listingNumber,
    required this.title,
    required this.createdAt,
    required this.checkIn,
    required this.checkOut,
    this.guestCount = 1,
    this.hostName,
    this.hostWhatsapp,
    this.lastNudgedAt,
  });

  final String enquiryId;
  final String propertyId;
  final int listingNumber;
  final String title;
  final DateTime createdAt;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guestCount;
  final String? hostName;
  final String? hostWhatsapp;
  final DateTime? lastNudgedAt;

  String get reference => 'PS-$listingNumber';

  static UnansweredEnquiry fromRow(Map<String, dynamic> r) => UnansweredEnquiry(
        enquiryId: r['enquiry_id'] as String,
        propertyId: r['property_id'] as String,
        listingNumber: (r['listing_number'] as num).toInt(),
        title: r['title'] as String? ?? '',
        createdAt: DateTime.parse(r['created_at'] as String),
        checkIn: DateTime.parse(r['check_in'] as String),
        checkOut: DateTime.parse(r['check_out'] as String),
        guestCount: (r['guest_count'] as num?)?.toInt() ?? 1,
        hostName: r['host_name'] as String?,
        hostWhatsapp: r['host_whatsapp'] as String?,
        lastNudgedAt: _date(r['last_nudged_at']),
      );
}

class FollowUps {
  const FollowUps({this.stale = const [], this.unanswered = const []});

  final List<StaleListing> stale;
  final List<UnansweredEnquiry> unanswered;

  int get total => stale.length + unanswered.length;

  static FollowUps fromJson(Map<String, dynamic> json) => FollowUps(
        stale: ((json['stale'] as List?) ?? const []).cast<Map<String, dynamic>>().map(StaleListing.fromRow).toList(),
        unanswered: ((json['unanswered'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(UnansweredEnquiry.fromRow)
            .toList(),
      );
}

/// A neighbourhood as admins manage it, including hidden ones.
class AdminArea {
  const AdminArea({
    required this.id,
    required this.name,
    required this.slug,
    this.city = 'Nairobi',
    this.county,
    this.latitude,
    this.longitude,
    this.isPopular = false,
    this.isActive = true,
    this.sortOrder = 0,
    this.listingCount = 0,
  });

  final String id;
  final String name;
  final String slug;
  final String city;
  final String? county;
  final double? latitude;
  final double? longitude;
  final bool isPopular;
  final bool isActive;
  final int sortOrder;
  final int listingCount;

  static AdminArea fromRow(Map<String, dynamic> r) => AdminArea(
        id: r['id'] as String,
        name: r['name'] as String,
        slug: r['slug'] as String,
        city: r['city'] as String? ?? 'Nairobi',
        county: r['county'] as String?,
        latitude: (r['latitude'] as num?)?.toDouble(),
        longitude: (r['longitude'] as num?)?.toDouble(),
        isPopular: r['is_popular'] as bool? ?? false,
        isActive: r['is_active'] as bool? ?? true,
        sortOrder: (r['sort_order'] as num?)?.toInt() ?? 0,
        listingCount: _count(r['properties']),
      );
}

class AdminAmenity {
  const AdminAmenity({
    required this.id,
    required this.name,
    required this.slug,
    this.category = 'general',
    this.icon,
    this.isKey = false,
    this.isActive = true,
    this.sortOrder = 0,
    this.listingCount = 0,
  });

  final String id;
  final String name;
  final String slug;
  final String category;
  final String? icon;
  final bool isKey;
  final bool isActive;
  final int sortOrder;
  final int listingCount;

  static const categories = ['essentials', 'comfort', 'building', 'safety', 'services', 'policies', 'general'];

  static AdminAmenity fromRow(Map<String, dynamic> r) => AdminAmenity(
        id: r['id'] as String,
        name: r['name'] as String,
        slug: r['slug'] as String,
        category: r['category'] as String? ?? 'general',
        icon: r['icon'] as String?,
        isKey: r['is_key'] as bool? ?? false,
        isActive: r['is_active'] as bool? ?? true,
        sortOrder: (r['sort_order'] as num?)?.toInt() ?? 0,
        listingCount: _count(r['property_amenities']),
      );
}

/// "Upper Hill" -> "upper-hill".
String slugify(String name) =>
    name.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
