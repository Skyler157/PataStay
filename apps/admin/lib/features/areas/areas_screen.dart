import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../core/admin_widgets.dart';
import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';

/// Neighbourhoods and amenities that hosts pick from and guests filter by.
class AreasScreen extends ConsumerStatefulWidget {
  const AreasScreen({super.key});

  @override
  ConsumerState<AreasScreen> createState() => _AreasScreenState();
}

class _AreasScreenState extends ConsumerState<AreasScreen> {
  bool _amenities = false;

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Areas & amenities',
      subtitle: 'What hosts choose from and guests filter by.',
      maxWidth: 1000,
      actions: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Areas'), icon: Icon(Icons.place_outlined)),
            ButtonSegment(value: true, label: Text('Amenities'), icon: Icon(Icons.checklist_rounded)),
          ],
          selected: {_amenities},
          onSelectionChanged: (s) => setState(() => _amenities = s.first),
        ),
        FilledButton.icon(
          onPressed: () => _amenities ? editAmenity(context, ref, null) : editArea(context, ref, null),
          icon: const Icon(Icons.add_rounded),
          label: Text(_amenities ? 'Add amenity' : 'Add area'),
        ),
      ],
      children: [_amenities ? const _AmenityList() : const _AreaList()],
    );
  }
}

Widget _shownTags(BuildContext context, {required bool active, bool popular = false, bool key = false}) {
  final p = context.palette;
  return Wrap(spacing: Space.xs, runSpacing: Space.xs, children: [
    if (!active) Tag(label: 'Hidden', foreground: context.colors.onSurface, background: p.neutralContainer),
    if (popular) const Tag(label: 'Popular', foreground: PataColors.ink, background: PataColors.saffronContainer),
    if (key) Tag(label: 'Shown on cards', foreground: p.verified, background: p.verifiedContainer),
  ]);
}

class _AreaList extends ConsumerWidget {
  const _AreaList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areas = ref.watch(adminAreasProvider);
    return switch (areas) {
      AsyncData(:final value) when value.isEmpty =>
        const SizedBox(height: 240, child: EmptyView(title: 'No areas yet', icon: Icons.place_outlined)),
      AsyncData(:final value) => Card(
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            for (var i = 0; i < value.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              ListTile(
                onTap: () => editArea(context, ref, value[i]),
                leading: Icon(
                  value[i].latitude == null ? Icons.location_off_outlined : Icons.place_rounded,
                  color: value[i].isActive ? context.colors.primary : context.palette.mutedText,
                ),
                title: Wrap(spacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(value[i].name, style: context.text.titleSmall),
                  _shownTags(context, active: value[i].isActive, popular: value[i].isPopular),
                ]),
                subtitle: Text([
                  '${value[i].listingCount} listing${value[i].listingCount == 1 ? '' : 's'}',
                  value[i].county ?? value[i].city,
                  if (value[i].latitude == null) 'no map location',
                ].join(' · ')),
                trailing: const Icon(Icons.edit_outlined),
              ),
            ],
          ]),
        ),
      AsyncError(:final error) =>
        SizedBox(height: 240, child: ErrorView(error: error, onRetry: () => ref.invalidate(adminAreasProvider))),
      _ => const SizedBox(height: 240, child: LoadingView()),
    };
  }
}

class _AmenityList extends ConsumerWidget {
  const _AmenityList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amenities = ref.watch(adminAmenitiesProvider);
    return switch (amenities) {
      AsyncData(:final value) when value.isEmpty =>
        const SizedBox(height: 240, child: EmptyView(title: 'No amenities yet', icon: Icons.checklist_rounded)),
      AsyncData(:final value) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final category in {...AdminAmenity.categories, ...value.map((a) => a.category)})
            if (value.any((a) => a.category == category)) ...[
              Padding(
                padding: const EdgeInsets.only(top: Space.md, bottom: Space.sm),
                child: Text(_categoryLabel(category), style: context.text.titleMedium),
              ),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  for (final (i, a) in value.where((a) => a.category == category).indexed) ...[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      onTap: () => editAmenity(context, ref, a),
                      title: Wrap(spacing: Space.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
                        Text(a.name, style: context.text.titleSmall),
                        _shownTags(context, active: a.isActive, key: a.isKey),
                      ]),
                      subtitle: Text('${a.listingCount} listing${a.listingCount == 1 ? '' : 's'}'),
                      trailing: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ]),
              ),
            ],
        ]),
      AsyncError(:final error) =>
        SizedBox(height: 240, child: ErrorView(error: error, onRetry: () => ref.invalidate(adminAmenitiesProvider))),
      _ => const SizedBox(height: 240, child: LoadingView()),
    };
  }
}

