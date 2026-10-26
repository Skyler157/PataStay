// Runs the main guest screens with large system text (160%) on a small,
// low-cost phone screen. Layout overflow fails the test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:patastay_core/patastay_core.dart';

import 'app_flow_test.dart' as flow;
import 'host_flow_test.dart' as host;

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    // 360x780 dp: a typical budget Android phone.
    binding.platformDispatcher.views.first.physicalSize = const Size(720, 1560);
    binding.platformDispatcher.views.first.devicePixelRatio = 2.0;
    binding.platformDispatcher.textScaleFactorTestValue = 1.6;
  });

  tearDown(() => TestWidgetsFlutterBinding.instance.platformDispatcher.clearTextScaleFactorTestValue());

  testWidgets('onboarding, home, search and listing details fit with large text', (tester) async {
    await tester.pumpWidget(flow.buildApp(prefs: flow.FakePreferences()));
    await tester.pumpAndSettle();
    expect(find.text('Find a stay that fits your budget'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Home, scrolled through.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1500));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Where in Nairobi?'));
    await tester.pumpAndSettle();
    expect(find.text('Near me'), findsOneWidget);

    await tester.tap(find.text('Bright studio near Yaya Centre').first);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2500));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Contact host'));
    await tester.pumpAndSettle();
    expect(find.text('Before you contact Otieno'), findsOneWidget);
  });

  testWidgets('sign-in and register fit with large text', (tester) async {
    await tester.pumpWidget(flow.buildApp(prefs: flow.FakePreferences(onboardingSeen: true)));
    await tester.pumpAndSettle();
    await flow.openTab(tester, 'Profile');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    await tester.ensureVisible(find.text('Create an account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);
  });

  testWidgets('Saved and Enquiries fit with large text', (tester) async {
    await tester.pumpWidget(flow.buildApp(prefs: flow.FakePreferences(onboardingSeen: true)));
    await tester.pumpAndSettle();
    await flow.openTab(tester, 'Saved');
    await flow.openTab(tester, 'Enquiries');
    await flow.openTab(tester, 'Profile');
    expect(find.text('Sign in to PataStay'), findsOneWidget);
  });

  testWidgets('host dashboard, manage listing, wizard and enquiry fit with large text', (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(flow.buildApp(
      prefs: flow.FakePreferences(onboardingSeen: true),
      signedInAs: Profile(id: 'h1', fullName: 'Leah W', role: UserRole.owner, createdAt: DateTime(2026)),
      hostListings: [host.listingForTests(id: 'l1', status: 'rejected', title: 'Garden studio in Lavington', reason: 'Please add a bathroom photo.')],
      hostEnquiries: [
        Enquiry(
          id: 'e1', propertyId: 'l1', checkIn: now.add(const Duration(days: 7)), checkOut: now.add(const Duration(days: 9)),
          guestCount: 2, guestName: 'Wanjiku Kamau', guestContact: '+254722000222', status: EnquiryStatus.newEnquiry,
          createdAt: now, propertyTitle: 'Garden studio in Lavington', listingNumber: 1020,
        ),
      ],
    ));
    await tester.pumpAndSettle();
    await flow.openTab(tester, 'Profile');
    await tester.ensureVisible(find.text('Hosting'));
    await tester.tap(find.text('Hosting'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Garden studio in Lavington'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit listing'));
    await tester.pumpAndSettle();
    expect(find.text('Basics'), findsOneWidget);

    // Visit every wizard step through the step menu.
    for (final step in ['Location', 'Rooms & guests', 'Pricing', 'Amenities', 'Photos', 'Check-in & rules', 'Contact number', 'Review & submit']) {
      await tester.tap(find.byTooltip('All steps'));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text(step)));
      await tester.pumpAndSettle();
      final error = tester.takeException();
      expect(error, isNull, reason: 'layout problem on wizard step "$step": $error');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'layout problem lower down on wizard step "$step"');
    }
  });
}
