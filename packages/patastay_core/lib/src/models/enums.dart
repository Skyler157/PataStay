import 'package:json_annotation/json_annotation.dart';

/// Enums mirror the PostgreSQL enum types. [dbValue] is the exact database
/// value and is also used when passing parameters to RPCs.

@JsonEnum(valueField: 'dbValue')
enum UserRole {
  guest('guest', 'Guest'),
  owner('owner', 'Host'),
  admin('admin', 'Administrator');

  const UserRole(this.dbValue, this.label);
  final String dbValue;
  final String label;
}

@JsonEnum(valueField: 'dbValue')
enum AccountStatus {
  active('active'),
  suspended('suspended');

  const AccountStatus(this.dbValue);
  final String dbValue;
}

@JsonEnum(valueField: 'dbValue')
enum PropertyType {
  studio('studio', 'Studio'),
  bedsitter('bedsitter', 'Bedsitter'),
  oneBedroom('one_bedroom', '1-bedroom'),
  twoBedroom('two_bedroom', '2-bedroom'),
  threeBedroomPlus('three_bedroom_plus', '3+ bedroom'),
  furnishedApartment('furnished_apartment', 'Furnished apartment'),
  servicedApartment('serviced_apartment', 'Serviced apartment'),
  guestHouse('guest_house', 'Guest house'),
  privateRoom('private_room', 'Private room'),
  house('house', 'Entire house');

  const PropertyType(this.dbValue, this.label);
  final String dbValue;
  final String label;
}

@JsonEnum(valueField: 'dbValue')
enum PropertyStatus {
  draft('draft', 'Draft'),
  pendingReview('pending_review', 'Pending review'),
  published('published', 'Published'),
  rejected('rejected', 'Needs changes'),
  paused('paused', 'Paused'),
  suspended('suspended', 'Suspended'),
  archived('archived', 'Archived');

  const PropertyStatus(this.dbValue, this.label);
  final String dbValue;
  final String label;
}

@JsonEnum(valueField: 'dbValue')
enum EnquiryStatus {
  newEnquiry('new', 'Sent'),
  seen('seen', 'Seen by host'),
  available('available', 'Host says available'),
  unavailable('unavailable', 'Not available'),
  cancelled('cancelled', 'Cancelled'),
  booked('booked', 'Stay agreed'),
  closed('closed', 'Closed');

  const EnquiryStatus(this.dbValue, this.label);
  final String dbValue;
  final String label;
}
