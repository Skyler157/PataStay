import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patastay_core/patastay_core.dart';

/// Phase 1 Explore tab: branding plus live reference data from the backend.
/// Listing search, filters and property cards are added in Phase 2.
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neighbourhoods = ref.watch(neighbourhoodsProvider);
    final profile = ref.watch(currentProfileProvider).value;
    final firstName = profile?.fullName.trim().split(' ').first;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(neighbourhoodsProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, Space.xxl),
            children: [
              const PataWordmark(size: 22),
              Gap.xl,
              Text(
                firstName == null || firstName.isEmpty ? 'Pata your perfect stay.' : 'Karibu, $firstName.',
                style: context.text.headlineMedium,
              ),
              Gap.sm,
              Text(
                'Affordable, trustworthy short stays across Nairobi.',
                style: context.text.bodyLarge?.copyWith(color: context.palette.mutedText),
              ),
              Gap.xl,
              const InfoBanner(
                title: 'Listing search is on its way',
                message: 'Browsing, filters and property details arrive in the next update. '
                    'You can already create your account.',
              ),
              Gap.xxl,
              Text('Neighbourhoods on PataStay', style: context.text.titleLarge),
              Gap.md,
              switch (neighbourhoods) {
                AsyncData(:final value) when value.isEmpty =>
                  const EmptyView(title: 'No neighbourhoods yet', icon: Icons.map_outlined),
                AsyncData(:final value) => _NeighbourhoodTags(neighbourhoods: value),
                AsyncError(:final error) => SizedBox(
                    height: 280,
                    child: ErrorView(error: error, onRetry: () => ref.invalidate(neighbourhoodsProvider)),
                  ),
                _ => const SizedBox(height: 120, child: LoadingView()),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _NeighbourhoodTags extends StatelessWidget {
  const _NeighbourhoodTags({required this.neighbourhoods});

  final List<Neighbourhood> neighbourhoods;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Space.sm,
      runSpacing: Space.sm,
      children: [
        for (final n in neighbourhoods)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
            decoration: BoxDecoration(
              color: n.isPopular ? context.colors.primaryContainer : context.palette.neutralContainer,
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
            child: Text(
              n.name,
              style: context.text.labelLarge?.copyWith(
                color: n.isPopular ? context.colors.onPrimaryContainer : context.colors.onSurface,
              ),
            ),
          ),
      ],
    );
  }
}
