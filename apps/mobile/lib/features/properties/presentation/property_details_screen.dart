import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/routing/routes.dart';
import '../../reports/presentation/report_sheet.dart';
import '../application/property_providers.dart';
import 'contact_sheet.dart';
import 'widgets/maps.dart';
import 'widgets/property_widgets.dart';
import 'widgets/stay_date_picker.dart';

class PropertyDetailsScreen extends ConsumerStatefulWidget {
  const PropertyDetailsScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<PropertyDetailsScreen> createState() =>
      _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends ConsumerState<PropertyDetailsScreen> {
  DateTime? _checkIn;
  DateTime? _checkOut;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(searchFiltersProvider);
    _checkIn = filters.checkIn;
    _checkOut = filters.checkOut;
    ref.read(propertyRepositoryProvider).trackView(widget.propertyId);
  }

  Future<void> _pickDates() async {
    final property = ref.read(propertyDetailsProvider(widget.propertyId)).value;
    final range = await pickStayDates(
      context,
      checkIn: _checkIn,
      checkOut: _checkOut,
      property: property,
    );
    if (range != null && range.end.isAfter(range.start)) {
      setState(() {
        _checkIn = range.start;
        _checkOut = range.end;
      });
      // Keep search in sync so going back shows totals for the same dates.
      ref
          .read(searchFiltersProvider.notifier)
          .update((f) => f.copyWith(checkIn: range.start, checkOut: range.end));
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(propertyDetailsProvider(widget.propertyId));
    return switch (details) {
      AsyncData(:final value?) => _Details(
        property: value,
        checkIn: _checkIn,
        checkOut: _checkOut,
        onPickDates: _pickDates,
      ),
      AsyncData() => Scaffold(
        appBar: AppBar(),
        body: const EmptyView(
          icon: Icons.home_work_outlined,
          title: 'This listing is not available',
          message: 'It may have been paused or removed by the host.',
        ),
      ),
      AsyncError(:final error) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          error: error,
          onRetry: () =>
              ref.invalidate(propertyDetailsProvider(widget.propertyId)),
        ),
      ),
      _ => Scaffold(appBar: AppBar(), body: const LoadingView()),
    };
  }
}

class _Details extends ConsumerWidget {
  const _Details({
    required this.property,
    required this.checkIn,
    required this.checkOut,
    required this.onPickDates,
  });

