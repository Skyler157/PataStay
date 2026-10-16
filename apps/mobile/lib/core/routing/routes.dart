abstract final class Routes {
  static const onboarding = '/onboarding';
  static const explore = '/explore';
  static const search = '/explore/search';
  static const saved = '/saved';
  static const enquiries = '/enquiries';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const signIn = '/auth/sign-in';
  static const register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';
  static const updatePassword = '/auth/update-password';
  static const enquirySent = '/enquiry-sent';

  static String property(String id) => '/property/$id';
  static String enquire(String propertyId) => '/property/$propertyId/enquire';
  static String enquiry(String id) => '/enquiries/$id';

  static const _requiresAuth = {editProfile, updatePassword, enquirySent};
  static const _authEntry = {signIn, register, forgotPassword};
  static final _enquirePath = RegExp(r'^/property/[^/]+/enquire$');

  static bool requiresAuth(String location) => _requiresAuth.contains(location) || _enquirePath.hasMatch(location);

  /// Screens a signed-in user should be sent away from.
  static bool isAuthEntry(String location) => _authEntry.contains(location);

  /// Only allows in-app paths as post-login destinations (no open redirects).
  static String? safeReturnPath(String? from) {
    if (from == null || !from.startsWith('/') || from.startsWith('//') || from.contains('://')) return null;
    if (isAuthEntry(Uri.parse(from).path)) return null;
    return from;
  }

  /// Where to go after a successful sign-in or sign-up.
  static String afterSignIn(String? from) => safeReturnPath(from) ?? profile;

  static String signInReturningTo(String from) => '$signIn?from=${Uri.encodeComponent(from)}';
}
