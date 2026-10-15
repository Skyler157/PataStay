import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:patastay_core/patastay_core.dart';
import 'package:patastay_mobile/app/app.dart';
import 'package:patastay_mobile/core/routing/routes.dart';
import 'package:patastay_mobile/core/storage/local_preferences.dart';

class FakePreferences implements LocalPreferences {
  FakePreferences({this.onboardingSeen = false});

  @override
  bool onboardingSeen;

  @override
  Future<void> setOnboardingSeen() async => onboardingSeen = true;
}

class MockAuthRepository extends Mock implements AuthRepository {}

const _neighbourhoods = [
  Neighbourhood(id: '1', name: 'Kilimani', slug: 'kilimani', isPopular: true),
  Neighbourhood(id: '2', name: 'Ngara', slug: 'ngara'),
];

Widget buildApp({
  required LocalPreferences prefs,
  AuthRepository? auth,
  Future<List<Neighbourhood>> Function()? loadNeighbourhoods,
}) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(
        const AppConfig(supabaseUrl: 'http://127.0.0.1:54321', supabasePublishableKey: 'sb_publishable_test'),
      ),
      localPreferencesProvider.overrideWithValue(prefs),
      authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
      currentUserIdProvider.overrideWithValue(null),
      currentProfileProvider.overrideWith((ref) async => null),
      neighbourhoodsProvider.overrideWith((ref) => (loadNeighbourhoods ?? () async => _neighbourhoods)()),
      if (auth != null) authRepositoryProvider.overrideWithValue(auth),
    ],
    child: const PataStayApp(),
  );
}

void main() {
  testWidgets('first launch shows onboarding, Skip goes to Explore with live neighbourhoods', (tester) async {
    final prefs = FakePreferences();
    await tester.pumpWidget(buildApp(prefs: prefs));
    await tester.pumpAndSettle();

    expect(find.text('Find a stay that fits your budget'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(prefs.onboardingSeen, isTrue);
    expect(find.text('Pata your perfect stay.'), findsOneWidget);
    expect(find.text('Kilimani'), findsOneWidget);
    expect(find.text('Ngara'), findsOneWidget);
  });

  testWidgets('Explore shows an error state with retry when loading fails', (tester) async {
    await tester.pumpWidget(buildApp(
      prefs: FakePreferences(onboardingSeen: true),
      loadNeighbourhoods: () async => throw const NetworkFailure(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('You appear to be offline'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('signed-out Profile prompts sign in and validates the form', (tester) async {
    await tester.pumpWidget(buildApp(prefs: FakePreferences(onboardingSeen: true)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to PataStay'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);

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
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), ' guest@example.com ');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'Nairobi2026');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    verify(() => auth.signIn(email: ' guest@example.com ', password: 'Nairobi2026')).called(1);
    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  group('Routes.safeReturnPath', () {
    test('allows in-app paths', () {
      expect(Routes.safeReturnPath('/profile/edit'), '/profile/edit');
    });

    test('blocks external and auth redirects', () {
      expect(Routes.safeReturnPath('https://evil.example'), isNull);
      expect(Routes.safeReturnPath('//evil.example'), isNull);
      expect(Routes.safeReturnPath(Routes.signIn), isNull);
      expect(Routes.safeReturnPath(null), isNull);
    });
  });
}
