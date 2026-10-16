import 'package:flutter_test/flutter_test.dart';
import 'package:patastay_core/patastay_core.dart';

Map<String, dynamic> _row({Map<String, dynamic> extra = const {}}) => {
      'id': 'p1',
      'listing_number': 1001,
      'title': 'Bright studio near Yaya Centre',
      'property_type': 'studio',
      'nightly_rate': 3500,
      'cleaning_fee': 500,
      'refundable_deposit': 2000,
      'latitude': -1.2926,
      'longitude': 36.7881,
      'bedrooms': 0,
      'bathrooms': 1.0,
      'maximum_guests': 2,
      'minimum_nights': 2,
      'verified_at': '2026-09-12T10:00:00Z',
      'availability_confirmed_at': '2026-10-13T08:00:00Z',
      'is_featured': true,
      'is_seed': true,
      'created_at': '2026-10-01T08:00:00Z',
      'neighbourhoods': {'id': 'n1', 'name': 'Kilimani', 'slug': 'kilimani'},
      'property_images': [
        {'storage_path': 'u/p1/b.jpg', 'display_order': 1},
        {'storage_path': 'seed/p1/a.jpg', 'display_order': 0},
      ],
      'property_amenities': [
        {'amenities': {'id': 'a2', 'name': 'Hot shower', 'slug': 'hot-shower', 'is_key': true, 'sort_order': 20}},
        {'amenities': {'id': 'a1', 'name': 'Wi-Fi', 'slug': 'wifi', 'is_key': true, 'sort_order': 10}},
        {'amenities': {'id': 'a3', 'name': 'CCTV', 'slug': 'cctv', 'is_key': false, 'sort_order': 80}},
      ],
      'property_unavailable_dates': [
        {'starts_on': '2026-11-10', 'ends_on': '2026-11-12', 'note': null},
      ],
      ...extra,
    };

