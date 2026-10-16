import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/app_failure.dart';
import '../models/enquiry.dart';

/// Saved listings. RLS restricts every row to the signed-in user.
class FavouritesRepository {
  FavouritesRepository(this._client);

  final SupabaseClient _client;

  /// Property ids, most recently saved first.
  Future<List<String>> fetchIds(String userId) {
    return guard('favourites.list', () async {
      final rows = await _client
          .from('favourites')
          .select('property_id')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return rows.map((r) => r['property_id'] as String).toList();
    });
  }

  Future<void> add(String userId, String propertyId) {
    return guard('favourites.add', () async {
      await _client.from('favourites').upsert(
        {'user_id': userId, 'property_id': propertyId},
        onConflict: 'user_id,property_id',
        ignoreDuplicates: true,
      );
    });
  }

  Future<void> remove(String userId, String propertyId) {
    return guard('favourites.remove', () async {
      await _client.from('favourites').delete().eq('user_id', userId).eq('property_id', propertyId);
    });
  }
}

class EnquiryRepository {
  EnquiryRepository(this._client);

  final SupabaseClient _client;

  static const _columns = 'id, property_id, check_in, check_out, guest_count, guest_name, guest_contact, '
      'message, status, owner_response, seen_at, responded_at, owner_reported_booking_at, guest_reported_booking_at, created_at, '
      'properties(title, listing_number, property_images(storage_path, thumbnail_path, display_order))';

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// The server forces guest_id and status and validates dates, capacity,
  /// minimum stay and daily limits.
  Future<Enquiry> create({
    required String propertyId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guestCount,
    required String guestName,
    required String guestContact,
    String? message,
  }) {
    return guard('enquiries.create', () async {
      final row = await _client
          .from('enquiries')
          .insert({
            'property_id': propertyId,
            'check_in': _day(checkIn),
            'check_out': _day(checkOut),
            'guest_count': guestCount,
            'guest_name': guestName.trim(),
            'guest_contact': guestContact.trim(),
            'message': (message == null || message.trim().isEmpty) ? null : message.trim(),
          })
          .select(_columns)
          .single();
      return Enquiry.fromRow(row);
    });
  }

  /// The guest's own enquiries (RLS also lets hosts read theirs; filter by guest).
  Future<List<Enquiry>> fetchMine(String userId) {
    return guard('enquiries.mine', () async {
      final rows = await _client
          .from('enquiries')
          .select(_columns)
          .eq('guest_id', userId)
          .order('created_at', ascending: false)
          .limit(100);
      return rows.map(Enquiry.fromRow).toList();
    });
  }

  Future<void> cancel(String enquiryId) => _guestAction(enquiryId, 'cancel');

  /// Voluntary report that a stay was agreed; it is never inferred.
  Future<void> reportBooked(String enquiryId) => _guestAction(enquiryId, 'report_booked');

  Future<void> _guestAction(String enquiryId, String action) {
    return guard('enquiries.$action', () async {
      await _client.rpc<dynamic>('guest_update_enquiry', params: {'p_enquiry_id': enquiryId, 'p_action': action});
    });
  }
}

class ReportRepository {
  ReportRepository(this._client);

  final SupabaseClient _client;

  Future<void> report({required String propertyId, required ReportReason reason, String? description}) {
    return guard('reports.create', () async {
      try {
        await _client.from('property_reports').insert({
          'property_id': propertyId,
          'reason': reason.dbValue,
          'description': (description == null || description.trim().isEmpty) ? null : description.trim(),
        });
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          throw const ConflictFailure('You have already reported this listing. Our team is looking into it.');
        }
        rethrow;
      }
    });
  }
}
