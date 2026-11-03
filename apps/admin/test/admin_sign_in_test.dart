import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_admin/features/auth/admin_sign_in_screen.dart';
import 'package:patastay_admin/features/auth/set_password_screen.dart';
import 'package:patastay_core/patastay_core.dart';

class _FakeAuth extends Fake implements AuthRepository {
  final calls = <String>[];

  @override
  Future<void> sendPasswordReset(String email) async => calls.add('reset ${email.trim()}');

  @override
  Future<void> updatePassword(String newPassword) async => calls.add('update $newPassword');
}

Widget _app(_FakeAuth auth, Widget screen) => ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: GoRouter(initialLocation: '/screen', routes: [
          GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('Dashboard'))),
          GoRoute(path: '/screen', builder: (_, _) => screen),
        ]),
      ),
    );

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1400, 1000);
    binding.platformDispatcher.views.first.devicePixelRatio = 1;
  });

  testWidgets('the password can be shown and hidden', (tester) async {
    await tester.pumpWidget(_app(_FakeAuth(), const AdminSignInScreen()));
    bool obscured() => tester.widget<EditableText>(find.byType(EditableText).last).obscureText;

    expect(obscured(), isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(obscured(), isFalse);
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(obscured(), isTrue);
  });

  testWidgets('forgot password sends a reset link to the typed email', (tester) async {
    final auth = _FakeAuth();
    await tester.pumpWidget(_app(auth, const AdminSignInScreen()));
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'admin@patastay.test');

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset your password'), findsOneWidget);

    await tester.tap(find.text('Send link'));
    await tester.pumpAndSettle();

    expect(auth.calls, ['reset admin@patastay.test']);
    expect(find.textContaining('a reset link is on its way'), findsOneWidget);
  });

  testWidgets('a new password must be strong and typed twice', (tester) async {
    final auth = _FakeAuth();
    await tester.pumpWidget(_app(auth, const SetPasswordScreen()));

    await tester.enterText(find.widgetWithText(TextFormField, 'New password'), 'NewPass2026');
    await tester.enterText(find.widgetWithText(TextFormField, 'Confirm new password'), 'Different2026');
    await tester.tap(find.text('Save password'));
    await tester.pumpAndSettle();
    expect(auth.calls, isEmpty);

    await tester.enterText(find.widgetWithText(TextFormField, 'Confirm new password'), 'NewPass2026');
    await tester.tap(find.text('Save password'));
    await tester.pumpAndSettle();
    expect(auth.calls, ['update NewPass2026']);
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