void main() {
  final property = Property.fromRow(_row());

  group('Property.fromRow', () {
    test('parses a card/details row', () {
      expect(property.reference, 'PS-1001');
      expect(property.propertyType, PropertyType.studio);
      expect(property.neighbourhood?.name, 'Kilimani');
      expect(property.nightlyRate, 3500);
      expect(property.isVerified, isTrue);
      expect(property.isSeed, isTrue);
      expect(property.hasLocation, isTrue);
      expect(property.latitude, -1.2926);
      expect(property.roomsSummary, 'Studio · 2 guests · 1 bath');
    });

    test('orders images and amenities', () {
      expect(property.coverImage?.storagePath, 'seed/p1/a.jpg');
      expect(property.coverImage?.isPlaceholder, isTrue);
      expect(property.amenities.map((a) => a.name), ['Wi-Fi', 'Hot shower', 'CCTV']);
      expect(property.keyAmenities.map((a) => a.name), ['Wi-Fi', 'Hot shower']);
    });

    test('unverified listings never report verified', () {
      final p = Property.fromRow(_row(extra: {'verified_at': null}));
      expect(p.isVerified, isFalse);
    });

    test('freshness', () {
      expect(property.isStale(now: DateTime.utc(2026, 10, 15)), isFalse);
      expect(property.isStale(now: DateTime.utc(2026, 11, 1)), isTrue);
      expect(Property.fromRow(_row(extra: {'availability_confirmed_at': null})).isStale(), isTrue);
    });
  });

  group('StayQuote', () {
    test('totals nights plus cleaning, deposit kept separate', () {
      final q = StayQuote.forStay(property, DateTime(2026, 11, 1), DateTime(2026, 11, 3))!;
      expect(q.nights, 2);
      expect(q.nightsTotal, 7000);
      expect(q.total, 7500);
      expect(q.refundableDeposit, 2000);
    });

    test('no quote without valid dates', () {
      expect(StayQuote.forStay(property, null, DateTime(2026, 11, 3)), isNull);
      expect(StayQuote.forStay(property, DateTime(2026, 11, 3), DateTime(2026, 11, 3)), isNull);
    });
  });

  group('stayProblems', () {
    final today = DateTime(2026, 10, 15);

    test('valid stay has no problems', () {
      expect(
        stayProblems(property, checkIn: DateTime(2026, 11, 1), checkOut: DateTime(2026, 11, 3), guests: 2, today: today),
        isEmpty,
      );
    });

    test('flags past dates, minimum stay, capacity and blocked nights', () {
      expect(stayProblems(property, checkIn: DateTime(2026, 10, 1), checkOut: DateTime(2026, 10, 4), today: today),
          contains('Check-in cannot be in the past.'));
      expect(stayProblems(property, checkIn: DateTime(2026, 11, 1), checkOut: DateTime(2026, 11, 2), today: today),
          contains('This place has a minimum stay of 2 nights.'));
      expect(
          stayProblems(property,
              checkIn: DateTime(2026, 11, 1), checkOut: DateTime(2026, 11, 3), guests: 3, today: today),
          contains('This place hosts at most 2 guests.'));
      expect(stayProblems(property, checkIn: DateTime(2026, 11, 9), checkOut: DateTime(2026, 11, 11), today: today),
          contains('The host has marked some of these dates as unavailable.'));
    });

    test('checking out on the first blocked day is fine', () {
      expect(stayProblems(property, checkIn: DateTime(2026, 11, 8), checkOut: DateTime(2026, 11, 10), today: today),
          isEmpty);
    });
  });

  group('SearchFilters.toRpcParams', () {
    test('maps filters to RPC parameters', () {
      final params = SearchFilters(
        query: '  Kilimani ',
        propertyTypes: {PropertyType.oneBedroom},
        minPrice: 2000,
        maxPrice: 4000,
        guests: 2,
        verifiedOnly: true,
        recentlyConfirmed: true,
        checkIn: DateTime(2026, 11, 1),
        checkOut: DateTime(2026, 11, 3),
      ).toRpcParams();
      expect(params['p_query'], 'Kilimani');
      expect(params['p_property_types'], ['one_bedroom']);
      expect(params['p_min_price'], 2000);
      expect(params['p_min_guests'], 2);
      expect(params['p_verified_only'], isTrue);
      expect(params['p_confirmed_within_days'], 7);
      expect(params['p_check_in'], '2026-11-01');
      expect(params['p_check_out'], '2026-11-03');
    });

    test('empty filters send nulls', () {
      final params = const SearchFilters().toRpcParams();
      expect(params['p_query'], isNull);
      expect(params['p_neighbourhood_ids'], isNull);
      expect(params['p_check_in'], isNull);
    });

    test('counts advanced filters and matches budget bands', () {
      const f = SearchFilters(neighbourhoodIds: {'a', 'b'}, verifiedOnly: true, minPrice: 2000, maxPrice: 4000);
      expect(f.advancedCount, 3);
      expect(f.matchesBudget(BudgetBand.presets[1]), isTrue);
    });
  });

  test('Enquiry.fromRow and available actions', () {
    final e = Enquiry.fromRow({
      'id': 'e1',
      'property_id': 'p1',
      'check_in': '2026-11-01',
      'check_out': '2026-11-03',
      'guest_count': 2,
      'guest_name': 'Wanjiku',
      'guest_contact': '+254712345678',
      'status': 'available',
      'created_at': '2026-10-15T08:00:00Z',
      'properties': {
        'title': 'Bright studio',
        'listing_number': 1001,
        'property_images': [
          {'storage_path': 'x.jpg', 'display_order': 0},
        ],
      },
    });
    expect(e.status, EnquiryStatus.available);
    expect(e.nights, 2);
    expect(e.reference, 'PS-1001');
    expect(e.canCancel, isTrue);
    expect(e.canReportBooked, isTrue);
    expect(e.copyWith(status: EnquiryStatus.cancelled).canCancel, isFalse);
  });

  group('Near me', () {
    test('distance labels', () {
      expect(property.copyWith(distanceKm: 0.84).distanceLabel, 'About 800 m away');
      expect(property.copyWith(distanceKm: 1.26).distanceLabel, 'About 1.3 km away');
      expect(property.copyWith(distanceKm: 12.4).distanceLabel, 'About 12 km away');
      expect(property.distanceLabel, isNull);
    });

    test('nearby params carry location, radius and filters', () {
      const f = SearchFilters(nearLatitude: -1.29, nearLongitude: 36.78, radiusKm: 10, minPrice: 2000);
      expect(f.isNearMe, isTrue);
      final params = f.toNearbyParams(limit: 21, offset: 20);
      expect(params['p_latitude'], -1.29);
      expect(params['p_radius_km'], 10);
      expect(params['p_min_price'], 2000);
      expect(params['p_offset'], 20);
      expect(f.copyWith(sort: SearchSort.nearest).withoutNearMe().isNearMe, isFalse);
      expect(f.copyWith(sort: SearchSort.nearest).withoutNearMe().sort, SearchSort.recommended);
    });
  });
}
