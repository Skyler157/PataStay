import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../errors/app_failure.dart';
import '../models/enquiry.dart';
import '../models/enums.dart';
import '../models/host_listing.dart';
import '../models/property.dart';

/// Everything a host does with their own listings and enquiries. RLS,
/// column grants and SECURITY DEFINER RPCs enforce ownership server-side;
/// nothing here relies on the app to keep hosts to their own data.
class HostRepository {
  HostRepository(this._client);

  final SupabaseClient _client;

  static const _columns = 'id, listing_number, title, description, property_type, nightly_rate, cleaning_fee, '
      'refundable_deposit, bedrooms, bathrooms, maximum_guests, minimum_nights, verified_at, '
      'availability_confirmed_at, availability_note, is_featured, is_seed, created_at, updated_at, '
      'latitude, longitude, address_or_area_description, check_in_time, check_out_time, '
      'check_in_information, check_out_information, house_rules, status, rejection_reason, '
      'submitted_at, approved_at, '
      'neighbourhoods(id, name, slug, latitude, longitude), '
      'property_images(id, storage_path, thumbnail_path, display_order, caption), '
      'property_amenities(amenities(id, name, slug, category, icon, is_key, sort_order)), '
      'property_unavailable_dates(id, starts_on, ends_on, note), '
      'property_contacts(phone, whatsapp_phone), '
      'property_locations(latitude, longitude)';

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<HostListing>> fetchMyListings(String ownerId) {
    return guard('host.listings', () async {
      final rows = await _client
          .from('properties')
          .select(_columns)
          .eq('owner_id', ownerId)
          .neq('status', PropertyStatus.archived.dbValue)
          .order('updated_at', ascending: false);
      return rows.map(HostListing.fromRow).toList();
    });
  }

  Future<HostListing?> fetchListing(String id) {
    return guard('host.listing', () async {
      final row = await _client.from('properties').select(_columns).eq('id', id).maybeSingle();
      return row == null ? null : HostListing.fromRow(row);
    });
  }

  /// Creates an empty draft and returns its id. Everything else is filled
  /// in step by step, so nothing is lost on a poor connection.
  Future<String> createDraft() {
    return guard('host.createDraft', () async {
      final row = await _client.from('properties').insert({'title': ''}).select('id').single();
      return row['id'] as String;
    });
  }

  /// Saves editable listing fields (keys are database column names). Status,
  /// verification and featuring are not writable by hosts.
  Future<void> saveDetails(String id, Map<String, dynamic> fields) {
    return guard('host.saveDetails', () async {
      await _client.from('properties').update(fields).eq('id', id);
    });
  }

  Future<void> saveContact(String id, {required String phone, String? whatsapp}) {
    return guard('host.saveContact', () async {
      await _client.from('property_contacts').upsert(
        {'property_id': id, 'phone': phone, 'whatsapp_phone': whatsapp ?? phone},
        onConflict: 'property_id',
      );
    });
  }

  /// Saves the exact pin privately; the database derives the public,
  /// approximate point (100-300 m away) automatically.
  Future<void> saveLocation(String id, {required double latitude, required double longitude}) {
    return guard('host.saveLocation', () async {
      await _client.from('property_locations').upsert(
        {'property_id': id, 'latitude': double.parse(latitude.toStringAsFixed(6)), 'longitude': double.parse(longitude.toStringAsFixed(6))},
        onConflict: 'property_id',
      );
    });
  }

  Future<void> setAmenities(String id, Set<String> amenityIds) {
    return guard('host.amenities', () async {
      await _client.from('property_amenities').delete().eq('property_id', id);
      if (amenityIds.isNotEmpty) {
        await _client.from('property_amenities').insert([
          for (final a in amenityIds) {'property_id': id, 'amenity_id': a},
        ]);
      }
    });
  }

  /// Uploads an already-compressed photo and its thumbnail under
  /// {ownerId}/{propertyId}/, then adds it at the end of the gallery.
  Future<PropertyImage> uploadPhoto({
    required String ownerId,
    required String propertyId,
    required Uint8List full,
    required Uint8List thumbnail,
    required int width,
    required int height,
    required int displayOrder,
  }) {
    return guard('host.uploadPhoto', () async {
      final name = '${DateTime.now().microsecondsSinceEpoch}';
      final fullPath = '$ownerId/$propertyId/$name.jpg';
      final thumbPath = '$ownerId/$propertyId/${name}_thumb.jpg';
      final bucket = _client.storage.from(AppConfig.propertyImagesBucket);
      const options = FileOptions(contentType: 'image/jpeg', cacheControl: '31536000');
      await bucket.uploadBinary(fullPath, full, fileOptions: options);
      await bucket.uploadBinary(thumbPath, thumbnail, fileOptions: options);
      final row = await _client
          .from('property_images')
          .insert({
            'property_id': propertyId,
            'storage_path': fullPath,
            'thumbnail_path': thumbPath,
            'display_order': displayOrder,
            'width': width,
            'height': height,
          })
          .select('id, storage_path, thumbnail_path, display_order, caption')
          .single();
      return PropertyImage.fromRow(row);
    });
  }

