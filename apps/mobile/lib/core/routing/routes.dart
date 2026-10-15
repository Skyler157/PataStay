abstract final class Routes {
  static const onboarding = '/onboarding';
  static const explore = '/explore';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const signIn = '/auth/sign-in';
  static const register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';
  static const updatePassword = '/auth/update-password';

  static const _requiresAuth = {editProfile, updatePassword};
  static const _authEntry = {signIn, register, forgotPassword};

  static bool requiresAuth(String location) => _requiresAuth.contains(location);

  /// Screens a signed-in user should be sent away from.
  static bool isAuthEntry(String location) => _authEntry.contains(location);

  /// Only allows in-app paths as post-login destinations (no open redirects).
  static String? safeReturnPath(String? from) {
    if (from == null || !from.startsWith('/') || from.startsWith('//') || from.contains('://')) return null;
    if (isAuthEntry(Uri.parse(from).path)) return null;
    return from;
  }

  static String signInReturningTo(String from) => '$signIn?from=${Uri.encodeComponent(from)}';
}
