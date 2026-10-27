import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patastay_core/patastay_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Parsed result of the admin_platform_stats() RPC.
class PlatformStats {
  const PlatformStats(this._json);

  final Map<String, dynamic> _json;

  int _int(String key) => (_json[key] as num?)?.toInt() ?? 0;

  int get periodDays => _int('period_days');
  int get usersTotal => _int('users_total');
  int get ownersTotal => _int('owners_total');
  int get usersNew => _int('users_new');
  int get listingsVerified => _int('listings_verified');
  int get listingsFeatured => _int('listings_featured');
  int get listingsStale => _int('listings_stale');
  int get views => _int('views');
  int get contactClicks => _int('contact_clicks');
  int get enquiries => _int('enquiries');
  int get enquiriesResponded => _int('enquiries_responded');
  int get bookingsReported => _int('bookings_reported');
  int get bookingsConfirmedByBoth => _int('bookings_confirmed_by_both');
  int get reportsOpen => _int('reports_open');
  int get listingsPending => _int('listings_pending');
  int get deletionRequests => _int('deletion_requests');
  DateTime? get pendingOldestSubmittedAt => _date('pending_oldest_submitted_at');
  DateTime? get deletionOldestRequestedAt => _date('deletion_oldest_requested_at');

  DateTime? _date(String key) => _json[key] == null ? null : DateTime.parse(_json[key] as String);
  num get promotionRevenueKes => (_json['promotion_revenue_kes'] as num?) ?? 0;

  /// Excludes development seed listings.
  int listingsWithStatus(PropertyStatus status) =>
      ((_json['listings_by_status'] as Map?)?[status.dbValue] as num?)?.toInt() ?? 0;
}

class AdminStatsRepository {
  AdminStatsRepository(this._client);

  final SupabaseClient _client;

  Future<PlatformStats> fetch({required int days}) {
    return guard('admin.platformStats', () async {
      final result = await _client.rpc<Map<String, dynamic>>('admin_platform_stats', params: {'p_days': days});
      return PlatformStats(result);
    });
  }
}

final adminStatsRepositoryProvider = Provider<AdminStatsRepository>(
  (ref) => AdminStatsRepository(ref.watch(supabaseClientProvider)),
);

final platformStatsProvider = FutureProvider.family<PlatformStats, int>(
  (ref, days) => ref.watch(adminStatsRepositoryProvider).fetch(days: days),
);
