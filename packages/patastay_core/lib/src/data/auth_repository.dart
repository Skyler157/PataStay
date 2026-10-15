import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../errors/app_failure.dart';

enum SignUpOutcome {
  /// The user is signed in immediately (email confirmation disabled).
  signedIn,

  /// The user must click the link in the confirmation email first.
  confirmationEmailSent,
}

class AuthRepository {
  AuthRepository(this._auth, {String this._redirectUrl = AppConfig.authRedirectUrl});

  final GoTrueClient _auth;
  final String? _redirectUrl;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  User? get currentUser => _auth.currentUser;

  Future<SignUpOutcome> signUp({
    required String email,
    required String password,
    required String fullName,
    bool wantsToHost = false,
  }) {
    return guard('auth.signUp', () async {
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: _redirectUrl,
        data: {
          'full_name': fullName.trim(),
          // The database only honours 'owner' here; 'admin' is ignored.
          if (wantsToHost) 'intended_role': 'owner',
        },
      );
      return response.session == null ? SignUpOutcome.confirmationEmailSent : SignUpOutcome.signedIn;
    });
  }

  Future<void> signIn({required String email, required String password}) {
    return guard('auth.signIn', () async {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    });
  }

  Future<void> signOut() => guard('auth.signOut', () => _auth.signOut());

  Future<void> sendPasswordReset(String email) {
    return guard('auth.resetPassword', () {
      return _auth.resetPasswordForEmail(email.trim(), redirectTo: _redirectUrl);
    });
  }

  Future<void> updatePassword(String newPassword) {
    return guard('auth.updatePassword', () async {
      await _auth.updateUser(UserAttributes(password: newPassword));
    });
  }
}
