import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patastay_core/patastay_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/admin_app.dart';
import 'app/theme_mode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  if (!config.isConfigured) {
    runApp(ConfigurationErrorApp(
      problems: config.problems,
      runCommand: 'flutter run -d chrome --web-port 5050 --dart-define-from-file=../../env/dev.json',
    ));
    return;
  }

  await Supabase.initialize(url: config.supabaseUrl, publishableKey: config.supabasePublishableKey);

  SharedPreferences? preferences;
  try {
    preferences = await SharedPreferences.getInstance();
  } catch (_) {
    // Storage blocked (e.g. private window): the theme choice won't be remembered.
  }

  runApp(ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      adminPreferencesProvider.overrideWithValue(preferences),
      // Password-reset links for admins return to the dashboard origin.
      authRepositoryProvider.overrideWith(
        (ref) => AuthRepository(ref.watch(supabaseClientProvider).auth, redirectUrl: Uri.base.origin),
      ),
    ],
    child: const AdminApp(),
  ));
}
