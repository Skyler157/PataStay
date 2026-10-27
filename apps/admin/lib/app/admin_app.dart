import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../data/admin_models.dart';
import '../features/auth/admin_gate.dart';
import '../features/auth/admin_sign_in_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/listings/listing_review_screen.dart';
import '../features/listings/listings_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/users/user_detail_screen.dart';
import '../features/users/users_screen.dart';
import 'admin_shell.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(currentUserIdProvider, (_, _) => refresh.ping());

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(currentUserIdProvider) != null;
      final atSignIn = state.matchedLocation == '/sign-in';
      if (!signedIn) return atSignIn ? null : '/sign-in';
      if (atSignIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/sign-in', builder: (_, _) => const AdminSignInScreen()),
      // Every admin page is wrapped in AdminGate (UI check). The database
      // enforces admin rights independently on every query and RPC.
      ShellRoute(
        builder: (_, state, child) =>
            AdminGate(child: AdminShell(location: state.matchedLocation, child: child)),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
          GoRoute(path: '/review', builder: (_, _) => const ListingsScreen(reviewQueue: true)),
          GoRoute(
            path: '/listings',
            builder: (_, state) => ListingsScreen(
              key: ValueKey(state.uri.query),
              initialStatus: PropertyStatus.values
                  .where((s) => s.dbValue == state.uri.queryParameters['status'])
                  .firstOrNull,
            ),
            routes: [
              GoRoute(path: ':id', builder: (_, state) => ListingReviewScreen(id: state.pathParameters['id']!)),
            ],
          ),
          GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
          GoRoute(
            path: '/users',
            builder: (_, state) => UsersScreen(
              key: ValueKey(state.uri.query),
              initialFilter: UserFilter.values.where((f) => f.name == state.uri.queryParameters['filter']).firstOrNull ??
                  UserFilter.all,
            ),
            routes: [
              GoRoute(path: ':id', builder: (_, state) => UserDetailScreen(id: state.pathParameters['id']!)),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'PataStay Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: ref.watch(adminRouterProvider),
    );
  }
}

class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}
