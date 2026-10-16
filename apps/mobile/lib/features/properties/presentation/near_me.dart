import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/location/location_service.dart';
import '../application/property_providers.dart';

/// Asks for the guest's location and switches search to "Near me".
/// Returns false (after explaining why) when location is unavailable.
Future<bool> startNearMe(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('Finding your location…'), duration: Duration(seconds: 20)));
  try {
    final position = await ref.read(locationServiceProvider).current();
    messenger.hideCurrentSnackBar();
    ref.read(searchFiltersProvider.notifier).update((f) => f.copyWith(
          nearLatitude: position.latitude,
          nearLongitude: position.longitude,
          sort: SearchSort.nearest,
        ));
    return true;
  } on LocationFailure catch (failure) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(failure.message),
        duration: const Duration(seconds: 6),
        action: failure.canOpenSettings
            ? SnackBarAction(label: 'Settings', onPressed: () => ref.read(locationServiceProvider).openSettings())
            : null,
      ));
    return false;
  }
}

/// Radius picker, with an option to turn Near me off.
Future<void> showNearMeSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final current = ref.read(searchFiltersProvider).radiusKm;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.sm),
              child: Text('Stays near you', style: sheetContext.text.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              child: Text(
                'Distances are approximate. Hosts share exact addresses after you contact them.',
                style: sheetContext.text.bodySmall,
              ),
            ),
            for (final km in SearchFilters.radiusChoices)
              ListTile(
                title: Text('Within ${km.toStringAsFixed(0)} km'),
                trailing: km == current ? Icon(Icons.check_rounded, color: sheetContext.colors.primary) : null,
                onTap: () {
                  ref.read(searchFiltersProvider.notifier).update((f) => f.copyWith(radiusKm: km));
                  Navigator.pop(sheetContext);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: const Text('Update my location'),
              onTap: () {
                Navigator.pop(sheetContext);
                startNearMe(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_off_outlined),
              title: const Text('Turn off Near me'),
              onTap: () {
                ref.read(searchFiltersProvider.notifier).update((f) => f.withoutNearMe());
                Navigator.pop(sheetContext);
              },
            ),
          ],
        ),
      );
    },
  );
}
