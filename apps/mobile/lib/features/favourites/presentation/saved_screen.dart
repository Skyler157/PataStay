import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/routing/routes.dart';
import '../../properties/application/property_providers.dart';
import '../../properties/presentation/widgets/property_widgets.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(currentUserIdProvider) != null;
    final saved = ref.watch(savedPropertiesProvider);
    final filters = ref.watch(searchFiltersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: !signedIn
          ? MessageView(
              icon: Icons.favorite_border_rounded,
              title: 'Save places you like',
              message: 'Sign in and tap the heart on any stay to keep it here.',
              action: FilledButton(
                onPressed: () => context.push(Routes.signInReturningTo(Routes.saved)),
                child: const Text('Sign in'),
              ),
            )
          : switch (saved) {
              AsyncData(:final value) when value.isEmpty => EmptyView(
                  icon: Icons.favorite_border_rounded,
                  title: 'Nothing saved yet',
                  message: 'Tap the heart on a stay to save it for later.',
                  action: OutlinedButton(onPressed: () => context.go(Routes.explore), child: const Text('Explore stays')),
                ),
              AsyncData(:final value) => RefreshIndicator(
                  onRefresh: () => ref.refresh(favouritesProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(Space.gutter),
                    itemCount: value.length,
                    separatorBuilder: (_, _) => Gap.lg,
                    itemBuilder: (_, i) => PropertyCard(
                      property: value[i],
                      quote: StayQuote.forStay(value[i], filters.checkIn, filters.checkOut),
                    ),
                  ),
                ),
              AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(favouritesProvider)),
              _ => const LoadingView(),
            },
    );
  }
}
