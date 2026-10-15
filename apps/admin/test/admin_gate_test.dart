import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patastay_admin/features/auth/admin_gate.dart';
import 'package:patastay_admin/features/dashboard/dashboard_screen.dart';
import 'package:patastay_admin/features/dashboard/platform_stats.dart';
import 'package:patastay_core/patastay_core.dart';

Profile _profile(UserRole role) =>
    Profile(id: 'u1', fullName: 'Test User', email: 'u@test.local', role: role, createdAt: DateTime(2026));

Widget _gate(Profile profile) => ProviderScope(
      overrides: [
        currentProfileProvider.overrideWith((ref) async => profile),
        platformStatsProvider.overrideWith(
          (ref, days) async => PlatformStats({
            'period_days': days,
            'listings_by_status': {'pending_review': 3, 'published': 12},
            'reports_open': 2,
            'enquiries': 10,
            'enquiries_responded': 7,
            'promotion_revenue_kes': 4500,
          }),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const AdminGate(child: DashboardScreen())),
    );

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1600, 1200);
    binding.platformDispatcher.views.first.devicePixelRatio = 1;
  });

  for (final role in [UserRole.guest, UserRole.owner]) {
    testWidgets('${role.name} is denied the dashboard', (tester) async {
      await tester.pumpWidget(_gate(_profile(role)));
      await tester.pumpAndSettle();
      expect(find.text('Administrator access required'), findsOneWidget);
      expect(find.text('Overview'), findsNothing);
    });
  }

  testWidgets('suspended admin is denied the dashboard', (tester) async {
    await tester.pumpWidget(_gate(_profile(UserRole.admin).copyWith(accountStatus: AccountStatus.suspended)));
    await tester.pumpAndSettle();
    expect(find.text('Administrator access required'), findsOneWidget);
  });

  testWidgets('admin sees live platform statistics', (tester) async {
    await tester.pumpWidget(_gate(_profile(UserRole.admin)));
    await tester.pumpAndSettle();
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Listings pending review'), findsOneWidget);
    expect(find.text('70%'), findsOneWidget);
    expect(find.text('KES 4,500'), findsOneWidget);
  });
}
