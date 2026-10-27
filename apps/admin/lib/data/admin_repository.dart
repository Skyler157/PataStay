import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patastay_core/patastay_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_models.dart';

/// Every administrator query and action. The database re-checks admin
/// rights on each call (RLS policies and assert_admin() in every RPC), so a
/// non-admin using this code gets nothing back and cannot change anything.
class AdminRepository {
  AdminRepository(this._client);

  final SupabaseClient _client;

  static const _listingColumns = 'id, listing_number, title, description, property_type, nightly_rate, cleaning_fee, '
      'refundable_deposit, bedrooms, bathrooms, maximum_guests, minimum_nights, verified_at, '
      'availability_confirmed_at, availability_note, is_featured, featured_until, is_seed, created_at, updated_at, '
      'latitude, longitude, address_or_area_description, check_in_time, check_out_time, '
      'check_in_information, check_out_information, house_rules, status, rejection_reason, '
      'submitted_at, approved_at, '
      'neighbourhoods(id, name, slug, latitude, longitude), '
      'property_images(id, storage_path, thumbnail_path, display_order, caption), '
      'property_amenities(amenities(id, name, slug, category, icon, is_key, sort_order)), '
      'property_unavailable_dates(id, starts_on, ends_on, note), '
      'property_contacts(phone, whatsapp_phone), '
      'property_locations(latitude, longitude), '
      'owner:profiles!properties_owner_id_fkey($profileColumns), '
      'enquiries(count), property_reports(count)';

  static const _reportColumns = 'id, property_id, reason, description, status, resolution_note, created_at, resolved_at, '
      'properties(listing_number, title, status), '
      'reporter:profiles!property_reports_reporter_id_fkey(full_name, email)';

  /// Removes characters that have meaning in PostgREST filter strings.
  static String _clean(String q) => q.replaceAll(RegExp(r'[,()*%\\]'), ' ').trim();

  // -------------------------------------------------------------------------
  // Listings
  // -------------------------------------------------------------------------

  /// Pending listings come oldest first (a queue); everything else by most
  /// recent change. [query] matches a PS-number or words in the title.
  Future<List<AdminListing>> fetchListings({PropertyStatus? status, String query = ''}) {
    return guard('admin.listings', () async {
      var filter = _client.from('properties').select(_listingColumns);
      if (status != null) filter = filter.eq('status', status.dbValue);
      final q = _clean(query);
      final number = int.tryParse(q.toUpperCase().replaceFirst(RegExp(r'^PS-?'), ''));
      if (number != null) {
        filter = filter.eq('listing_number', number);
      } else if (q.isNotEmpty) {
        filter = filter.ilike('title', '%$q%');
      }
      final rows = status == PropertyStatus.pendingReview
          ? await filter.order('submitted_at', ascending: true, nullsFirst: false).limit(200)
          : await filter.order('updated_at', ascending: false).limit(200);
      return rows.map(AdminListing.fromRow).toList();
    });
  }

  Future<AdminListing?> fetchListing(String id) {
    return guard('admin.listing', () async {
      final row = await _client.from('properties').select(_listingColumns).eq('id', id).maybeSingle();
      return row == null ? null : AdminListing.fromRow(row);
    });
  }

  Future<List<AdminListing>> fetchListingsOf(String ownerId) {
    return guard('admin.listingsOf', () async {
      final rows = await _client
          .from('properties')
          .select(_listingColumns)
          .eq('owner_id', ownerId)
          .order('updated_at', ascending: false);
      return rows.map(AdminListing.fromRow).toList();
    });
  }

  Future<List<StatusChange>> fetchHistory(String propertyId) {
    return guard('admin.history', () async {
      final rows = await _client
          .from('property_status_history')
          .select('from_status, to_status, reason, created_at, profiles(full_name)')
          .eq('property_id', propertyId)
          .order('created_at', ascending: false)
          .limit(50);
      return rows.map(StatusChange.fromRow).toList();
    });
  }

  Future<List<VerificationCheck>> fetchChecks(String propertyId) {
    return guard('admin.checks', () async {
      final rows = await _client
          .from('verification_checks')
          .select('id, check_type, result, notes, checked_at, profiles(full_name)')
          .eq('property_id', propertyId)
          .order('checked_at', ascending: false);
      return rows.map(VerificationCheck.fromRow).toList();
    });
  }