  Future<void> deletePhoto(PropertyImage image) {
    return guard('host.deletePhoto', () async {
      await _client.from('property_images').delete().eq('id', image.id!);
      final paths = [image.storagePath, ?image.thumbnailPath];
      try {
        await _client.storage.from(AppConfig.propertyImagesBucket).remove(paths);
      } catch (_) {
        // The photo is already off the listing; a leftover file is harmless.
      }
    });
  }

  /// Saves a new photo order; the first photo is the cover.
  Future<void> reorderPhotos(String propertyId, List<String> imageIds) {
    return guard('host.reorderPhotos', () async {
      await _client.rpc<void>('reorder_property_images', params: {'p_property_id': propertyId, 'p_image_ids': imageIds});
    });
  }

  /// Returns the new status. The server lists anything still missing.
  Future<PropertyStatus> submitForReview(String id) {
    return guard('host.submit', () async {
      final status = await _client.rpc<String>('submit_property_for_review', params: {'p_property_id': id});
      return PropertyStatus.values.firstWhere((s) => s.dbValue == status);
    });
  }

  Future<void> setPaused(String id, {required bool paused}) {
    return guard('host.pause', () async {
      await _client.rpc<dynamic>('set_property_paused', params: {'p_property_id': id, 'p_paused': paused});
    });
  }

  Future<void> archive(String id) {
    return guard('host.archive', () => _client.rpc<void>('archive_property', params: {'p_property_id': id}));
  }

  Future<void> deleteDraft(String id) {
    return guard('host.deleteDraft', () async {
      await _client.from('properties').delete().eq('id', id);
    });
  }

  Future<void> confirmAvailability(String id, {String? note}) {
    return guard('host.confirmAvailability', () async {
      await _client.rpc<dynamic>('confirm_property_availability', params: {'p_property_id': id, 'p_note': note});
    });
  }

  Future<void> blockDates(String id, {required DateTime start, required DateTime end, String? note}) {
    return guard('host.blockDates', () async {
      await _client.from('property_unavailable_dates').insert({
        'property_id': id,
        'starts_on': _day(start),
        'ends_on': _day(end),
        'note': (note == null || note.trim().isEmpty) ? null : note.trim(),
      });
    });
  }

  Future<void> unblockDates(String rangeId) {
    return guard('host.unblockDates', () async {
      await _client.from('property_unavailable_dates').delete().eq('id', rangeId);
    });
  }

  Future<Map<String, ListingStats>> fetchStats() {
    return guard('host.stats', () async {
      final rows = await _client.rpc<List<dynamic>>('owner_listing_stats');
      return {
        for (final r in rows.cast<Map<String, dynamic>>()) r['property_id'] as String: ListingStats.fromRow(r),
      };
    });
  }

  static const _enquiryColumns = 'id, property_id, check_in, check_out, guest_count, guest_name, guest_contact, '
      'message, status, owner_response, seen_at, responded_at, owner_reported_booking_at, guest_reported_booking_at, created_at, '
      'properties!inner(owner_id, title, listing_number, property_images(storage_path, thumbnail_path, display_order))';

  /// Enquiries for the host's own listings, newest first.
  Future<List<Enquiry>> fetchEnquiries(String ownerId) {
    return guard('host.enquiries', () async {
      final rows = await _client
          .from('enquiries')
          .select(_enquiryColumns)
          .eq('properties.owner_id', ownerId)
          .order('created_at', ascending: false)
          .limit(200);
      return rows.map(Enquiry.fromRow).toList();
    });
  }

  /// seen / available / unavailable / booked / closed, with an optional reply.
  Future<EnquiryStatus> respondToEnquiry(String enquiryId, EnquiryStatus status, {String? response}) {
    return guard('host.respond', () async {
      final result = await _client.rpc<String>('owner_update_enquiry', params: {
        'p_enquiry_id': enquiryId,
        'p_status': status.dbValue,
        'p_response': response,
      });
      return EnquiryStatus.values.firstWhere((s) => s.dbValue == result);
    });
  }
}
