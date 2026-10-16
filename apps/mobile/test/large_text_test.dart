// Runs the main guest screens with large system text (160%) on a small,
// low-cost phone screen. Layout overflow fails the test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_flow_test.dart' as flow;

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
}
