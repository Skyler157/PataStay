import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../errors/app_failure.dart';
import '../models/property.dart';
import '../models/search_filters.dart';

class PropertyPage {
  const PropertyPage(this.items, {required this.hasMore});

  final List<Property> items;
  final bool hasMore;
}

class PropertyRepository {
  PropertyRepository(this._client);

  final SupabaseClient _client;

  static const pageSize = 20;

  static const _baseColumns = 'id, listing_number, title, property_type, nightly_rate, cleaning_fee, '
      'refundable_deposit, bedrooms, bathrooms, maximum_guests, minimum_nights, verified_at, '
      'availability_confirmed_at, is_featured, is_seed, created_at, latitude, longitude, '
      'neighbourhoods(id, name, slug, latitude, longitude), '
      'property_amenities(amenities(id, name, slug, category, icon, is_key, sort_order))';

  static const _cardColumns = '$_baseColumns, property_images(storage_path, thumbnail_path, display_order)';

  static const _detailColumns = '$_baseColumns, description, address_or_area_description, check_in_time, '
      'check_out_time, check_in_information, check_out_information, house_rules, availability_note, '
      'property_images(storage_path, thumbnail_path, display_order, caption), '
      'property_unavailable_dates(starts_on, ends_on, note)';

  /// Paginated search. Ordering is applied here; filtering runs in the
  /// search_properties RPC under the caller's RLS (published listings only).
  Future<PropertyPage> search(SearchFilters filters, {int page = 0}) {
    if (filters.isNearMe) return _searchNearby(filters, page: page);
    return guard('properties.search', () async {
      final from = page * pageSize;
      var query = _client.rpc<List<dynamic>>('search_properties', params: filters.toRpcParams()).select(_cardColumns);
      final ordered = switch (filters.sort) {
        SearchSort.priceLow => query.order('nightly_rate', ascending: true).order('created_at'),
        SearchSort.priceHigh => query.order('nightly_rate', ascending: false).order('created_at'),
        SearchSort.newest => query.order('created_at', ascending: false),
        SearchSort.recommended || SearchSort.nearest => query
            .order('is_featured', ascending: false)
            .order('verified_at', ascending: false, nullsFirst: false)
            .order('availability_confirmed_at', ascending: false, nullsFirst: false)
            .order('created_at', ascending: false),
      };
      // Fetch one extra row to know whether another page exists.
      final rows = await ordered.range(from, from + pageSize);
      final items = rows.cast<Map<String, dynamic>>().map(Property.fromRow).toList();
      final hasMore = items.length > pageSize;
      return PropertyPage(hasMore ? items.sublist(0, pageSize) : items, hasMore: hasMore);
    });
  }

  /// Closest first within the radius. The RPC returns ids and distances in
  /// order; cards are then loaded by id and kept in that order.
  Future<PropertyPage> _searchNearby(SearchFilters filters, {required int page}) {
    return guard('properties.nearby', () async {
      final rows = await _client.rpc<List<dynamic>>(
        'search_nearby',
        params: filters.toNearbyParams(limit: pageSize + 1, offset: page * pageSize),
      );
      final hits = rows.cast<Map<String, dynamic>>();
      final hasMore = hits.length > pageSize;
      final pageHits = hasMore ? hits.sublist(0, pageSize) : hits;
      final distances = {for (final h in pageHits) h['property_id'] as String: (h['distance_km'] as num).toDouble()};
      final cards = await fetchByIds(distances.keys.toList());
      return PropertyPage(
        [for (final p in cards) p.copyWith(distanceKm: distances[p.id])],
        hasMore: hasMore,
      );
    });
  }

  Future<Property?> fetchDetails(String id) {
    return guard('properties.details', () async {
      final row = await _client.from('properties').select(_detailColumns).eq('id', id).maybeSingle();
      return row == null ? null : Property.fromRow(row);
    });
  }

  Future<List<Property>> fetchByIds(List<String> ids) {
    if (ids.isEmpty) return Future.value(const []);
    return guard('properties.byIds', () async {
      final rows = await _client.from('properties').select(_cardColumns).inFilter('id', ids);
      final byId = {for (final r in rows) r['id'] as String: Property.fromRow(r)};
      return [for (final id in ids) ?byId[id]];
    });
  }

  Future<HostSummary?> fetchHostSummary(String propertyId) {
    return guard('properties.host', () async {
      final rows = await _client.rpc<List<dynamic>>('get_host_summary', params: {'p_property_id': propertyId});
      if (rows.isEmpty) return null;
      final r = rows.first as Map<String, dynamic>;
      return HostSummary(
        displayName: r['display_name'] as String,
        memberSince: DateTime.parse(r['member_since'] as String),
        publishedListings: (r['published_listings'] as num?)?.toInt() ?? 0,
        verifiedListings: (r['verified_listings'] as num?)?.toInt() ?? 0,
        typicalResponseHours: (r['typical_response_hours'] as num?)?.toDouble(),
      );
    });
  }

  /// Records a listing view. Failures are ignored; analytics must never
  /// break browsing.
  Future<void> trackView(String propertyId) async {
    try {
      await _client.rpc<void>('track_listing_event', params: {'p_property_id': propertyId, 'p_event_type': 'view'});
    } catch (_) {}
  }

  /// Reveals the host's numbers (signed-in users only; logged and rate-limited).
  Future<ContactDetails> revealContact(String propertyId, {required bool whatsapp}) {
    return guard('properties.contact', () async {
      final rows = await _client.rpc<List<dynamic>>(
        'get_property_contact',
        params: {'p_property_id': propertyId, 'p_channel': whatsapp ? 'whatsapp' : 'call'},
      );
      if (rows.isEmpty) throw const NotFoundFailure('This host has not added a contact number yet.');
      final r = rows.first as Map<String, dynamic>;
      return ContactDetails(phone: r['phone'] as String, whatsappPhone: r['whatsapp_phone'] as String);
    });
  }

  /// Public CDN URL for a listing photo.
  String imageUrl(PropertyImage image, {bool thumbnail = false}) {
    final path = thumbnail ? (image.thumbnailPath ?? image.storagePath) : image.storagePath;
    return _client.storage.from(AppConfig.propertyImagesBucket).getPublicUrl(path);
  }
}