String _categoryLabel(String c) => c.isEmpty ? 'General' : '${c[0].toUpperCase()}${c.substring(1)}';

/// Nairobi CBD, the default map centre for a new area.
const _nairobi = LatLng(-1.286389, 36.817223);

Future<void> editArea(BuildContext context, WidgetRef ref, AdminArea? area) async {
  final saved = await showDialog<bool>(context: context, builder: (_) => _AreaDialog(area: area));
  if (saved ?? false) {
    ref
      ..invalidate(adminAreasProvider)
      ..invalidate(neighbourhoodsProvider);
  }
}

Future<void> editAmenity(BuildContext context, WidgetRef ref, AdminAmenity? amenity) async {
  final saved = await showDialog<bool>(context: context, builder: (_) => _AmenityDialog(amenity: amenity));
  if (saved ?? false) {
    ref
      ..invalidate(adminAmenitiesProvider)
      ..invalidate(amenitiesProvider);
  }
}

/// Shared save/delete plumbing for the two editors.
mixin _EditorDialog<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  final formKey = GlobalKey<FormState>();
  bool busy = false;

  String get duplicateMessage;

  Future<void> save(Future<void> Function() action, String success) async {
    if (!formKey.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await action();
      if (!mounted) return;
      context.showMessage(success);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => busy = false);
      final failure = mapToFailure(e);
      context.showMessage(failure is ConflictFailure ? duplicateMessage : failure.message);
    }
  }

  Future<void> remove(String name, Future<void> Function() action) async {
    final yes = await confirmAction(context,
        title: 'Delete $name?', message: 'This cannot be undone.', action: 'Delete', destructive: true);
    if (yes) await save(action, '$name deleted.');
  }
}

class _AreaDialog extends ConsumerStatefulWidget {
  const _AreaDialog({this.area});

  final AdminArea? area;

  @override
  ConsumerState<_AreaDialog> createState() => _AreaDialogState();
}

class _AreaDialogState extends ConsumerState<_AreaDialog> with _EditorDialog {
  late final _name = TextEditingController(text: widget.area?.name);
  late final _county = TextEditingController(text: widget.area?.county ?? 'Nairobi');
  late final _sort = TextEditingController(text: '${widget.area?.sortOrder ?? 100}');
  late bool _popular = widget.area?.isPopular ?? false;
  late bool _active = widget.area?.isActive ?? true;
  late LatLng? _pin = widget.area?.latitude == null ? null : LatLng(widget.area!.latitude!, widget.area!.longitude!);

  @override
  String get duplicateMessage => 'An area with this name already exists.';

