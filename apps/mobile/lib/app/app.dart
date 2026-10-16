import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patastay_core/patastay_core.dart';

import '../core/connectivity/offline_banner.dart';
import '../core/routing/app_router.dart';
import '../core/storage/local_preferences.dart';
import '../features/properties/application/property_providers.dart';

class PataStayApp extends ConsumerWidget {
  const PataStayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return MaterialApp.router(
      title: 'PataStay',
      debugShowCheckedModeBanner: !config.isProduction,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => OfflineBanner(
        // Back online: reload what guests are most likely looking at.
        onReconnected: (ref) {
          ref.invalidate(searchResultsProvider);
          ref.invalidate(featuredPropertiesProvider);
          ref.invalidate(recentPropertiesProvider);
          ref.invalidate(neighbourhoodsProvider);
          ref.invalidate(myEnquiriesProvider);
        },
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
