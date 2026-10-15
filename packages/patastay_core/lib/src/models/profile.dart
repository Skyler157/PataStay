import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
abstract class Profile with _$Profile {
  const Profile._();

  const factory Profile({
    required String id,
    @Default('') String fullName,
    String? email,
    String? phone,
    @Default(UserRole.guest) UserRole role,
    @Default(AccountStatus.active) AccountStatus accountStatus,
    String? suspendedReason,
    DateTime? deletionRequestedAt,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

  bool get isAdmin => role == UserRole.admin;
  bool get canHost => role == UserRole.owner || role == UserRole.admin;
  bool get isSuspended => accountStatus == AccountStatus.suspended;
  bool get hasRequestedDeletion => deletionRequestedAt != null;

  String get displayName {
    final name = fullName.trim();
    if (name.isNotEmpty) return name;
    return email ?? 'PataStay member';
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return (email ?? '?').substring(0, 1).toUpperCase();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
