import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/app_failure.dart';
import '../models/reference_data.dart';

class ReferenceDataRepository {
  ReferenceDataRepository(this._client);

  final SupabaseClient _client;

  Future<List<Neighbourhood>> fetchNeighbourhoods() {
    return guard('reference.neighbourhoods', () async {
      final rows = await _client
          .from('neighbourhoods')
          .select('id, name, slug, city, county, latitude, longitude, is_popular, sort_order')
          // Hidden areas stay readable for existing listings but are not offered.
          .eq('is_active', true)
          .order('sort_order')
          .order('name');
      return rows.map(Neighbourhood.fromJson).toList();
    });
  }

  Future<List<Amenity>> fetchAmenities() {
    return guard('reference.amenities', () async {
      final rows = await _client
          .from('amenities')
          .select('id, name, slug, category, icon, is_key, sort_order')
          .order('sort_order')
          .order('name');
      return rows.map(Amenity.fromJson).toList();
    });
  }
}
