import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'property.dart';

part 'enquiry.freezed.dart';

@freezed
abstract class Enquiry with _$Enquiry {
  const Enquiry._();

  const factory Enquiry({
    required String id,
    required String propertyId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guestCount,
    required String guestName,
    required String guestContact,
    String? message,
    required EnquiryStatus status,
    String? ownerResponse,
    DateTime? seenAt,
    DateTime? respondedAt,
    DateTime? ownerReportedBookingAt,
    DateTime? guestReportedBookingAt,
    required DateTime createdAt,
    // Light listing details for the list view.
    String? propertyTitle,
    int? listingNumber,
    PropertyImage? propertyCover,
  }) = _Enquiry;

  int get nights => checkOut.difference(checkIn).inDays;
  String? get reference => listingNumber == null ? null : 'PS-$listingNumber';

  /// True when the host has answered (available / not available / booked).
  bool get hostReplied => respondedAt != null || ownerReportedBookingAt != null;

  bool get canCancel =>
      status != EnquiryStatus.cancelled && status != EnquiryStatus.booked && status != EnquiryStatus.closed;
  bool get canReportBooked =>
      guestReportedBookingAt == null && status != EnquiryStatus.cancelled && status != EnquiryStatus.unavailable;

  static Enquiry fromRow(Map<String, dynamic> row) {
    final property = row['properties'];
    PropertyImage? cover;
    int? number;
    String? title;
    if (property is Map<String, dynamic>) {
      title = property['title'] as String?;
      number = (property['listing_number'] as num?)?.toInt();
      final images = ((property['property_images'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(PropertyImage.fromRow)
          .toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      cover = images.firstOrNull;
    }
    DateTime? date(String key) => row[key] == null ? null : DateTime.parse(row[key] as String);
    return Enquiry(
      id: row['id'] as String,
      propertyId: row['property_id'] as String,
      checkIn: DateTime.parse(row['check_in'] as String),
      checkOut: DateTime.parse(row['check_out'] as String),
      guestCount: (row['guest_count'] as num).toInt(),
      guestName: row['guest_name'] as String,
      guestContact: row['guest_contact'] as String,
      message: row['message'] as String?,
      status: EnquiryStatus.values.firstWhere((s) => s.dbValue == row['status'], orElse: () => EnquiryStatus.newEnquiry),
      ownerResponse: row['owner_response'] as String?,
      seenAt: date('seen_at'),
      respondedAt: date('responded_at'),
      ownerReportedBookingAt: date('owner_reported_booking_at'),
      guestReportedBookingAt: date('guest_reported_booking_at'),
      createdAt: DateTime.parse(row['created_at'] as String),
      propertyTitle: title,
      listingNumber: number,
      propertyCover: cover,
    );
  }
}

enum ReportReason {
  scamOrFraud('scam_or_fraud', 'Scam or fraud', 'Asked for payment upfront, fake host, or the place does not exist'),
  misleadingPhotos('misleading_photos', 'Misleading photos', 'Photos are copied or do not match the place'),
  wrongPrice('wrong_price', 'Wrong price', 'The host asked for a different price or extra fees'),
  wrongLocation('wrong_location', 'Wrong location', 'The place is not in the area shown'),
  notAvailable('not_available', 'Not actually available', 'Shown as available but the host says it is not'),
  inappropriateContent('inappropriate_content', 'Inappropriate content', 'Offensive text or images'),
  other('other', 'Something else', 'Tell us what happened');

  const ReportReason(this.dbValue, this.label, this.hint);
  final String dbValue;
  final String label;
  final String hint;
}
