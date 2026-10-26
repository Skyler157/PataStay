import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:patastay_core/patastay_core.dart';

import 'app_flow_test.dart' as flow;

class MockHostRepository extends Mock implements HostRepository {}

final _guest = Profile(id: 'g1', fullName: 'Leah Gitau', role: UserRole.guest, createdAt: DateTime(2026));
final _host = Profile(id: 'h1', fullName: 'Leah W', role: UserRole.owner, createdAt: DateTime(2026));

HostListing listingForTests({required String id, required String status, String title = '', String? reason, bool complete = false}) {
  return HostListing.fromRow({
    'id': id,
    'listing_number': 1020,
    'title': title,
    'description': complete ? 'Clean, quiet and close to shops and matatus. Fast Wi-Fi and backup power.' : '',
    'property_type': complete ? 'studio' : null,
    'nightly_rate': complete ? 3200 : null,
    'bedrooms': complete ? 0 : null,
    'bathrooms': complete ? 1 : null,
    'maximum_guests': complete ? 2 : null,
    'minimum_nights': 1,
    'is_featured': false,
    'is_seed': false,
    'created_at': '2026-10-20T08:00:00Z',
    'status': status,
    'rejection_reason': reason,
    'approved_at': status == 'published' ? '2026-10-21T08:00:00Z' : null,
    'neighbourhoods': complete ? {'id': 'n1', 'name': 'Kilimani', 'slug': 'kilimani'} : null,
    'property_images': const [],
    'property_amenities': const [],
    'property_contacts': complete ? {'phone': '+254711000111', 'whatsapp_phone': '+254711000111'} : null,
    'property_locations': null,
  });
}

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2340);
    binding.platformDispatcher.views.first.devicePixelRatio = 2.75;
    registerFallbackValue(EnquiryStatus.seen);
  });

  testWidgets('a guest is invited to list their place', (tester) async {
    await tester.pumpWidget(flow.buildApp(prefs: flow.FakePreferences(onboardingSeen: true), signedInAs: _guest));
    await tester.pumpAndSettle();
    await flow.openTab(tester, 'Profile');
    expect(find.text('Have a place to rent out?'), findsOneWidget);
    expect(find.text('List your place'), findsOneWidget);
    expect(find.text('Hosting'), findsNothing);
  });

  testWidgets('a host sees the dashboard, listing status and the reviewer\'s note', (tester) async {
    await tester.pumpWidget(flow.buildApp(
      prefs: flow.FakePreferences(onboardingSeen: true),
      signedInAs: _host,
      hostListings: [
        listingForTests(id: 'l1', status: 'rejected', title: 'Garden studio in Lavington', reason: 'Please add a photo of the bathroom.'),
        listingForTests(id: 'l2', status: 'draft'),
      ],
    ));
    await tester.pumpAndSettle();
    await flow.openTab(tester, 'Profile');
    await tester.tap(find.text('Hosting'));
    await tester.pumpAndSettle();

    expect(find.text('Your listings'), findsOneWidget);
    expect(find.text('Garden studio in Lavington'), findsOneWidget);
    expect(find.text('Untitled listing'), findsOneWidget);
    expect(find.text('Needs changes'), findsOneWidget);
    expect(find.textContaining('Please add a photo of the bathroom.'), findsOneWidget);
    expect(find.text('Add a listing'), findsOneWidget);

    await tester.tap(find.text('Garden studio in Lavington'));
    await tester.pumpAndSettle();
    expect(find.text('Manage listing'), findsOneWidget);
    expect(find.textContaining('Edit the listing, then submit it again'), findsOneWidget);
    expect(find.text('Edit listing'), findsOneWidget);
  });

  testWidgets('the wizard review step lists what is missing and jumps to the right step', (tester) async {
    await tester.pumpWidget(flow.buildApp(
      prefs: flow.FakePreferences(onboardingSeen: true),
      signedInAs: _host,
      hostListings: [listingForTests(id: 'l2', status: 'draft')],
    ));
    await tester.pumpAndSettle();
    await flow.openTab(tester, 'Profile');
    await tester.tap(find.text('Hosting'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Untitled listing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue setting up'));
    await tester.pumpAndSettle();

    expect(find.text('Basics'), findsOneWidget);
    expect(find.text('Step 1 of 9 · saved as you go'), findsOneWidget);
    await tester.tap(find.byTooltip('All steps'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review & submit'));
    await tester.pumpAndSettle();

    expect(find.text('Still needed'), findsOneWidget);
    expect(find.text('A title of at least 10 characters'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('At least 3 photos (0 added)'), 300, scrollable: find.byType(Scrollable).last);
    expect(find.text('At least 3 photos (0 added)'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('A title of at least 10 characters'), -300, scrollable: find.byType(Scrollable).last);
    final submit = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Submit for review'));
    expect(submit.onPressed, isNull, reason: 'cannot submit an incomplete listing');

    await tester.tap(find.widgetWithText(TextButton, 'Add').first);
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 9 · saved as you go'), findsOneWidget);
  });

  testWidgets('a host replies "available" to a new enquiry', (tester) async {
    final repo = MockHostRepository();
    when(() => repo.respondToEnquiry(any(), any(), response: any(named: 'response')))
        .thenAnswer((inv) async => inv.positionalArguments[1] as EnquiryStatus);
    final now = DateTime.now();
    await tester.pumpWidget(flow.buildApp(
      prefs: flow.FakePreferences(onboardingSeen: true),
      signedInAs: _host,
      hostRepository: repo,
      hostEnquiries: [
        Enquiry(
          id: 'e1', propertyId: 'l1', checkIn: now.add(const Duration(days: 7)), checkOut: now.add(const Duration(days: 9)),
          guestCount: 2, guestName: 'Wanjiku Kamau', guestContact: '+254722000222', message: 'Is it free?',
          status: EnquiryStatus.newEnquiry, createdAt: now.subtract(const Duration(hours: 1)),
          propertyTitle: 'Garden studio in Lavington', listingNumber: 1020,
        ),
      ],
    ));
    await tester.pumpAndSettle();
    await flow.openTab(tester, 'Profile');
    await tester.tap(find.text('Hosting'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 waiting for your reply'), findsOneWidget);

    await tester.tap(find.text('Guest enquiries'));
    await tester.pumpAndSettle();
    expect(find.text('Wanjiku Kamau'), findsOneWidget);
    await tester.tap(find.text('Wanjiku Kamau'));
    await tester.pumpAndSettle();

    // Opening the enquiry tells the guest it was seen.
    verify(() => repo.respondToEnquiry('e1', EnquiryStatus.seen, response: any(named: 'response'))).called(1);
    expect(find.text('WhatsApp guest'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('It is available'), 300, scrollable: find.byType(Scrollable).last);
    await tester.enterText(find.byType(TextField), 'Yes, it is free.');
    await tester.tap(find.text('It is available'));
    await tester.pumpAndSettle();
    verify(() => repo.respondToEnquiry('e1', EnquiryStatus.available, response: 'Yes, it is free.')).called(1);
  });
}
