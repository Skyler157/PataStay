import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/location/location_service.dart';
import '../../../core/widgets/form_widgets.dart';
import 'listing_editor_screen.dart';

typedef StepSaved = void Function();

/// Shared layout: scrollable form with a "Save and continue" bar.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.intro,
    required this.children,
    required this.onSave,
    this.busy = false,
    this.saveLabel = 'Save and continue',
  });

  final String intro;
  final List<Widget> children;
  final VoidCallback? onSave;
  final bool busy;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.lg, Space.gutter, Space.xxl),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Text(intro, style: context.text.bodyLarge?.copyWith(color: context.palette.mutedText)),
            Gap.xl,
            ...children,
          ],
        ),
      ),
      Material(
        color: context.colors.surface,
        elevation: 6,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.md, Space.gutter, Space.md),
            child: SizedBox(width: double.infinity, child: BusyButton(label: saveLabel, busy: busy, onPressed: onSave)),
          ),
        ),
      ),
    ]);
  }
}

/// Runs a save, shows server errors, and reports success.
mixin _Saving<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool busy = false;

  Future<void> save(Future<void> Function() action, VoidCallback onSaved) async {
    setState(() => busy = true);
    try {
      await action();
      if (mounted) onSaved();
    } on AppFailure catch (failure) {
      if (mounted) context.showFailure(failure);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

// ---------------------------------------------------------------------------
// 1. Basics
// ---------------------------------------------------------------------------
class BasicsStep extends ConsumerStatefulWidget {
  const BasicsStep({super.key, required this.listing, required this.onSaved});

  final HostListing listing;
  final StepSaved onSaved;

  @override
  ConsumerState<BasicsStep> createState() => _BasicsStepState();
}

class _BasicsStepState extends ConsumerState<BasicsStep> with _Saving {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.listing.property.title);
  late final _description = TextEditingController(text: widget.listing.property.description);
  late PropertyType? _type = widget.listing.property.propertyType;

  static final _types = [
    ...PropertyType.featured,
    ...PropertyType.values.where((t) => !PropertyType.featured.contains(t)),
  ];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      intro: 'Tell guests what kind of place this is. A clear title and an honest description get more enquiries.',
      busy: busy,
      onSave: () {
        if (!_form.currentState!.validate()) return;
        save(
          () => ref.read(hostRepositoryProvider).saveDetails(widget.listing.id, {
            'title': _title.text.trim(),
            'description': _description.text.trim(),
            'property_type': _type!.dbValue,
          }),
          widget.onSaved,
        );
      },
      children: [
        Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(
              controller: _title,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Bright studio near Yaya Centre'),
              validator: (v) => (v ?? '').trim().length < 10 ? 'Use at least 10 characters' : null,
            ),
            Gap.md,
            DropdownButtonFormField<PropertyType>(
              initialValue: _type,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Type of place'),
              items: [for (final t in _types) DropdownMenuItem(value: t, child: Text(t.label))],
              onChanged: (t) => setState(() => _type = t),
              validator: (t) => t == null ? 'Choose the type of place' : null,
            ),
            Gap.lg,
            TextFormField(
              controller: _description,
              maxLength: 5000,
              minLines: 5,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                hintText: 'What makes it comfortable? Water and power backup? Nearby shops and matatu stages?',
              ),
              validator: (v) => (v ?? '').trim().length < 50 ? 'Use at least 50 characters so guests know what to expect' : null,
            ),
          ]),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Location
// ---------------------------------------------------------------------------
class LocationStep extends ConsumerStatefulWidget {
  const LocationStep({super.key, required this.listing, required this.onSaved});

  final HostListing listing;
  final StepSaved onSaved;

