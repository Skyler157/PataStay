import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:patastay_core/patastay_core.dart';

import '../application/property_providers.dart';
import 'filters_sheet.dart';
import 'near_me.dart';
import 'widgets/maps.dart';
import 'widgets/property_widgets.dart';
import 'widgets/stay_date_picker.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _query = TextEditingController(
    text: ref.read(searchFiltersProvider).query,
  );
  final _scroll = ScrollController();
  Timer? _debounce;
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) {
        ref.read(searchResultsProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref
          .read(searchFiltersProvider.notifier)
          .update((f) => f.copyWith(query: value));
    });
  }

  Future<void> _pickDates() async {
    final filters = ref.read(searchFiltersProvider);
    final range = await pickStayDates(context, checkIn: filters.checkIn, checkOut: filters.checkOut);
    if (range == null) return;
    ref.read(searchFiltersProvider.notifier).update((f) => f.copyWith(checkIn: range.start, checkOut: range.end));
  }

  Future<void> _pickGuests() async {
    final current = ref.read(searchFiltersProvider).guests ?? 1;
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => _GuestPicker(initial: current),
    );
    if (picked != null) {
      ref.read(searchFiltersProvider.notifier).update((f) => f.copyWith(guests: picked));
    }
  }

  Future<void> _pickBudget() async {
    final band = await showModalBottomSheet<BudgetBand?>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final b in [
              const BudgetBand('Any budget'),
              ...BudgetBand.presets,
            ])
              ListTile(
                title: Text(b.label),
                onTap: () => Navigator.pop(context, b),
              ),
          ],
        ),
      ),
    );
    if (band != null) {
      ref
          .read(searchFiltersProvider.notifier)
          .update((f) => f.copyWith(minPrice: band.min, maxPrice: band.max));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(searchFiltersProvider);
    final results = ref.watch(searchResultsProvider);
    final budget = BudgetBand.presets.where(filters.matchesBudget).firstOrNull;
    final hasCustomBudget =
        budget == null &&
        (filters.minPrice != null || filters.maxPrice != null);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _query,
          autofocus:
              filters.query.isEmpty &&
              filters.advancedCount == 0 &&
              !filters.featuredOnly,
          textInputAction: TextInputAction.search,
          onChanged: _onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Area, estate or place name',
            prefixIcon: const Icon(Icons.search_rounded),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: Space.md),
            suffixIcon: _query.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _query.clear();
                      _onQueryChanged('');
                      setState(() {});
                    },
                  ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: _showMap ? 'Show list' : 'Show map',
            icon: Icon(_showMap ? Icons.view_list_rounded : Icons.map_outlined),
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          if (!filters.isNearMe)
            PopupMenuButton<SearchSort>(
              tooltip: 'Sort',
              icon: const Icon(Icons.sort_rounded),
              initialValue: filters.sort,
              onSelected: (s) => ref
                  .read(searchFiltersProvider.notifier)
                  .update((f) => f.copyWith(sort: s)),
              itemBuilder: (_) => [
                for (final s in SearchSort.values.where(
                  (s) => s != SearchSort.nearest,
                ))
                  PopupMenuItem(value: s, child: Text(s.label)),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              Space.xs,
              Space.gutter,
              Space.sm,
            ),
            child: Row(
              spacing: Space.sm,
              children: [
                FilterChip(
                  label: Text(
                    filters.isNearMe
                        ? 'Near me · ${filters.radiusKm.toStringAsFixed(0)} km'
                        : 'Near me',
                  ),
                  avatar: const Icon(Icons.near_me_outlined, size: 16),
                  selected: filters.isNearMe,
                  onSelected: (_) => filters.isNearMe
                      ? showNearMeSheet(context, ref)
                      : startNearMe(context, ref),
                ),
                FilterChip(
                  label: Text(
                    filters.hasDates
                        ? '${Dates.shortDay(filters.checkIn!)} – ${Dates.shortDay(filters.checkOut!)}'
                        : 'Dates',
                  ),
                  avatar: const Icon(Icons.calendar_today_outlined, size: 16),
                  selected: filters.hasDates,
                  onSelected: (_) => _pickDates(),
                  onDeleted: filters.hasDates
                      ? () => ref
                            .read(searchFiltersProvider.notifier)
                            .update(
                              (f) => f.copyWith(checkIn: null, checkOut: null),
                            )
                      : null,
                ),
                FilterChip(
                  label: Text(
                    filters.guests == null
                        ? 'Guests'
                        : '${filters.guests} guest${filters.guests == 1 ? '' : 's'}',
                  ),
                  avatar: const Icon(Icons.group_outlined, size: 16),
                  selected: filters.guests != null,
                  onSelected: (_) => _pickGuests(),
                ),
                FilterChip(
                  label: Text(
                    budget?.label ??
                        (hasCustomBudget ? 'Custom budget' : 'Budget'),
                  ),
                  avatar: const Icon(Icons.payments_outlined, size: 16),
                  selected: budget != null || hasCustomBudget,
                  onSelected: (_) => _pickBudget(),
                ),
                FilterChip(
                  label: Text(
                    filters.advancedCount == 0
                        ? 'Filters'
                        : 'Filters · ${filters.advancedCount}',
                  ),
                  avatar: const Icon(Icons.tune_rounded, size: 16),
                  selected: filters.advancedCount > 0,
                  onSelected: (_) => showFiltersSheet(context),
                ),
              ],
            ),
          ),
          if (filters.featuredOnly)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                0,
                Space.gutter,
                Space.sm,
              ),
              child: Row(
                children: [
                  const PataBadge(label: 'Featured stays only'),
                  TextButton(
                    onPressed: () => ref
                        .read(searchFiltersProvider.notifier)
                        .update((f) => f.copyWith(featuredOnly: false)),
                    child: const Text('Show all'),
                  ),
                ],
              ),
            ),
          const Divider(),
          Expanded(
            child: switch (results) {
              AsyncData(:final value) when value.items.isEmpty => EmptyView(
                icon: Icons.search_off_rounded,
                title: 'No stays match',
                message: filters.isNearMe
                    ? 'Nothing within ${filters.radiusKm.toStringAsFixed(0)} km. Try a wider radius or fewer filters.'
                    : filters.hasDates
                    ? 'Try other dates, a wider budget or fewer filters.'
                    : 'Try a wider budget, another area or fewer filters.',
                action: OutlinedButton(
                  onPressed: () {
                    _query.clear();
                    ref.read(searchFiltersProvider.notifier).reset();
                  },
                  child: const Text('Clear filters'),
                ),
              ),
              AsyncData(:final value) when _showMap => SearchResultsMap(
                properties: value.items,
                myLocation: filters.isNearMe ? LatLng(filters.nearLatitude!, filters.nearLongitude!) : null,
              ),
              AsyncData(:final value) => RefreshIndicator(
                onRefresh: () => ref.refresh(searchResultsProvider.future),
                child: ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(
                    Space.gutter,
                    Space.md,
                    Space.gutter,
                    Space.xxl,
                  ),
                  itemCount: value.items.length + 2,
                  separatorBuilder: (_, i) => i == 0 ? Gap.sm : Gap.lg,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Text(
                        '${value.items.length}${value.hasMore ? '+' : ''} stay${value.items.length == 1 ? '' : 's'}'
                        ' · ${filters.isNearMe ? 'nearest first' : filters.sort.label}',
                        style: context.text.bodySmall,
                      );
                    }
                    if (i == value.items.length + 1) {
                      return _ListFooter(results: value);
                    }
                    final property = value.items[i - 1];
                    return PropertyCard(
                      property: property,
                      quote: StayQuote.forStay(
                        property,
                        filters.checkIn,
                        filters.checkOut,
                      ),
                    );
                  },
                ),
              ),
              AsyncError(:final error) => ErrorView(
                error: error,
                onRetry: () => ref.invalidate(searchResultsProvider),
              ),
              _ => const LoadingView(message: 'Finding stays'),
            },
          ),
        ],
      ),
    );
  }
}

