import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/app_failure.dart';
import '../models/profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  static const _columns =
      'id, full_name, email, phone, role, account_status, suspended_reason, deletion_requested_at, created_at, updated_at';

  Future<Profile> fetchProfile(String userId) {
    return guard('profile.fetch', () async {
      final row = await _client.from('profiles').select(_columns).eq('id', userId).single();
      return Profile.fromJson(row);
    });
  }

  /// Only full_name and phone are writable by users (enforced by column grants).
  Future<Profile> updateProfile(String userId, {required String fullName, String? phone}) {
    return guard('profile.update', () async {
      final row = await _client
          .from('profiles')
          .update({'full_name': fullName.trim(), 'phone': phone})
          .eq('id', userId)
          .select(_columns)
          .single();
      return Profile.fromJson(row);
    });
  }

  /// Turns a guest account into a host account (cannot grant admin).
  Future<void> becomeOwner() => guard('profile.becomeOwner', () => _client.rpc<void>('become_owner'));

  /// Records a deletion request and immediately archives the user's listings.
  Future<void> requestAccountDeletion() {
    return guard('profile.requestDeletion', () => _client.rpc<void>('request_account_deletion'));
  }
}
