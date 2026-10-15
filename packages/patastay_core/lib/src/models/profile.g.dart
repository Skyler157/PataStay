// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Profile _$ProfileFromJson(Map<String, dynamic> json) => _Profile(
  id: json['id'] as String,
  fullName: json['full_name'] as String? ?? '',
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']) ?? UserRole.guest,
  accountStatus:
      $enumDecodeNullable(_$AccountStatusEnumMap, json['account_status']) ??
      AccountStatus.active,
  suspendedReason: json['suspended_reason'] as String?,
  deletionRequestedAt: json['deletion_requested_at'] == null
      ? null
      : DateTime.parse(json['deletion_requested_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ProfileToJson(_Profile instance) => <String, dynamic>{
  'id': instance.id,
  'full_name': instance.fullName,
  'email': instance.email,
  'phone': instance.phone,
  'role': _$UserRoleEnumMap[instance.role]!,
  'account_status': _$AccountStatusEnumMap[instance.accountStatus]!,
  'suspended_reason': instance.suspendedReason,
  'deletion_requested_at': instance.deletionRequestedAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

const _$UserRoleEnumMap = {
  UserRole.guest: 'guest',
  UserRole.owner: 'owner',
  UserRole.admin: 'admin',
};

const _$AccountStatusEnumMap = {
  AccountStatus.active: 'active',
  AccountStatus.suspended: 'suspended',
};