  @override
  ConsumerState<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends ConsumerState<LocationStep> with _Saving {
  late String? _neighbourhoodId = widget.listing.property.neighbourhood?.id;
  late final _area = TextEditingController(text: widget.listing.property.addressOrAreaDescription ?? '');
  late LatLng? _pin = widget.listing.hasExactLocation
      ? LatLng(widget.listing.exactLatitude!, widget.listing.exactLongitude!)
      : null;
  final _map = MapController();
  bool _locating = false;

  @override
  void dispose() {
    _area.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final p = await ref.read(locationServiceProvider).current();
      final point = LatLng(p.latitude, p.longitude);
      setState(() => _pin = point);
      _map.move(point, 16);
    } on AppFailure catch (failure) {
      if (mounted) context.showFailure(failure);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final neighbourhoods = ref.watch(neighbourhoodsProvider).value ?? const [];
    final config = ref.watch(appConfigProvider);
    final hood = neighbourhoods.where((n) => n.id == _neighbourhoodId).firstOrNull;
    final centre = _pin ??
        (hood?.latitude != null ? LatLng(hood!.latitude!, hood.longitude!) : const LatLng(-1.2864, 36.8172));

    return StepScaffold(
      intro: 'Choose the area and drop a pin on the building. Guests only ever see an approximate circle, '
          'never your exact pin. You share the address with a guest yourself.',
      busy: busy,
      onSave: () {
        if (_neighbourhoodId == null) {
          context.showMessage('Choose the neighbourhood');
          return;
        }
        save(() async {
          final repo = ref.read(hostRepositoryProvider);
          await repo.saveDetails(widget.listing.id, {
            'neighbourhood_id': _neighbourhoodId,
            'address_or_area_description': _area.text.trim().isEmpty ? null : _area.text.trim(),
          });
          if (_pin != null) {
            await repo.saveLocation(widget.listing.id, latitude: _pin!.latitude, longitude: _pin!.longitude);
          }
        }, widget.onSaved);
      },
      children: [
        DropdownButtonFormField<String>(
          initialValue: _neighbourhoodId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Neighbourhood'),
          items: [for (final n in neighbourhoods) DropdownMenuItem(value: n.id, child: Text(n.name))],
          onChanged: (id) {
            setState(() => _neighbourhoodId = id);
            final n = neighbourhoods.where((x) => x.id == id).firstOrNull;
            if (_pin == null && n?.latitude != null) _map.move(LatLng(n!.latitude!, n.longitude!), 15);
          },
        ),
        Gap.lg,
        TextFormField(
          controller: _area,
          maxLength: 300,
          decoration: const InputDecoration(
            labelText: 'Area description (shown to guests)',
            hintText: 'e.g. Off Argwings Kodhek Road, near Yaya Centre',
            helperText: 'A landmark or road, not your house number',
          ),
        ),
        Gap.lg,
        Text('Pin on the map (private)', style: context.text.titleSmall),
        Text(_pin == null ? 'Tap the map where the building is.' : 'Pin set. Tap elsewhere to move it.',
            style: context.text.bodySmall),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _locating ? null : _useMyLocation,
            icon: const Icon(Icons.my_location_rounded),
            label: const Text('I am at the place right now'),
          ),
        ),
        Gap.sm,
        if (config.mapsEnabled)
          ClipRRect(
            borderRadius: BorderRadius.circular(Radii.md),
            child: SizedBox(
              height: 300,
              child: FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: centre,
                  initialZoom: _pin == null ? 14 : 16,
                  onTap: (_, point) => setState(() => _pin = point),
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                ),
                children: [
                  TileLayer(urlTemplate: config.mapTileUrl, userAgentPackageName: 'com.patastay.app'),
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
                  RichAttributionWidget(
                    showFlutterMapAttribution: false,
                    attributions: [TextSourceAttribution(config.mapAttribution)],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Rooms & guests
// ---------------------------------------------------------------------------
class RoomsStep extends ConsumerStatefulWidget {
  const RoomsStep({super.key, required this.listing, required this.onSaved});

  final HostListing listing;
  final StepSaved onSaved;

  @override
  ConsumerState<RoomsStep> createState() => _RoomsStepState();
}

class _RoomsStepState extends ConsumerState<RoomsStep> with _Saving {
  late int _bedrooms = widget.listing.property.bedrooms ??
      (widget.listing.property.propertyType == PropertyType.studio ? 0 : 1);
  late double _bathrooms = widget.listing.property.bathrooms ?? 1;
  late int _guests = widget.listing.property.maximumGuests ?? 2;
  late int _minNights = widget.listing.property.minimumNights;

  Widget _counter(String label, String value, {required VoidCallback? onMinus, required VoidCallback? onPlus, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: context.text.titleSmall),
            if (hint != null) Text(hint, style: context.text.bodySmall),
          ]),
        ),
        IconButton.outlined(tooltip: 'Less', onPressed: onMinus, icon: const Icon(Icons.remove_rounded)),
        SizedBox(width: 56, child: Text(value, textAlign: TextAlign.center, style: context.text.titleMedium)),
        IconButton.outlined(tooltip: 'More', onPressed: onPlus, icon: const Icon(Icons.add_rounded)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    String bath(double b) => b % 1 == 0 ? b.toInt().toString() : b.toString();
    return StepScaffold(
      intro: 'How big is the place, and how many people can stay?',
      busy: busy,
      onSave: () => save(
        () => ref.read(hostRepositoryProvider).saveDetails(widget.listing.id, {
          'bedrooms': _bedrooms,
          'bathrooms': _bathrooms,
          'maximum_guests': _guests,
          'minimum_nights': _minNights,
        }),
        widget.onSaved,
      ),
      children: [
        _counter('Bedrooms', _bedrooms == 0 ? 'Studio' : '$_bedrooms',
            hint: '0 means a studio or bedsitter',
            onMinus: _bedrooms > 0 ? () => setState(() => _bedrooms--) : null,
            onPlus: _bedrooms < 20 ? () => setState(() => _bedrooms++) : null),
        _counter('Bathrooms', bath(_bathrooms),
            hint: 'Use .5 for a guest toilet without a shower',
            onMinus: _bathrooms > 0 ? () => setState(() => _bathrooms -= 0.5) : null,
            onPlus: _bathrooms < 20 ? () => setState(() => _bathrooms += 0.5) : null),
        _counter('Maximum guests', '$_guests',
            onMinus: _guests > 1 ? () => setState(() => _guests--) : null,
            onPlus: _guests < 30 ? () => setState(() => _guests++) : null),
        _counter('Minimum stay', '$_minNights night${_minNights == 1 ? '' : 's'}',
            onMinus: _minNights > 1 ? () => setState(() => _minNights--) : null,
            onPlus: _minNights < 90 ? () => setState(() => _minNights++) : null),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Pricing
// ---------------------------------------------------------------------------
class PricingStep extends ConsumerStatefulWidget {
  const PricingStep({super.key, required this.listing, required this.onSaved});

  final HostListing listing;
  final StepSaved onSaved;

  @override
  ConsumerState<PricingStep> createState() => _PricingStepState();
}

class _PricingStepState extends ConsumerState<PricingStep> with _Saving {
  final _form = GlobalKey<FormState>();
  late final _rate = TextEditingController(text: _fmt(widget.listing.property.nightlyRate));
  late final _cleaning = TextEditingController(text: _fmt(widget.listing.property.cleaningFee));
  late final _deposit = TextEditingController(text: _fmt(widget.listing.property.refundableDeposit));

  static String _fmt(double v) => v <= 0 ? '' : v.toStringAsFixed(0);
  static double? _parse(String s) => double.tryParse(s.replaceAll(',', '').trim());

  @override
  void dispose() {
    _rate.dispose();
    _cleaning.dispose();
    _deposit.dispose();
    super.dispose();
  }

  FormFieldValidator<String> _money({required bool required, double max = 1000000}) {
    return (v) {
      final text = (v ?? '').trim();
      if (text.isEmpty) return required ? 'Enter the nightly rate' : null;
      final n = _parse(text);
      if (n == null || n < 0) return 'Enter an amount in shillings';
      if (required && n <= 0) return 'The rate must be more than 0';
      if (n > max) return 'That amount is too high';
      return null;
    };
  }

  @override
  Widget build(BuildContext context) {
    final rate = _parse(_rate.text) ?? 0;
    final cleaning = _parse(_cleaning.text) ?? 0;
    final deposit = _parse(_deposit.text) ?? 0;
    final inputs = [FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))];

    return StepScaffold(
      intro: 'Set your price in Kenyan shillings. Guests always see the full total before contacting you, '
          'so include any fee here rather than adding it later.',
      busy: busy,
      onSave: () {
        if (!_form.currentState!.validate()) return;
        save(
          () => ref.read(hostRepositoryProvider).saveDetails(widget.listing.id, {
            'nightly_rate': rate,
            'cleaning_fee': cleaning,
            'refundable_deposit': deposit,
          }),
          widget.onSaved,
        );
      },
      children: [
        Form(
          key: _form,
          onChanged: () => setState(() {}),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(
              controller: _rate,
              keyboardType: TextInputType.number,
              inputFormatters: inputs,
              decoration: const InputDecoration(labelText: 'Price per night', prefixText: 'KES '),
              validator: _money(required: true),
            ),
            Gap.lg,
            TextFormField(
              controller: _cleaning,
              keyboardType: TextInputType.number,
              inputFormatters: inputs,
              decoration: const InputDecoration(labelText: 'Cleaning fee per stay (optional)', prefixText: 'KES '),
              validator: _money(required: false),
            ),
            Gap.lg,
            TextFormField(
              controller: _deposit,
              keyboardType: TextInputType.number,
              inputFormatters: inputs,
              decoration: const InputDecoration(
                labelText: 'Refundable deposit (optional)',
                prefixText: 'KES ',
                helperText: 'Returned after checkout if nothing is damaged',
              ),
              validator: _money(required: false, max: 10000000),
            ),
          ]),
        ),
        if (rate > 0) ...[
          Gap.xl,
          InfoBanner(
            title: 'What guests will see for 2 nights',
            message: '${Money.kes(rate)} × 2 nights = ${Money.kes(rate * 2)}'
                '${cleaning > 0 ? ' + ${Money.kes(cleaning)} cleaning' : ''}'
                ' → ${Money.kes(rate * 2 + cleaning)} total'
                '${deposit > 0 ? ', plus a ${Money.kes(deposit)} refundable deposit' : ''}.',
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Amenities
// ---------------------------------------------------------------------------
class AmenitiesStep extends ConsumerStatefulWidget {
  const AmenitiesStep({super.key, required this.listing, required this.onSaved});

  final HostListing listing;
  final StepSaved onSaved;

  @override
  ConsumerState<AmenitiesStep> createState() => _AmenitiesStepState();
}

class _AmenitiesStepState extends ConsumerState<AmenitiesStep> with _Saving {
  late final Set<String> _selected = {...widget.listing.amenityIds};

  static const _categoryTitles = {
    'essentials': 'Essentials',
    'safety': 'Safety',
    'comfort': 'Comfort',
    'building': 'Building',
    'services': 'Services',
    'policies': 'Policies',
  };

  @override
  Widget build(BuildContext context) {
    final amenities = ref.watch(amenitiesProvider).value ?? const [];
    final byCategory = <String, List<Amenity>>{};
    for (final a in amenities) {
      byCategory.putIfAbsent(a.category, () => []).add(a);
    }
    return StepScaffold(
      intro: 'Tick only what the place really has. Guests filter by these, and wrong ones lead to reports.',
      busy: busy,
      onSave: () => save(() => ref.read(hostRepositoryProvider).setAmenities(widget.listing.id, _selected), widget.onSaved),
      children: [
        for (final entry in byCategory.entries) ...[
          Text(_categoryTitles[entry.key] ?? entry.key, style: context.text.titleSmall),
          Gap.sm,
          Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
            for (final a in entry.value)
              FilterChip(
                label: Text(a.name),
                selected: _selected.contains(a.id),
                onSelected: (on) => setState(() => on ? _selected.add(a.id) : _selected.remove(a.id)),
              ),
          ]),
          Gap.xl,
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 7. Check-in & rules
// ---------------------------------------------------------------------------
class RulesStep extends ConsumerStatefulWidget {
  const RulesStep({super.key, required this.listing, required this.onSaved});

  final HostListing listing;
  final StepSaved onSaved;

  @override
  ConsumerState<RulesStep> createState() => _RulesStepState();
}

class _RulesStepState extends ConsumerState<RulesStep> with _Saving {
  late TimeOfDay? _checkIn = _parseTime(widget.listing.property.checkInTime);
  late TimeOfDay? _checkOut = _parseTime(widget.listing.property.checkOutTime);
  late final _checkInInfo = TextEditingController(text: widget.listing.property.checkInInformation ?? '');
  late final _checkOutInfo = TextEditingController(text: widget.listing.property.checkOutInformation ?? '');
  late final _rules = TextEditingController(text: widget.listing.property.houseRules ?? '');

  static TimeOfDay? _parseTime(String? t) {
    if (t == null || t.length < 5) return null;
    return TimeOfDay(hour: int.parse(t.substring(0, 2)), minute: int.parse(t.substring(3, 5)));
  }

  static String? _toDb(TimeOfDay? t) =>
      t == null ? null : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _checkInInfo.dispose();
    _checkOutInfo.dispose();
    _rules.dispose();
    super.dispose();
  }

  Future<void> _pick(bool checkIn) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (checkIn ? _checkIn : _checkOut) ?? TimeOfDay(hour: checkIn ? 14 : 10, minute: 0),
      helpText: checkIn ? 'Check-in from' : 'Checkout by',
    );
    if (picked != null) setState(() => checkIn ? _checkIn = picked : _checkOut = picked);
  }

  @override
  Widget build(BuildContext context) {
    String show(TimeOfDay? t) => t == null ? 'Not set' : t.format(context);
    String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    return StepScaffold(
      intro: 'Clear arrival details and rules avoid surprises for you and your guests.',
      busy: busy,
      onSave: () => save(
        () => ref.read(hostRepositoryProvider).saveDetails(widget.listing.id, {
          'check_in_time': _toDb(_checkIn),
          'check_out_time': _toDb(_checkOut),
          'check_in_information': text(_checkInInfo),
          'check_out_information': text(_checkOutInfo),
          'house_rules': text(_rules),
        }),
        widget.onSaved,
      ),
      children: [
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pick(true),
              icon: const Icon(Icons.login_rounded),
              label: Text('Check-in from: ${show(_checkIn)}'),
            ),
          ),
        ]),
        Gap.sm,
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pick(false),
              icon: const Icon(Icons.logout_rounded),
              label: Text('Checkout by: ${show(_checkOut)}'),
            ),
          ),
        ]),
        Gap.lg,
        TextFormField(
          controller: _checkInInfo,
          maxLength: 1000,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'How guests get in (optional)',
            hintText: 'e.g. The caretaker meets you at the gate',
            alignLabelWithHint: true,
          ),
        ),
        Gap.md,
        TextFormField(
          controller: _checkOutInfo,
          maxLength: 1000,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Checkout instructions (optional)',
            hintText: 'e.g. Leave the keys with the caretaker',
            alignLabelWithHint: true,
          ),
        ),
        Gap.md,
        TextFormField(
          controller: _rules,
          maxLength: 2000,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'House rules (optional)',
            hintText: 'e.g. No smoking indoors. No parties. Quiet hours 10pm to 7am.',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 8. Contact number
// ---------------------------------------------------------------------------
class ContactStep extends ConsumerStatefulWidget {
  const ContactStep({super.key, required this.listing, required this.onSaved});

  final HostListing listing;
  final StepSaved onSaved;

  @override
  ConsumerState<ContactStep> createState() => _ContactStepState();
}

class _ContactStepState extends ConsumerState<ContactStep> with _Saving {
  final _form = GlobalKey<FormState>();
  late final _phone = TextEditingController(
    text: widget.listing.contactPhone == null ? '' : PhoneNumbers.format(widget.listing.contactPhone!),
  );
  late final _whatsapp = TextEditingController(
    text: widget.listing.whatsappPhone == null ? '' : PhoneNumbers.format(widget.listing.whatsappPhone!),
  );
  late bool _same = widget.listing.whatsappPhone == null || widget.listing.whatsappPhone == widget.listing.contactPhone;

  @override
  void dispose() {
    _phone.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = widget.listing.status == PropertyStatus.published || widget.listing.status == PropertyStatus.paused;
    return StepScaffold(
      intro: 'Guests reach you on this number by WhatsApp or a call. It is only shown to signed-in guests, '
          'one at a time, and PataStay records each contact to stop scrapers.',
      busy: busy,
      onSave: () {
        if (!_form.currentState!.validate()) return;
        final phone = PhoneNumbers.normalize(_phone.text)!;
        final whatsapp = _same ? phone : PhoneNumbers.normalize(_whatsapp.text)!;
        save(
          () => ref.read(hostRepositoryProvider).saveContact(widget.listing.id, phone: phone, whatsapp: whatsapp),
          widget.onSaved,
        );
      },
      children: [
        if (live) ...[
          const InfoBanner(
            tone: BannerTone.warning,
            message: 'Changing the number of a live listing sends it back for a quick review. '
                'This protects guests from people taking over listings.',
          ),
          Gap.lg,
        ],
        Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number', hintText: '0712 345 678'),
              validator: Validators.phone(isRequired: true),
            ),
            Gap.sm,
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use the same number for WhatsApp'),
              value: _same,
              onChanged: (v) => setState(() => _same = v),
            ),
            if (!_same)
              TextFormField(
                controller: _whatsapp,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'WhatsApp number', hintText: '0712 345 678'),
                validator: Validators.phone(isRequired: true),
              ),
          ]),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 9. Review & submit
// ---------------------------------------------------------------------------
class ReviewStep extends ConsumerStatefulWidget {
  const ReviewStep({super.key, required this.listing, required this.onFix, required this.onDone});

  final HostListing listing;
  final ValueChanged<EditorStep> onFix;
  final VoidCallback onDone;

  @override
  ConsumerState<ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends ConsumerState<ReviewStep> with _Saving {
  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final missing = l.missingForSubmission;
    final submittable = l.canSubmit;

    final (String intro, String label, VoidCallback? action) = switch (l.status) {
      _ when submittable && missing.isNotEmpty => (
          'Almost there. Add the items below, then submit your listing for review.',
          'Submit for review',
          null,
        ),
      _ when submittable => (
          'Everything is ready. Our team checks every listing before guests can see it, usually within a day or two.',
          'Submit for review',
          () => save(() async {
                await ref.read(hostRepositoryProvider).submitForReview(l.id);
                if (mounted) this.context.showMessage('Submitted for review. We will let you know when it is live.');
              }, widget.onDone),
        ),
      PropertyStatus.pendingReview => ('Your listing is in review. Your changes are saved.', 'Done', widget.onDone),
      _ => ('Your changes are saved and live for guests.', 'Done', widget.onDone),
    };

    return StepScaffold(
      intro: intro,
      busy: busy,
      saveLabel: label,
      onSave: action,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Space.lg),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.displayTitle, style: context.text.titleMedium),
              Text(
                [l.reference, l.property.propertyType?.label, l.property.neighbourhood?.name].whereType<String>().join(' · '),
                style: context.text.bodySmall,
              ),
              Gap.sm,
              if (l.property.nightlyRate > 0) Text('${Money.kes(l.property.nightlyRate)} / night', style: context.text.titleSmall),
              Text(l.property.roomsSummary, style: context.text.bodyMedium),
              Text('${l.property.images.length} photo${l.property.images.length == 1 ? '' : 's'}', style: context.text.bodySmall),
            ]),
          ),
        ),
        Gap.lg,
        if (missing.isEmpty)
          const InfoBanner(tone: BannerTone.success, message: 'Everything required is filled in.')
        else ...[
          Text('Still needed', style: context.text.titleSmall),
          Gap.sm,
          for (final m in missing)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.error_outline_rounded, color: context.palette.warning),
              title: Text(m),
              trailing: TextButton(onPressed: () => widget.onFix(EditorStep.forMissing(m)), child: const Text('Add')),
            ),
        ],
        if (l.status == PropertyStatus.rejected && l.rejectionReason != null) ...[
          Gap.lg,
          InfoBanner(tone: BannerTone.danger, title: 'Reviewer\'s note', message: l.rejectionReason!),
        ],
        Gap.lg,
        Text(
          'By submitting, you confirm the photos are of this place, the price is what guests will pay, '
          'and you are the owner or allowed to rent it out.',
          style: context.text.bodySmall,
        ),
      ],
    );
  }
}
