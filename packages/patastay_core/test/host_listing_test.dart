import 'package:flutter_test/flutter_test.dart';
import 'package:patastay_core/patastay_core.dart';

Map<String, dynamic> _row({Map<String, dynamic> extra = const {}}) => {
      'id': 'p1',
      'listing_number': 1012,
      'title': '',
      'description': '',
      'property_type': null,
      'nightly_rate': null,
      'bedrooms': null,
      'bathrooms': null,
      'maximum_guests': null,
      'minimum_nights': 1,
      'is_featured': false,
      'is_seed': false,
      'created_at': '2026-10-22T08:00:00Z',
      'status': 'draft',
      'property_images': [],
      'property_amenities': [],
      'property_contacts': null,
      'property_locations': null,
      ...extra,
    };

void main() {
  test('an empty draft lists every missing item, in the server\'s order', () {
    final l = HostListing.fromRow(_row());
    expect(l.status, PropertyStatus.draft);
    expect(l.displayTitle, 'Untitled listing');
    expect(l.missingForSubmission, hasLength(10));
    expect(l.readyToSubmit, isFalse);
    expect(l.canSubmit, isTrue);
    expect(l.canDelete, isTrue);
    expect(l.completeness, 0);
  });

  test('a complete listing is ready to submit', () {
    final l = HostListing.fromRow(_row(extra: {
      'title': 'Sunny one-bedroom near Junction',
      'description': 'Clean, quiet and close to shops and matatus. Fast Wi-Fi and backup power.',
      'property_type': 'one_bedroom',
      'neighbourhoods': {'id': 'n1', 'name': 'Kilimani', 'slug': 'kilimani'},
      'nightly_rate': 4500,
      'bedrooms': 1,
      'bathrooms': 1,
      'maximum_guests': 2,
      'property_contacts': {'phone': '+254711000111', 'whatsapp_phone': '+254711000111'},
      'property_locations': {'latitude': -1.2921, 'longitude': 36.7872},
      'property_images': [
        {'id': 'i1', 'storage_path': 'a.jpg', 'display_order': 0},
        {'id': 'i2', 'storage_path': 'b.jpg', 'display_order': 1},
        {'id': 'i3', 'storage_path': 'c.jpg', 'display_order': 2},
      ],
      'property_amenities': [
        {'amenities': {'id': 'wifi', 'name': 'Wi-Fi', 'slug': 'wifi'}},
      ],
    }));
    expect(l.missingForSubmission, isEmpty);
    expect(l.readyToSubmit, isTrue);
    expect(l.hasExactLocation, isTrue);
    expect(l.amenityIds, {'wifi'});
    expect(l.property.images.first.id, 'i1');
    expect(l.completeness, 1);
  });

  test('photos are counted against the minimum', () {
    final l = HostListing.fromRow(_row(extra: {
      'property_images': [
        {'id': 'i1', 'storage_path': 'a.jpg', 'display_order': 0},
      ],
    }));
    expect(l.missingForSubmission, contains('At least 3 photos (1 added)'));
  });

  test('status rules for host actions', () {
    HostListing withStatus(String s, {String? approvedAt}) =>
        HostListing.fromRow(_row(extra: {'status': s, 'approved_at': approvedAt}));
    expect(withStatus('published', approvedAt: '2026-10-01T00:00:00Z').canPause, isTrue);
    expect(withStatus('paused', approvedAt: '2026-10-01T00:00:00Z').canResume, isTrue);
    expect(withStatus('paused').canResume, isFalse, reason: 'never-approved listings cannot be resumed');
    expect(withStatus('suspended').canEdit, isFalse);
    expect(withStatus('rejected').canSubmit, isTrue);
    expect(withStatus('pending_review').canSubmit, isFalse);
    expect(withStatus('rejected', approvedAt: '2026-10-01T00:00:00Z').canDelete, isFalse,
        reason: 'listings that were once live are archived, not deleted');
  });

  test('host response label', () {
    HostSummary h(double? hours) => HostSummary(displayName: 'Otieno', memberSince: DateTime(2026), typicalResponseHours: hours);
    expect(h(null).responseLabel, isNull);
    expect(h(0.5).responseLabel, 'Usually replies within an hour');
    expect(h(2.3).responseLabel, 'Usually replies within 3 hours');
    expect(h(40).responseLabel, 'Usually replies within 2 days');
  });
}
