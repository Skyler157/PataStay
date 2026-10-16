import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/routing/routes.dart';
import '../../properties/application/property_providers.dart';
import '../../properties/presentation/near_me.dart';
import '../../properties/presentation/widgets/property_widgets.dart';

/// Search-first home: one search field, budget chips, areas, categories,
/// then real listings. No promotions wall.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _typeIcons = {
    PropertyType.studio: Icons.weekend_outlined,
    PropertyType.oneBedroom: Icons.single_bed_outlined,
    PropertyType.twoBedroom: Icons.bed_outlined,
    PropertyType.threeBedroomPlus: Icons.king_bed_outlined,
    PropertyType.penthouse: Icons.apartment_rounded,
    PropertyType.villa: Icons.villa_outlined,
    PropertyType.house: Icons.house_outlined,
  };

  void _openSearch(BuildContext context, WidgetRef ref, SearchFilters Function(SearchFilters) change) {
    final base = ref.read(searchFiltersProvider);
    ref.read(searchFiltersProvider.notifier).replace(
          change(SearchFilters(checkIn: base.checkIn, checkOut: base.checkOut, guests: base.guests)),
        );
    context.push(Routes.search);
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(featuredPropertiesProvider);
    ref.invalidate(recentPropertiesProvider);
    ref.invalidate(neighbourhoodsProvider);
    await ref.read(recentPropertiesProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider).value;
    final firstName = profile?.fullName.trim().split(' ').first;
    final neighbourhoods = ref.watch(neighbourhoodsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            padding: const EdgeInsets.only(top: Space.lg, bottom: Space.xxl),
            children: [
              _Padded(child: const PataWordmark(size: 22)),
              Gap.lg,
              _Padded(
                child: Text(
                  firstName == null || firstName.isEmpty ? 'Pata your perfect stay.' : 'Karibu, $firstName.',
                  style: context.text.headlineMedium,
                ),
              ),
              Gap.lg,
              _Padded(child: _SearchEntry(onTap: () => _openSearch(context, ref, (f) => f))),
              Gap.sm,
              _Padded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () async {
                      final base = ref.read(searchFiltersProvider);
                      ref.read(searchFiltersProvider.notifier).replace(
                            SearchFilters(checkIn: base.checkIn, checkOut: base.checkOut, guests: base.guests),
                          );
                      if (await startNearMe(context, ref) && context.mounted) context.push(Routes.search);
                    },
                    icon: const Icon(Icons.near_me_outlined),
                    label: const Text('Stays near me'),
                  ),
                ),
              ),
              Gap.lg,
              _Padded(child: Text('Budget per night', style: context.text.titleSmall)),
              Gap.sm,
              _HorizontalChips(children: [
                for (final band in BudgetBand.presets)
                  ActionChip(
                    label: Text(band.label),
                    onPressed: () =>
                        _openSearch(context, ref, (f) => f.copyWith(minPrice: band.min, maxPrice: band.max)),
                  ),
              ]),
              Gap.xl,
              _SectionTitle(title: 'Popular areas', onSeeAll: () => _openSearch(context, ref, (f) => f)),
              Gap.sm,
              switch (neighbourhoods) {
                AsyncData(:final value) => _AreaRow(
                    areas: [...value.where((n) => n.isPopular), ...value.where((n) => !n.isPopular)],
                    onTap: (n) => _openSearch(context, ref, (f) => f.copyWith(neighbourhoodIds: {n.id})),
                  ),
                AsyncError() => _Padded(
                    child: TextButton.icon(
                      onPressed: () => ref.invalidate(neighbourhoodsProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Could not load areas. Try again'),
                    ),
                  ),
                _ => const SizedBox(height: 84, child: LoadingView()),
              },
              Gap.xl,
              _Padded(child: Text('Browse by type', style: context.text.titleMedium)),
              Gap.sm,
              _HorizontalChips(children: [
                for (final type in PropertyType.featured)
                  ActionChip(
                    avatar: Icon(_typeIcons[type], size: 18),
                    label: Text(type.label),
                    onPressed: () => _openSearch(context, ref, (f) => f.copyWith(propertyTypes: {type})),
                  ),
              ]),
              Gap.xl,
              _ListingRow(
                title: 'Featured stays',
                provider: featuredPropertiesProvider,
                onSeeAll: () => _openSearch(context, ref, (f) => f.copyWith(featuredOnly: true)),
                hideWhenEmpty: true,
              ),
              _ListingRow(
                title: 'Recently added',
                provider: recentPropertiesProvider,
                onSeeAll: () => _openSearch(context, ref, (f) => f.copyWith(sort: SearchSort.newest)),
              ),
              Gap.lg,
              _Padded(
                child: OutlinedButton.icon(
                  onPressed: () => _openSearch(context, ref, (f) => f),
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('See all stays'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Padded extends StatelessWidget {
  const _Padded({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: Space.gutter), child: child);
}

class _SearchEntry extends StatelessWidget {
  const _SearchEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Search stays',
      child: Material(
        color: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          side: BorderSide(color: context.colors.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(Radii.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: Space.md + 2),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: context.colors.primary),
                Gap.md,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Where in Nairobi?', style: context.text.titleSmall),
                      Text('Area, estate or place name · dates · guests', style: context.text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizontalChips extends StatelessWidget {
  const _HorizontalChips({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
      child: Row(spacing: Space.sm, children: children),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: Space.gutter, right: Space.sm),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.text.titleMedium)),
          if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      ),
    );
  }
}

class _AreaRow extends StatelessWidget {
  const _AreaRow({required this.areas, required this.onTap});

  final List<Neighbourhood> areas;
  final ValueChanged<Neighbourhood> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
        itemCount: areas.length,
        separatorBuilder: (_, _) => Gap.sm,
        itemBuilder: (context, i) {
          final area = areas[i];
          return Material(
            color: i.isEven ? context.colors.primaryContainer : context.colors.secondaryContainer,
            borderRadius: BorderRadius.circular(Radii.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.md),
              onTap: () => onTap(area),
              child: Container(
                width: 120,
                padding: const EdgeInsets.all(Space.md),
                alignment: Alignment.bottomLeft,
                child: Text(
                  area.name,
                  style: context.text.titleSmall?.copyWith(
                    color: i.isEven ? context.colors.onPrimaryContainer : context.colors.onSecondaryContainer,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ListingRow extends ConsumerWidget {
  const _ListingRow({required this.title, required this.provider, required this.onSeeAll, this.hideWhenEmpty = false});

  final String title;
  final FutureProvider<List<Property>> provider;
  final VoidCallback onSeeAll;
  final bool hideWhenEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(provider);
    if (hideWhenEmpty && listings.value?.isEmpty == true) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title, onSeeAll: onSeeAll),
          Gap.sm,
          SizedBox(
            // Photo (150) plus text that grows with the phone's font size.
            height: 150 + MediaQuery.textScalerOf(context).scale(140),
            child: switch (listings) {
              AsyncData(:final value) when value.isEmpty => const _Padded(
                  child: EmptyView(
                    icon: Icons.home_work_outlined,
                    title: 'No stays here yet',
                    message: 'New listings appear once our team has reviewed them.',
                  ),
                ),
              AsyncData(:final value) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                  itemCount: value.length,
                  separatorBuilder: (_, _) => Gap.md,
                  itemBuilder: (_, i) => SizedBox(width: 240, child: PropertyCard(property: value[i], compact: true)),
                ),
              AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(provider)),
              _ => const LoadingView(),
            },
          ),
        ],
      ),
    );
  }
}