  Future<void> approve(String id, {String? note}) => guard('admin.approve',
      () => _client.rpc<void>('admin_approve_property', params: {'p_property_id': id, 'p_note': note}));

  Future<void> reject(String id, String reason) => guard('admin.reject',
      () => _client.rpc<void>('admin_reject_property', params: {'p_property_id': id, 'p_reason': reason}));

  Future<void> suspend(String id, String reason) => guard('admin.suspend',
      () => _client.rpc<void>('admin_suspend_property', params: {'p_property_id': id, 'p_reason': reason}));

  Future<void> reinstate(String id, {String? note}) => guard('admin.reinstate',
      () => _client.rpc<String>('admin_reinstate_property', params: {'p_property_id': id, 'p_note': note}));

  Future<void> setFeatured(String id, {required bool featured, DateTime? until, num amountKes = 0, String? notes}) {
    return guard('admin.featured', () => _client.rpc<void>('admin_set_featured', params: {
          'p_property_id': id,
          'p_featured': featured,
          'p_until': until?.toUtc().toIso8601String(),
          'p_amount_kes': amountKes,
          'p_notes': notes,
        }));
  }

  Future<void> recordCheck(String id, VerificationCheckType type, VerificationResult result, {String? notes}) {
    return guard('admin.recordCheck', () => _client.rpc<String>('admin_record_verification_check', params: {
          'p_property_id': id,
          'p_check_type': type.dbValue,
          'p_result': result.dbValue,
          'p_notes': notes,
        }));
  }

  Future<void> setVerified(String id, bool verified) => guard('admin.setVerified',
      () => _client.rpc<dynamic>('admin_set_property_verified', params: {'p_property_id': id, 'p_verified': verified}));

  // -------------------------------------------------------------------------
  // Reports
  // -------------------------------------------------------------------------

  Future<List<AdminReport>> fetchReports({bool activeOnly = true, String? propertyId}) {
    return guard('admin.reports', () async {
      var filter = _client.from('property_reports').select(_reportColumns);
      if (activeOnly) filter = filter.inFilter('status', ['open', 'investigating']);
      if (propertyId != null) filter = filter.eq('property_id', propertyId);
      final rows = await filter.order('created_at', ascending: !activeOnly).limit(200);
      return rows.map(AdminReport.fromRow).toList();
    });
  }

  Future<void> updateReport(String id, ReportStatus status, {String? note}) {
    return guard('admin.updateReport', () => _client.rpc<void>('admin_update_report',
        params: {'p_report_id': id, 'p_status': status.dbValue, 'p_note': note}));
  }

  // -------------------------------------------------------------------------
  // Users
  // -------------------------------------------------------------------------

  Future<List<AdminUser>> fetchUsers({UserFilter filter = UserFilter.all, String query = ''}) {
    return guard('admin.users', () async {
      var q = _client.from('profiles').select('$profileColumns, properties!properties_owner_id_fkey(count)');
      q = switch (filter) {
        UserFilter.all => q,
        UserFilter.hosts => q.eq('role', UserRole.owner.dbValue),
        UserFilter.guests => q.eq('role', UserRole.guest.dbValue),
        UserFilter.admins => q.eq('role', UserRole.admin.dbValue),
        UserFilter.suspended => q.eq('account_status', AccountStatus.suspended.dbValue),
        UserFilter.deletionRequested => q.not('deletion_requested_at', 'is', null),
      };
      final text = _clean(query);
      if (text.isNotEmpty) q = q.or('full_name.ilike.%$text%,email.ilike.%$text%,phone.ilike.%$text%');
      final rows = filter == UserFilter.deletionRequested
          ? await q.order('deletion_requested_at', ascending: true).limit(200)
          : await q.order('created_at', ascending: false).limit(200);
      return rows.map(AdminUser.fromRow).toList();
    });
  }

  Future<AdminUser?> fetchUser(String id) {
    return guard('admin.user', () async {
      final row = await _client
          .from('profiles')
          .select('$profileColumns, properties!properties_owner_id_fkey(count)')
          .eq('id', id)
          .maybeSingle();
      return row == null ? null : AdminUser.fromRow(row);
    });
  }