class _ListFooter extends ConsumerWidget {
  const _ListFooter({required this.results});

  final SearchResults results;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (results.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(Space.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (results.loadMoreError != null) {
      return Center(
        child: TextButton.icon(
          onPressed: () => ref.read(searchResultsProvider.notifier).loadMore(),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(mapToFailure(results.loadMoreError!).message),
        ),
      );
    }
    if (!results.hasMore) {
      return Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Text(
          "That's everything for now",
          textAlign: TextAlign.center,
          style: context.text.bodySmall,
        ),
      );
    }
    return const SizedBox(height: Space.xl);
  }
}

class _GuestPicker extends StatefulWidget {
  const _GuestPicker({required this.initial});

  final int initial;

  @override
  State<_GuestPicker> createState() => _GuestPickerState();
}

class _GuestPickerState extends State<_GuestPicker> {
  late int _guests = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.gutter,
          0,
          Space.gutter,
          Space.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Guests', style: context.text.titleLarge),
            Gap.lg,
            GuestStepper(
              value: _guests,
              onChanged: (v) => setState(() => _guests = v),
            ),
            Gap.xl,
            FilledButton(
              onPressed: () => Navigator.pop(context, _guests),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

/// -  2 guests  + control with 48px targets.
class GuestStepper extends StatelessWidget {
  const GuestStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.max = 30,
  });

  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$value guest${value == 1 ? '' : 's'}',
            style: context.text.titleMedium,
          ),
        ),
        IconButton.outlined(
          tooltip: 'Fewer guests',
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_rounded),
        ),
        Gap.md,
        IconButton.outlined(
          tooltip: 'More guests',
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}
