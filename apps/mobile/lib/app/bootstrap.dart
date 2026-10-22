import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patastay_core/patastay_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/storage/local_preferences.dart';
import 'app.dart';

const _runCommand = 'flutter run --dart-define-from-file=../../env/dev.json';

/// Validates configuration, initialises Supabase and local storage, installs
/// global error handlers, then starts the app.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.failure('flutter', details.exception, details.exception, details.stack ?? StackTrace.empty);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.failure('uncaught', error, error, stack);
    return true;
  };

  final config = AppConfig.fromEnvironment();
  if (!config.isConfigured) {
    runApp(ConfigurationErrorApp(problems: config.problems, runCommand: _runCommand));
    return;
  }

  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabasePublishableKey,
    authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );

  final preferences = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(allowList: SharedLocalPreferences.keys),
  );

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        localPreferencesProvider.overrideWithValue(SharedLocalPreferences(preferences)),
        // In a browser, email links (password reset, confirmation) must come
        // back to this site rather than to the phone app's deep link.
        if (kIsWeb)
          authRepositoryProvider.overrideWith(
            (ref) => AuthRepository(ref.watch(supabaseClientProvider).auth, redirectUrl: Uri.base.origin),
          ),
      ],
      child: const PataStayApp(),
    ),
  );
}
