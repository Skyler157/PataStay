import 'dart:convert';

enum AppEnvironment { development, staging, production }

/// Runtime configuration supplied at build time with
/// `--dart-define-from-file=env/<name>.json`.
///
/// Only the Supabase project URL and the *publishable* (anon) key belong in a
/// client app. Secret / service-role keys are rejected outright.
class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    this.environment = AppEnvironment.development,
  });

  factory AppConfig.fromEnvironment() {
    const env = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    return AppConfig(
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL').trim(),
      supabasePublishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY').trim(),
      environment: AppEnvironment.values.firstWhere(
        (e) => e.name == env,
        orElse: () => AppEnvironment.development,
      ),
    );
  }

  final String supabaseUrl;
  final String supabasePublishableKey;
  final AppEnvironment environment;

  static const propertyImagesBucket = 'property-images';

  /// Deep link used by Supabase Auth emails (password reset, confirmation).
  /// Must also be listed under Auth > URL Configuration > Redirect URLs.
  static const authRedirectUrl = 'com.patastay.app://login-callback';

  bool get isProduction => environment == AppEnvironment.production;

  /// Human-readable problems that stop the app from talking to the backend.
  List<String> get problems {
    final issues = <String>[];
    final uri = Uri.tryParse(supabaseUrl);
    if (supabaseUrl.isEmpty) {
      issues.add('SUPABASE_URL is not set.');
    } else if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      issues.add('SUPABASE_URL is not a valid URL.');
    }
    if (supabasePublishableKey.isEmpty) {
      issues.add('SUPABASE_PUBLISHABLE_KEY is not set.');
    } else if (looksLikeSecretKey(supabasePublishableKey)) {
      issues.add(
        'SUPABASE_PUBLISHABLE_KEY looks like a secret/service-role key. '
        'Never ship that key in an app; use the publishable (anon) key.',
      );
    }
    return issues;
  }

  bool get isConfigured => problems.isEmpty;

  /// Detects new-style secret keys and legacy JWT keys with the
  /// `service_role` role claim.
  static bool looksLikeSecretKey(String key) {
    if (key.startsWith('sb_secret_')) return true;
    final parts = key.split('.');
    if (parts.length != 3) return false;
    try {
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final claims = jsonDecode(payload);
      return claims is Map && claims['role'] == 'service_role';
    } on FormatException {
      return false;
    }
  }
}