  Future<void> setRole(String userId, UserRole role) => guard('admin.setRole',
      () => _client.rpc<void>('admin_set_user_role', params: {'p_user_id': userId, 'p_role': role.dbValue}));

  Future<void> setAccountStatus(String userId, AccountStatus status, {String? reason}) {
    return guard('admin.setAccountStatus', () => _client.rpc<void>('admin_set_account_status',
        params: {'p_user_id': userId, 'p_status': status.dbValue, 'p_reason': reason}));
  }

  Future<void> cancelDeletion(String userId) => guard('admin.cancelDeletion',
      () => _client.rpc<void>('admin_cancel_account_deletion', params: {'p_user_id': userId}));

  /// Deletes the account and its data, then removes the listing photos from
  /// storage. Returns how many photo files could not be removed (they are
  /// unreachable once their rows are gone, so this is only reported).
  Future<int> processDeletion(String userId) {
    return guard('admin.processDeletion', () async {
      final result = await _client.rpc<List<dynamic>>('admin_process_account_deletion', params: {'p_user_id': userId});
      final paths = result.cast<String>();
      var failed = 0;
      for (var i = 0; i < paths.length; i += 100) {
        final batch = paths.sublist(i, i + 100 > paths.length ? paths.length : i + 100);
        try {
          await _client.storage.from(AppConfig.propertyImagesBucket).remove(batch);
        } catch (_) {
          failed += batch.length;
          AppLogger.info('admin.processDeletion: could not remove ${batch.length} photo files');
        }
      }
      return failed;
    });
  }

  Future<List<DeletionRecord>> fetchDeletionLog() {
    return guard('admin.deletionLog', () async {
      final rows = await _client
          .from('account_deletions')
          .select('role, requested_at, processed_at, listings_removed')
          .order('processed_at', ascending: false)
          .limit(100);
      return rows.map(DeletionRecord.fromRow).toList();
    });
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) => AdminRepository(ref.watch(supabaseClientProvider)));

typedef ListingQuery = ({PropertyStatus? status, String query});
typedef UserQuery = ({UserFilter filter, String query});

final adminListingsProvider = FutureProvider.autoDispose.family<List<AdminListing>, ListingQuery>(
  (ref, q) => ref.watch(adminRepositoryProvider).fetchListings(status: q.status, query: q.query),
);

final adminListingProvider = FutureProvider.autoDispose.family<AdminListing?, String>(
  (ref, id) => ref.watch(adminRepositoryProvider).fetchListing(id),
);

final adminListingsOfProvider = FutureProvider.autoDispose.family<List<AdminListing>, String>(
  (ref, ownerId) => ref.watch(adminRepositoryProvider).fetchListingsOf(ownerId),
);

final listingHistoryProvider = FutureProvider.autoDispose.family<List<StatusChange>, String>(
  (ref, id) => ref.watch(adminRepositoryProvider).fetchHistory(id),
);

final verificationChecksProvider = FutureProvider.autoDispose.family<List<VerificationCheck>, String>(
  (ref, id) => ref.watch(adminRepositoryProvider).fetchChecks(id),
);

final adminReportsProvider = FutureProvider.autoDispose.family<List<AdminReport>, bool>(
  (ref, activeOnly) => ref.watch(adminRepositoryProvider).fetchReports(activeOnly: activeOnly),
);

final listingReportsProvider = FutureProvider.autoDispose.family<List<AdminReport>, String>(
  (ref, id) => ref.watch(adminRepositoryProvider).fetchReports(activeOnly: false, propertyId: id),
);

final adminUsersProvider = FutureProvider.autoDispose.family<List<AdminUser>, UserQuery>(
  (ref, q) => ref.watch(adminRepositoryProvider).fetchUsers(filter: q.filter, query: q.query),
);

final adminUserProvider = FutureProvider.autoDispose.family<AdminUser?, String>(
  (ref, id) => ref.watch(adminRepositoryProvider).fetchUser(id),
);

final deletionLogProvider = FutureProvider.autoDispose<List<DeletionRecord>>(
  (ref) => ref.watch(adminRepositoryProvider).fetchDeletionLog(),
);
