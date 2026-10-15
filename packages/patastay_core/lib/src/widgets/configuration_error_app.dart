import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'pata_wordmark.dart';
import 'state_views.dart';

/// Shown instead of the real app when required build configuration is missing,
/// so a misconfigured build explains exactly what to fix instead of crashing.
class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({super.key, required this.problems, required this.runCommand});

  final List<String> problems;

  /// The command a developer should run, e.g.
  /// `flutter run --dart-define-from-file=env/dev.json`.
  final String runCommand;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Builder(
                  builder: (context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PataWordmark(size: 26),
                      const SizedBox(height: Space.xxl),
                      Text('Backend not configured', style: context.text.headlineSmall),
                      const SizedBox(height: Space.md),
                      InfoBanner(tone: BannerTone.danger, message: problems.join('\n')),
                      const SizedBox(height: Space.xl),
                      Text('How to fix', style: context.text.titleMedium),
                      const SizedBox(height: Space.sm),
                      Text(
                        '1. Copy env/example.json to env/dev.json.\n'
                        '2. Set SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY (from `supabase status` '
                        'locally, or Project Settings > API Keys in the Supabase dashboard).\n'
                        '3. Run the app with:',
                        style: context.text.bodyMedium,
                      ),
                      const SizedBox(height: Space.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(Space.md),
                        decoration: BoxDecoration(
                          color: context.palette.neutralContainer,
                          borderRadius: BorderRadius.circular(Radii.sm),
                        ),
                        child: SelectableText(
                          runCommand,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
