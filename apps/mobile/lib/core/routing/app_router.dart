import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/auth/presentation/update_password_screen.dart';
import '../../features/home/presentation/explore_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/shell/app_shell.dart';
import '../storage/local_preferences.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(currentUserIdProvider, (_, _) => refresh.ping());
  ref.listen(onboardingCompleteProvider, (_, _) => refresh.ping());

  final router = GoRouter(
    initialLocation: Routes.explore,
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final onboarded = ref.read(onboardingCompleteProvider);
      if (!onboarded) return location == Routes.onboarding ? null : Routes.onboarding;
      if (location == Routes.onboarding) return Routes.explore;

      final signedIn = ref.read(currentUserIdProvider) != null;
      if (!signedIn && Routes.requiresAuth(location)) {
        return Routes.signInReturningTo(state.uri.toString());
      }
      if (signedIn && Routes.isAuthEntry(location)) {
        return Routes.safeReturnPath(state.uri.queryParameters['from']) ?? Routes.profile;
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => Routes.explore),
      GoRoute(path: Routes.onboarding, builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(path: Routes.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(path: Routes.updatePassword, builder: (_, _) => const UpdatePasswordScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.explore, builder: (_, _) => const ExploreScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.profile,
              builder: (_, _) => const ProfileScreen(),
              routes: [GoRoute(path: 'edit', builder: (_, _) => const EditProfileScreen())],
            ),
          ]),
        ],
      ),
    ],
  );

  // Password-reset links open the app with a recovery session.
  ref.listen(authStateChangesProvider, (_, next) {
    if (next.value?.event == AuthChangeEvent.passwordRecovery) router.go(Routes.updatePassword);
  });

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

/// Re-runs GoRouter redirects when auth or onboarding state changes.
class _RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}
