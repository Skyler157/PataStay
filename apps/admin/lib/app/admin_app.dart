import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../features/auth/admin_gate.dart';
import '../features/auth/admin_sign_in_screen.dart';
import '../features/dashboard/dashboard_screen.dart';

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
      GoRoute(path: '/', builder: (_, _) => const AdminGate(child: DashboardScreen())),
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
