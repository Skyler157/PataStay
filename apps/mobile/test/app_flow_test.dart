import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:patastay_core/patastay_core.dart';
import 'package:patastay_mobile/app/app.dart';
import 'package:patastay_mobile/core/connectivity/offline_banner.dart';
import 'package:patastay_mobile/core/routing/routes.dart';
import 'package:patastay_mobile/core/storage/local_preferences.dart';
import 'package:patastay_mobile/features/properties/application/property_providers.dart';
import 'package:patastay_mobile/features/properties/presentation/contact_sheet.dart';

class FakePreferences implements LocalPreferences {
  FakePreferences({this.onboardingSeen = false});

  @override
  bool onboardingSeen;

  @override
  Future<void> setOnboardingSeen() async => onboardingSeen = true;

  @override
  String themeMode = 'system';

  @override
  Future<void> setThemeMode(String mode) async => themeMode = mode;

  @override
  DateTime? enquiriesSeenAt;

  @override
  Future<void> setEnquiriesSeenAt(DateTime time) async => enquiriesSeenAt = time;
}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockPropertyRepository extends Mock implements PropertyRepository {}

class FakeFavourites extends FavouritesController {
  @override
  Future<List<String>> build() async => const [];
}

class FakeSearchResults extends SearchResultsController {
  FakeSearchResults(this.items);

  final List<Property> items;

  @override
  Future<SearchResults> build() async => SearchResults(items: items, hasMore: false);
}

const _neighbourhoods = [
  Neighbourhood(id: '1', name: 'Kilimani', slug: 'kilimani', isPopular: true),
  Neighbourhood(id: '2', name: 'Ngara', slug: 'ngara'),
];

final _studio = Property(
  id: 'p1',
  listingNumber: 1001,
  title: 'Bright studio near Yaya Centre',
  propertyType: PropertyType.studio,
  neighbourhood: _neighbourhoods.first,
  nightlyRate: 3500,
  cleaningFee: 500,
  bedrooms: 0,
  bathrooms: 1,
  maximumGuests: 2,
  isSeed: true,
  verifiedAt: DateTime(2026, 9, 12),
  availabilityConfirmedAt: DateTime.now().subtract(const Duration(days: 2)),
  createdAt: DateTime(2026, 10, 1),
  images: const [PropertyImage(storagePath: 'seed/p1/a.jpg')],
  description: 'A compact, sunny studio with fast Wi-Fi.',
);