  @override
  void dispose() {
    _name.dispose();
    _county.dispose();
    _sort.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _fields => {
        'name': _name.text.trim(),
        // The slug is fixed once created: the app links areas by it.
        if (widget.area == null) 'slug': slugify(_name.text),
        'county': _county.text.trim().isEmpty ? null : _county.text.trim(),
        'latitude': _pin == null ? null : double.parse(_pin!.latitude.toStringAsFixed(6)),
        'longitude': _pin == null ? null : double.parse(_pin!.longitude.toStringAsFixed(6)),
        'is_popular': _popular,
        'is_active': _active,
        'sort_order': int.tryParse(_sort.text) ?? 100,
      };

  @override
  Widget build(BuildContext context) {
    final area = widget.area;
    final config = ref.watch(appConfigProvider);
    final repo = ref.read(adminRepositoryProvider);
    return AlertDialog(
      title: Text(area == null ? 'Add an area' : 'Edit ${area.name}'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextFormField(
                controller: _name,
                autofocus: area == null,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Name', hintText: 'For example: Syokimau'),
                validator: (v) => (v ?? '').trim().length < 2 ? 'Enter the area name' : null,
              ),
              TextFormField(controller: _county, maxLength: 60, decoration: const InputDecoration(labelText: 'County')),
              Gap.sm,
              Text('Map location', style: context.text.labelLarge),
              Text('Click the map at the centre of the area. "Near me" search and the area map use it.',
                  style: context.text.bodySmall),
              Gap.sm,
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.md),
                child: SizedBox(
                  height: 240,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _pin ?? _nairobi,
                      initialZoom: _pin == null ? 11 : 13.5,
                      onTap: (_, point) => setState(() => _pin = point),
                    ),
                    children: [
                      TileLayer(urlTemplate: config.mapTileUrl, userAgentPackageName: 'com.patastay.admin', maxNativeZoom: 19),
                      if (_pin != null)
                        MarkerLayer(markers: [
                          Marker(
                            point: _pin!,
                            width: 40,
                            height: 40,
                            alignment: Alignment.topCenter,
                            child: Icon(Icons.location_on_rounded, size: 40, color: context.colors.primary),
                          ),
                        ]),
                      MapCredit(config.mapAttribution),
                    ],
                  ),
                ),
              ),
              Gap.xs,
              Text(
                _pin == null
                    ? 'No location set.'
                    : '${_pin!.latitude.toStringAsFixed(5)}, ${_pin!.longitude.toStringAsFixed(5)}',
                style: context.text.bodySmall,
              ),
              Gap.md,
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _popular,
                onChanged: (v) => setState(() => _popular = v),
                title: const Text('Popular'),
                subtitle: const Text('Shown as a shortcut on Home'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: const Text('Shown in the app'),
                subtitle: const Text('Hidden areas cannot be picked for new listings. Existing listings keep them.'),
              ),
              TextFormField(
                controller: _sort,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Order', helperText: 'Lower numbers are listed first'),
              ),
            ]),
          ),
        ),
      ),
      actions: [
        if (area != null)
          area.listingCount == 0
              ? TextButton(
                  onPressed: busy ? null : () => remove(area.name, () => repo.deleteArea(area.id)),
                  style: TextButton.styleFrom(foregroundColor: context.palette.danger),
                  child: const Text('Delete'),
                )
              : Tooltip(
                  message: 'Used by ${area.listingCount} listing${area.listingCount == 1 ? '' : 's'}. '
                      'Turn off "Shown in the app" instead.',
                  child: const TextButton(onPressed: null, child: Text('Delete')),
                ),
        TextButton(onPressed: busy ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: busy ? null : () => save(() => repo.saveArea(area?.id, _fields), 'Area saved.'),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AmenityDialog extends ConsumerStatefulWidget {
  const _AmenityDialog({this.amenity});

  final AdminAmenity? amenity;

  @override
  ConsumerState<_AmenityDialog> createState() => _AmenityDialogState();
}

class _AmenityDialogState extends ConsumerState<_AmenityDialog> with _EditorDialog {
  late final _name = TextEditingController(text: widget.amenity?.name);
  late final _sort = TextEditingController(text: '${widget.amenity?.sortOrder ?? 500}');
  late String _category = widget.amenity?.category ?? 'comfort';
  late bool _key = widget.amenity?.isKey ?? false;
  late bool _active = widget.amenity?.isActive ?? true;

  @override
  String get duplicateMessage => 'An amenity with this name already exists.';

  @override
  void dispose() {
    _name.dispose();
    _sort.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _fields => {
        'name': _name.text.trim(),
        if (widget.amenity == null) 'slug': slugify(_name.text),
        'category': _category,
        'is_key': _key,
        'is_active': _active,
        'sort_order': int.tryParse(_sort.text) ?? 500,
      };

  @override
  Widget build(BuildContext context) {
    final a = widget.amenity;
    final repo = ref.read(adminRepositoryProvider);
    final categories = {...AdminAmenity.categories, ?a?.category}.toList();
    return AlertDialog(
      title: Text(a == null ? 'Add an amenity' : 'Edit ${a.name}'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(
              controller: _name,
              autofocus: a == null,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Name', hintText: 'For example: Borehole water'),
              validator: (v) => (v ?? '').trim().length < 2 ? 'Enter the amenity name' : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Group'),
              items: [for (final c in categories) DropdownMenuItem(value: c, child: Text(_categoryLabel(c)))],
              onChanged: (c) => setState(() => _category = c!),
            ),
            Gap.sm,
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _key,
              onChanged: (v) => setState(() => _key = v),
              title: const Text('Key amenity'),
              subtitle: const Text('Shown on listing cards in search results. Keep this to the few that matter most.'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              title: const Text('Shown in the app'),
              subtitle: const Text('Hidden amenities cannot be picked any more and disappear from listings.'),
            ),
            TextFormField(
              controller: _sort,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Order', helperText: 'Lower numbers are listed first'),
            ),
          ]),
        ),
      ),
      actions: [
        if (a != null)
          a.listingCount == 0
              ? TextButton(
                  onPressed: busy ? null : () => remove(a.name, () => repo.deleteAmenity(a.id)),
                  style: TextButton.styleFrom(foregroundColor: context.palette.danger),
                  child: const Text('Delete'),
                )
              : Tooltip(
                  message: 'Used by ${a.listingCount} listing${a.listingCount == 1 ? '' : 's'}. '
                      'Turn off "Shown in the app" instead.',
                  child: const TextButton(onPressed: null, child: Text('Delete')),
                ),
        TextButton(onPressed: busy ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: busy ? null : () => save(() => repo.saveAmenity(a?.id, _fields), 'Amenity saved.'),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
