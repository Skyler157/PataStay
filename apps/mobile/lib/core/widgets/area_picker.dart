import 'package:flutter/material.dart';
import 'package:patastay_core/patastay_core.dart';

/// Full-height, searchable list of areas grouped by city. Returns the chosen
/// ids, or null when dismissed. With [multiple] false it returns one id.
Future<Set<String>?> showAreaPicker(
  BuildContext context, {
  required List<Neighbourhood> areas,
  Set<String> selected = const {},
  bool multiple = false,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.92,
      child: _AreaPicker(areas: areas, selected: selected, multiple: multiple),
    ),
  );
}

class _AreaPicker extends StatefulWidget {
  const _AreaPicker({required this.areas, required this.selected, required this.multiple});

  final List<Neighbourhood> areas;
  final Set<String> selected;
  final bool multiple;

  @override
  State<_AreaPicker> createState() => _AreaPickerState();
}

class _AreaPickerState extends State<_AreaPicker> {
  late final Set<String> _chosen = {...widget.selected};
  String _query = '';

  /// Cities in the order of their first area (Nairobi first), areas by sort order.
  List<(String, List<Neighbourhood>)> get _groups {
    final q = _query.trim().toLowerCase();
    final matches = widget.areas.where((a) =>
        q.isEmpty ||
        a.name.toLowerCase().contains(q) ||
        a.city.toLowerCase().contains(q) ||
        (a.county ?? '').toLowerCase().contains(q));
    final byCity = <String, List<Neighbourhood>>{};
    for (final a in [...matches]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))) {
      byCity.putIfAbsent(a.city, () => []).add(a);
    }
    return [for (final e in byCity.entries) (e.key, e.value)];
  }

  void _tap(Neighbourhood area) {
    if (!widget.multiple) {
      Navigator.pop(context, {area.id});
      return;
    }
    setState(() => _chosen.contains(area.id) ? _chosen.remove(area.id) : _chosen.add(area.id));
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.sm),
        child: Row(children: [
          Expanded(child: Text(widget.multiple ? 'Choose areas' : 'Choose the area', style: context.text.titleLarge)),
          if (widget.multiple && _chosen.isNotEmpty)
            TextButton(onPressed: () => setState(_chosen.clear), child: const Text('Clear')),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
        child: TextField(
          autofocus: false,
          onChanged: (v) => setState(() => _query = v),
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search an area or town',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
      ),
      Gap.sm,
      Expanded(
        child: groups.isEmpty
            ? Padding(
                padding: const EdgeInsets.all(Space.xl),
                child: Text(
                  'No area matches "$_query". If your area is missing, choose the nearest one '
                  'and describe the exact place in the next field.',
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium,
                ),
              )
            : ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  for (final (city, areas) in groups) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, Space.xs),
                      child: Text(city, style: context.text.titleSmall?.copyWith(color: context.colors.primary)),
                    ),
                    for (final a in areas)
                      ListTile(
                        title: Text(a.name),
                        subtitle: a.county == null || a.county == a.city ? null : Text('${a.county} County'),
                        selected: _chosen.contains(a.id),
                        trailing: widget.multiple
                            ? Checkbox(value: _chosen.contains(a.id), onChanged: (_) => _tap(a))
                            : _chosen.contains(a.id)
                                ? const Icon(Icons.check_rounded)
                                : null,
                        onTap: () => _tap(a),
                      ),
                  ],
                ],
              ),
      ),
      if (widget.multiple)
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(Space.gutter),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _chosen),
                child: Text(_chosen.isEmpty ? 'Any area' : 'Done (${_chosen.length} selected)'),
              ),
            ),
          ),
        ),
    ]);
  }
}