Widget buildApp({
  required LocalPreferences prefs,
  AuthRepository? auth,
  Future<List<Property>> Function()? loadRecent,
  bool online = true,
}) {
  final properties = MockPropertyRepository();
  when(() => properties.trackView(any())).thenAnswer((_) async {});
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(
        const AppConfig(supabaseUrl: 'http://127.0.0.1:54321', supabasePublishableKey: 'sb_publishable_test'),
      ),
      localPreferencesProvider.overrideWithValue(prefs),
      authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
      currentUserIdProvider.overrideWithValue(null),
      currentProfileProvider.overrideWith((ref) async => null),
      myEnquiriesProvider.overrideWith((ref) async => const []),
      isOnlineProvider.overrideWith((ref) => Stream.value(online)),
      neighbourhoodsProvider.overrideWith((ref) async => _neighbourhoods),
      amenitiesProvider.overrideWith((ref) async => const []),
      featuredPropertiesProvider.overrideWith((ref) async => [_studio]),
      recentPropertiesProvider.overrideWith((ref) => (loadRecent ?? () async => [_studio])()),
      searchResultsProvider.overrideWith(() => FakeSearchResults([_studio])),
      favouritesProvider.overrideWith(FakeFavourites.new),
      propertyDetailsProvider.overrideWith((ref, id) async => _studio),
      hostSummaryProvider.overrideWith(
        (ref, id) async => HostSummary(displayName: 'Otieno', memberSince: DateTime(2026, 1, 5), publishedListings: 5),
      ),
      propertyRepositoryProvider.overrideWithValue(properties),
      if (auth != null) authRepositoryProvider.overrideWithValue(auth),
    ],
    child: const PataStayApp(),
  );
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2340);
    binding.platformDispatcher.views.first.devicePixelRatio = 2.75;
  });

  testWidgets('first launch shows onboarding; Skip opens Home with areas and listings', (tester) async {
    final prefs = FakePreferences();
    await tester.pumpWidget(buildApp(prefs: prefs));
    await tester.pumpAndSettle();

    expect(find.text('Find a stay that fits your budget'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(prefs.onboardingSeen, isTrue);
    expect(find.text('Pata your perfect stay.'), findsOneWidget);
    expect(find.text('Where in Nairobi?'), findsOneWidget);
    expect(find.text('Kilimani'), findsOneWidget);
    expect(find.text('Under 2K'), findsOneWidget);
    expect(find.text('Bright studio near Yaya Centre'), findsWidgets);
  });

  testWidgets('Home shows an offline state with retry when listings fail', (tester) async {
    await tester.pumpWidget(buildApp(
      prefs: FakePreferences(onboardingSeen: true),
      loadRecent: () async => throw const NetworkFailure(),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('You appear to be offline'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Try again'), findsWidgets);
  });

  testWidgets('See all stays opens search results with price per night', (tester) async {
    await tester.pumpWidget(buildApp(prefs: FakePreferences(onboardingSeen: true)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Where in Nairobi?'));
    await tester.pumpAndSettle();

    expect(find.text('Dates'), findsOneWidget);
    expect(find.text('Filters'), findsOneWidget);
    expect(find.textContaining('1 stay'), findsOneWidget);
    expect(find.text('Sample listing'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
  });

  testWidgets('listing details show the reference and price; contact asks signed-out users to sign in', (tester) async {
    await tester.pumpWidget(buildApp(prefs: FakePreferences(onboardingSeen: true)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Where in Nairobi?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bright studio near Yaya Centre'));
    await tester.pumpAndSettle();

    expect(find.text('PS-1001'), findsOneWidget);
    expect(find.textContaining('not a real place you can book'), findsOneWidget);
    expect(find.text('Cleaning fee'), findsOneWidget);
    expect(find.text('Add dates to see the total'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Contact host'));
    await tester.pumpAndSettle();
    expect(find.text('Before you contact Otieno'), findsOneWidget);
    expect(find.textContaining('Never pay a deposit'), findsOneWidget);
    expect(find.textContaining('PS-1001'), findsWidgets);
    expect(find.text('Sign in to continue'), findsOneWidget);
  });

  testWidgets('Saved and Enquiries ask signed-out users to sign in', (tester) async {
    await tester.pumpWidget(buildApp(prefs: FakePreferences(onboardingSeen: true)));
    await tester.pumpAndSettle();

    await openTab(tester, 'Saved');
    expect(find.text('Save places you like'), findsOneWidget);
    await openTab(tester, 'Enquiries');
    expect(find.text('Track your enquiries'), findsOneWidget);
  });

  testWidgets('signed-out Profile prompts sign in and validates the form', (tester) async {
    await tester.pumpWidget(buildApp(prefs: FakePreferences(onboardingSeen: true)));
    await tester.pumpAndSettle();
    await openTab(tester, 'Profile');
    expect(find.text('Sign in to PataStay'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('sign-in failure is shown to the user', (tester) async {
    final auth = MockAuthRepository();
    when(() => auth.signIn(email: any(named: 'email'), password: any(named: 'password')))
        .thenThrow(const AuthFailure('Incorrect email or password.'));

    await tester.pumpWidget(buildApp(prefs: FakePreferences(onboardingSeen: true), auth: auth));
    await tester.pumpAndSettle();
    await openTab(tester, 'Profile');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'guest@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'Nairobi2026');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets('successful sign-in leaves the sign-in screen', (tester) async {
    final auth = MockAuthRepository();
    when(() => auth.signIn(email: any(named: 'email'), password: any(named: 'password'))).thenAnswer((_) async {});

    await tester.pumpWidget(buildApp(prefs: FakePreferences(onboardingSeen: true), auth: auth));
    await tester.pumpAndSettle();
    await openTab(tester, 'Profile');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'guest@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'Nairobi2026');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsNothing);
  });

  testWidgets('offline banner appears when there is no connection', (tester) async {
    await tester.pumpWidget(buildApp(prefs: FakePreferences(onboardingSeen: true), online: false));
    await tester.pumpAndSettle();
    expect(find.textContaining("You're offline"), findsOneWidget);
  });

  test('WhatsApp message quotes the listing reference and dates', () {
    final msg = whatsappMessage(_studio, hostName: 'Otieno', checkIn: DateTime(2026, 11, 1), checkOut: DateTime(2026, 11, 3));
    expect(msg, startsWith('Hi Otieno,'));
    expect(msg, contains('PS-1001'));
    expect(msg, contains('Sun 1 Nov'));
  });

  group('Routes', () {
    test('safe return paths', () {
      expect(Routes.safeReturnPath('/profile/edit'), '/profile/edit');
      expect(Routes.safeReturnPath('https://evil.example'), isNull);
      expect(Routes.safeReturnPath('//evil.example'), isNull);
      expect(Routes.safeReturnPath(Routes.signIn), isNull);
    });

    test('sending an enquiry requires sign-in; browsing does not', () {
      expect(Routes.requiresAuth(Routes.enquire('abc')), isTrue);
      expect(Routes.requiresAuth(Routes.property('abc')), isFalse);
      expect(Routes.requiresAuth(Routes.search), isFalse);
    });
  });
}