  final Property property;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final VoidCallback onPickDates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = property;
    final quote = StayQuote.forStay(p, checkIn, checkOut);
    final problems = checkIn == null
        ? const <String>[]
        : stayProblems(p, checkIn: checkIn, checkOut: checkOut);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            automaticallyImplyLeading: false,
            leading: const Padding(
              padding: EdgeInsets.only(left: Space.sm),
              child: _BackButton(),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: Space.sm),
                child: FavouriteButton(propertyId: p.id),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _Gallery(images: p.images),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              Space.lg,
              Space.gutter,
              120,
            ),
            sliver: SliverList.list(
              children: [
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    if (p.verifiedAt != null)
                      VerifiedBadge(verifiedAt: p.verifiedAt!, long: true),
                    if (showSampleLabel(ref, p)) const SampleBadge(),
                    PataBadge(label: p.reference, icon: Icons.tag_rounded),
                  ],
                ),
                if (showSampleLabel(ref, p)) ...[
                  Gap.md,
                  const InfoBanner(
                    tone: BannerTone.warning,
                    message: 'This is sample data for testing PataStay. It is not a real place you can book.',
                  ),
                ],
                Gap.md,
                Text(p.title, style: context.text.headlineSmall),
                Gap.xs,
                Text(
                  [
                    p.propertyType?.label,
                    p.neighbourhood?.name,
                    p.neighbourhood?.city,
                  ].whereType<String>().join(' · '),
                  style: context.text.bodyMedium?.copyWith(
                    color: context.palette.mutedText,
                  ),
                ),
                if (p.addressOrAreaDescription != null) ...[
                  Gap.xs,
                  Text(
                    p.addressOrAreaDescription!,
                    style: context.text.bodySmall,
                  ),
                ],
                Gap.sm,
                Text(p.roomsSummary, style: context.text.bodyMedium),
                Gap.xl,
                _PriceCard(
                  property: p,
                  quote: quote,
                  checkIn: checkIn,
                  checkOut: checkOut,
                  onPickDates: onPickDates,
                ),
                for (final problem in problems) ...[
                  Gap.sm,
                  InfoBanner(tone: BannerTone.warning, message: problem),
                ],
                Gap.xl,
                _Section(
                  title: 'Availability',
                  children: [
                    FreshnessLabel(property: p),
                    if (p.availabilityNote != null &&
                        p.availabilityNote!.trim().isNotEmpty) ...[
                      Gap.xs,
                      Text(p.availabilityNote!, style: context.text.bodyMedium),
                    ],
                    if (p.minimumNights > 1) ...[
                      Gap.xs,
                      Text(
                        'Minimum stay: ${p.minimumNights} nights',
                        style: context.text.bodyMedium,
                      ),
                    ],
                    for (final r
                        in p.unavailableDates
                            .where(
                              (r) => !r.endsOn.isBefore(
                                DateTime.now().subtract(
                                  const Duration(days: 1),
                                ),
                              ),
                            )
                            .take(5)) ...[
                      Gap.xs,
                      Text(
                        'Not available ${Dates.shortDay(r.startsOn)} – ${Dates.shortDay(r.endsOn)}',
                        style: context.text.bodySmall,
                      ),
                    ],
                    Gap.sm,
                    Text(
                      'The host confirms availability directly with you. An enquiry is not a reservation.',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
                _Section(
                  title: "Where you'll be",
                  children: [AreaMap(property: p)],
                ),
                if (p.amenities.isNotEmpty)
                  _Section(
                    title: 'What this place has',
                    children: [
                      Wrap(
                        spacing: Space.sm,
                        runSpacing: Space.sm,
                        children: [
                          for (final a in p.amenities)
                            Chip(
                              label: Text(a.name),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ],
                  ),
                if (p.description.trim().isNotEmpty)
                  _Section(
                    title: 'About this place',
                    children: [
                      Text(p.description, style: context.text.bodyLarge),
                    ],
                  ),
                _Section(
                  title: 'Arriving and leaving',
                  children: [
                    _Fact(
                      icon: Icons.login_rounded,
                      label: 'Check-in',
                      value: _time(p.checkInTime) == null
                          ? 'Ask the host'
                          : 'from ${_time(p.checkInTime)}',
                    ),
                    if (p.checkInInformation != null)
                      Text(
                        p.checkInInformation!,
                        style: context.text.bodyMedium,
                      ),
                    Gap.sm,
                    _Fact(
                      icon: Icons.logout_rounded,
                      label: 'Checkout',
                      value: _time(p.checkOutTime) == null
                          ? 'Ask the host'
                          : 'by ${_time(p.checkOutTime)}',
                    ),
                    if (p.checkOutInformation != null)
                      Text(
                        p.checkOutInformation!,
                        style: context.text.bodyMedium,
                      ),
                  ],
                ),
                if (p.houseRules != null && p.houseRules!.trim().isNotEmpty)
                  _Section(
                    title: 'House rules',
                    children: [
                      Text(p.houseRules!, style: context.text.bodyMedium),
                    ],
                  ),
                _HostCard(propertyId: p.id),
                Gap.xl,
                Center(
                  child: TextButton.icon(
                    onPressed: () => showReportSheet(context, p),
                    icon: Icon(
                      Icons.flag_outlined,
                      color: context.colors.error,
                    ),
                    label: Text(
                      'Report this listing',
                      style: TextStyle(color: context.colors.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ContactBar(
        property: p,
        quote: quote,
        checkIn: checkIn,
        checkOut: checkOut,
      ),
    );
  }

  /// '14:00:00' -> 'from 2:00 pm'.
  static String? _time(String? hhmmss) {
    if (hhmmss == null || hhmmss.length < 5) return null;
    final h = int.tryParse(hhmmss.substring(0, 2));
    if (h == null) return null;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${hhmmss.substring(3, 5)} ${h >= 12 ? 'pm' : 'am'}';
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.images});

  final List<PropertyImage> images;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const PropertyPhoto();
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => PropertyPhoto(image: widget.images[i]),
        ),
        Positioned(
          right: Space.md,
          bottom: Space.md,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.sm,
              vertical: Space.xxs,
            ),
            decoration: BoxDecoration(
              color: const Color(0xB3000000),
              borderRadius: BorderRadius.circular(Radii.pill),
            ),
            child: Text(
              '${_index + 1} / ${widget.images.length}',
              style: context.text.labelMedium?.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.property,
    required this.quote,
    required this.checkIn,
    required this.checkOut,
    required this.onPickDates,
  });

  final Property property;
  final StayQuote? quote;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final VoidCallback onPickDates;

  @override
  Widget build(BuildContext context) {
    final q = quote;
    final p = property;
    final rows = <(String, String, bool)>[
      if (q != null)
        (
          '${Money.kes(q.nightlyRate)} × ${q.nights} night${q.nights == 1 ? '' : 's'}',
          Money.kes(q.nightsTotal),
          false,
        ),
      if (q == null) ('Nightly rate', Money.kes(p.nightlyRate), false),
      if (p.cleaningFee > 0) ('Cleaning fee', Money.kes(p.cleaningFee), false),
      if (q != null) ('Total you pay the host', Money.kes(q.total), true),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Price', style: context.text.titleMedium)),
                TextButton.icon(
                  onPressed: onPickDates,
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(
                    checkIn != null && checkOut != null
                        ? '${Dates.shortDay(checkIn!)} – ${Dates.shortDay(checkOut!)}'
                        : 'Add dates',
                  ),
                ),
              ],
            ),
            Gap.sm,
            for (final (label, value, bold) in rows)
              Padding(
                padding: EdgeInsets.only(top: bold ? Space.sm : Space.xs),
                child: DecoratedBox(
                  decoration: bold
                      ? BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: context.colors.outlineVariant,
                            ),
                          ),
                        )
                      : const BoxDecoration(),
                  child: Padding(
                    padding: EdgeInsets.only(top: bold ? Space.sm : 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: bold
                                ? context.text.titleSmall
                                : context.text.bodyMedium,
                          ),
                        ),
                        Text(
                          value,
                          style:
                              (bold
                                      ? context.text.titleSmall
                                      : context.text.bodyMedium)
                                  ?.copyWith(
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Gap.md,
            Text(
              p.refundableDeposit > 0
                  ? 'Refundable deposit: ${Money.kes(p.refundableDeposit)}, returned after checkout if there is no damage.'
                  : 'No refundable deposit.',
              style: context.text.bodySmall,
            ),
            Gap.xs,
            Text(
              'Prices are set by the host. PataStay adds no fees and never takes payment. '
              'Pay the host only after you have confirmed the place is real.',
              style: context.text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Gap.lg,
          Text(title, style: context.text.titleMedium),
          Gap.sm,
          ...children,
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: context.palette.mutedText),
        Gap.sm,
        Text('$label: ', style: context.text.titleSmall),
        Expanded(child: Text(value, style: context.text.bodyMedium)),
      ],
    );
  }
}

class _HostCard extends ConsumerWidget {
  const _HostCard({required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final host = ref.watch(hostSummaryProvider(propertyId)).value;
    if (host == null) return const SizedBox.shrink();
    return _Section(
      title: 'Your host',
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: context.colors.primaryContainer,
              child: Text(
                host.displayName.substring(0, 1).toUpperCase(),
                style: context.text.titleMedium?.copyWith(
                  color: context.colors.onPrimaryContainer,
                ),
              ),
            ),
            Gap.md,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(host.displayName, style: context.text.titleSmall),
                  Text(
                    'On PataStay since ${Dates.day(host.memberSince)} · '
                    '${host.publishedListings} listing${host.publishedListings == 1 ? '' : 's'}'
                    '${host.verifiedListings > 0 ? ' · ${host.verifiedListings} verified' : ''}',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContactBar extends StatelessWidget {
  const _ContactBar({
    required this.property,
    required this.quote,
    required this.checkIn,
    required this.checkOut,
  });

  final Property property;
  final StayQuote? quote;
  final DateTime? checkIn;
  final DateTime? checkOut;

  @override
  Widget build(BuildContext context) {
    final q = quote;
    return Material(
      color: context.colors.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.md,
            Space.gutter,
            Space.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q != null
                          ? '${Money.kes(q.total)} total'
                          : '${Money.kes(property.nightlyRate)} / night',
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      q != null
                          ? '${Dates.shortDay(checkIn!)} – ${Dates.shortDay(checkOut!)} · ${q.nights} night${q.nights == 1 ? '' : 's'}'
                          : 'Add dates to see the total',
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
              Gap.md,
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  // Without heightFactor the bar would grow to fill the screen.
                  heightFactor: 1,
                  child: FilledButton(
                    onPressed: () => showContactSheet(
                      context,
                      property,
                      checkIn: checkIn,
                      checkOut: checkOut,
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Contact host'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Always-visible back button over the photo: returns to the previous screen,
/// or to Home when the listing was opened directly (a link or page refresh).
class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xEEFFFFFF),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded, color: PataColors.ink),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.explore),
        ),
      ),
    );
  }
}
