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
  const AdminListing({required this.listing, this.owner, this.enquiryCount = 0, this.reportCount = 0, this.featuredUntil});

  final HostListing listing;
  final Profile? owner;
  final int enquiryCount;
  final int reportCount;
  final DateTime? featuredUntil;

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
