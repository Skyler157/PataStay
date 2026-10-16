import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patastay_core/patastay_core.dart';

import '../application/property_providers.dart';

Future<void> showFiltersSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const FractionallySizedBox(heightFactor: 0.92, child: _FiltersSheet()),
  );
}

/// Edits a draft copy and applies on "Show stays", so results don't reload
/// on every tap (saves data on slow connections).
class _FiltersSheet extends ConsumerStatefulWidget {
  const _FiltersSheet();

  @override
  ConsumerState<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends ConsumerState<_FiltersSheet> {
  late SearchFilters _draft = ref.read(searchFiltersProvider);

  /// Home's main types first, then the rest.
  static final _typeChoices = [
    ...PropertyType.featured,
    ...PropertyType.values.where((t) => !PropertyType.featured.contains(t)),
  ];

  Set<T> _toggle<T>(Set<T> set, T value) => set.contains(value) ? ({...set}..remove(value)) : {...set, value};

  @override
  Widget build(BuildContext context) {
    final neighbourhoods = ref.watch(neighbourhoodsProvider).value ?? const [];
    final amenities = ref.watch(amenitiesProvider).value ?? const [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.sm, 0),
          child: Row(
            children: [
              Expanded(child: Text('Filters', style: context.text.titleLarge)),
              TextButton(
                onPressed: () => setState(() => _draft = SearchFilters(
                      query: _draft.query,
                      checkIn: _draft.checkIn,
                      checkOut: _draft.checkOut,
                      guests: _draft.guests,
                      sort: _draft.sort,
                    )),
                child: const Text('Clear all'),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Space.gutter),
            children: [
              _Group(
                title: 'Neighbourhood',
                child: Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
                  for (final n in neighbourhoods)
                    FilterChip(
                      label: Text(n.name),
                      selected: _draft.neighbourhoodIds.contains(n.id),
                      onSelected: (_) => setState(
                          () => _draft = _draft.copyWith(neighbourhoodIds: _toggle(_draft.neighbourhoodIds, n.id))),
                    ),
                ]),
              ),
              _Group(
                title: 'Budget per night (KES)',
                child: _BudgetFields(
                  min: _draft.minPrice,
                  max: _draft.maxPrice,
                  onChanged: (min, max) => setState(() => _draft = _draft.copyWith(minPrice: min, maxPrice: max)),
                ),
              ),
              _Group(
                title: 'Type of place',
                child: Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
                  for (final t in _typeChoices)
                    FilterChip(
                      label: Text(t.label),
                      selected: _draft.propertyTypes.contains(t),
                      onSelected: (_) =>
                          setState(() => _draft = _draft.copyWith(propertyTypes: _toggle(_draft.propertyTypes, t))),
                    ),
                ]),
              ),
              _Group(
                title: 'Bedrooms',
                child: Wrap(spacing: Space.sm, children: [
                  for (final (label, value) in [('Any', null), ('1+', 1), ('2+', 2), ('3+', 3)])
                    ChoiceChip(
                      label: Text(label),
                      selected: _draft.minBedrooms == value,
                      onSelected: (_) => setState(() => _draft = _draft.copyWith(minBedrooms: value)),
                    ),
                ]),
              ),
              _Group(
                title: 'Must have',
                child: Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
                  for (final a in amenities)
                    FilterChip(
                      label: Text(a.name),
                      selected: _draft.amenityIds.contains(a.id),
                      onSelected: (_) =>
                          setState(() => _draft = _draft.copyWith(amenityIds: _toggle(_draft.amenityIds, a.id))),
                    ),
                ]),
              ),
              _Group(
                title: 'Trust',
                child: Column(children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Verified by PataStay only'),
                    subtitle: const Text('Our team checked the owner and visited the place'),
                    value: _draft.verifiedOnly,
                    onChanged: (v) => setState(() => _draft = _draft.copyWith(verifiedOnly: v)),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Availability confirmed this week'),
                    subtitle: const Text('The host confirmed in the last 7 days'),
                    value: _draft.recentlyConfirmed,
                    onChanged: (v) => setState(() => _draft = _draft.copyWith(recentlyConfirmed: v)),
                  ),
                ]),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.sm, Space.gutter, Space.md),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ref.read(searchFiltersProvider.notifier).replace(_draft);
                  Navigator.pop(context);
                },
                child: const Text('Show stays'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(title, style: context.text.titleSmall), const SizedBox(height: Space.md), child],
      ),
    );
  }
}

class _BudgetFields extends StatefulWidget {
  const _BudgetFields({required this.min, required this.max, required this.onChanged});

  final double? min;
  final double? max;
  final void Function(double? min, double? max) onChanged;

  @override
  State<_BudgetFields> createState() => _BudgetFieldsState();
}

class _BudgetFieldsState extends State<_BudgetFields> {
  late final _min = TextEditingController(text: widget.min?.toStringAsFixed(0) ?? '');
  late final _max = TextEditingController(text: widget.max?.toStringAsFixed(0) ?? '');

  @override
  void didUpdateWidget(covariant _BudgetFields old) {
    super.didUpdateWidget(old);
    if (widget.min == null && old.min != null) _min.clear();
    if (widget.max == null && old.max != null) _max.clear();
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _emit() {
    double? parse(String s) {
      final v = double.tryParse(s.replaceAll(',', '').trim());
      return (v == null || v <= 0) ? null : v;
    }

    widget.onChanged(parse(_min.text), parse(_max.text));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
          for (final band in BudgetBand.presets)
            ActionChip(
              label: Text(band.label),
              onPressed: () {
                _min.text = band.min?.toStringAsFixed(0) ?? '';
                _max.text = band.max?.toStringAsFixed(0) ?? '';
                _emit();
              },
            ),
        ]),
        const SizedBox(height: Space.md),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _min,
                keyboardType: TextInputType.number,
                onChanged: (_) => _emit(),
                decoration: const InputDecoration(labelText: 'Minimum', prefixText: 'KES '),
              ),
            ),
            const SizedBox(width: Space.md),
            Expanded(
              child: TextField(
                controller: _max,
                keyboardType: TextInputType.number,
                onChanged: (_) => _emit(),
                decoration: const InputDecoration(labelText: 'Maximum', prefixText: 'KES '),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
