import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:patastay_core/patastay_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/admin_widgets.dart';
import '../../data/admin_models.dart';
import '../../data/admin_repository.dart';
import '../dashboard/platform_stats.dart';
import 'listing_panels.dart';

/// Everything an administrator needs to decide on one listing: the content
/// guests will see, the private contact and pin, the host, verification,
/// reports and the status history, with the moderation actions alongside.
class ListingReviewScreen extends ConsumerWidget {
  const ListingReviewScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listing = ref.watch(adminListingProvider(id));
    return switch (listing) {
      AsyncData(:final value?) => _Body(listing: value),
      AsyncData() => const MessageView(
          icon: Icons.search_off_rounded,
          title: 'Listing not found',
          message: 'It may have been deleted with its host\'s account.',
        ),
      AsyncError(:final error) => ErrorView(error: error, onRetry: () => ref.invalidate(adminListingProvider(id))),
      _ => const LoadingView(),
    };
  }
}

/// Reloads everything that a moderation action can change.
void refreshListing(WidgetRef ref, String id) {
  ref
    ..invalidate(adminListingProvider(id))
    ..invalidate(listingHistoryProvider(id))
    ..invalidate(verificationChecksProvider(id))
    ..invalidate(listingReportsProvider(id))
    ..invalidate(adminListingsProvider)
    ..invalidate(platformStatsProvider);
}

class _Body extends StatelessWidget {
  const _Body({required this.listing});

  final AdminListing listing;

  @override
  Widget build(BuildContext context) {
    final p = listing.property;
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1100;
      final content = [
        _Photos(listing: listing),
        _Content(listing: listing),
        _LocationPanel(listing: listing),
      ];
      final side = [
        ModerationPanel(listing: listing),
        _HostPanel(listing: listing),
        VerificationPanel(listing: listing),
        if (listing.status == PropertyStatus.published) FeaturingPanel(listing: listing),
        ReportsForListingPanel(propertyId: listing.id),
        HistoryPanel(propertyId: listing.id),
      ];
      return AdminPage(
        maxWidth: 1400,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/listings'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: listing.listing.displayTitle,
        subtitle: [
          p.reference,
          listing.status.label,
          if (p.isSeed) 'Sample listing',
        ].join(' · '),
        children: [
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: content)),
              Gap.xl,
              Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: side)),
            ])
          else ...[
            side.first,
            ...content,
            ...side.skip(1),
          ],
        ],
      );
    });
  }
}

class _Photos extends StatelessWidget {
  const _Photos({required this.listing});

  final AdminListing listing;

  @override
  Widget build(BuildContext context) {
    final images = listing.property.images;
    return Panel(
      title: 'Photos (${images.length})',
      child: images.isEmpty
          ? const Text('No photos yet.')
          : Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
              for (var i = 0; i < images.length; i++)
                InkWell(
                  onTap: () => _openViewer(context, images, i),
                  borderRadius: BorderRadius.circular(Radii.sm),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Radii.sm),
                    child: SizedBox(
                      width: 160,
                      height: 112,
                      child: Stack(fit: StackFit.expand, children: [
                        ListingPhoto(image: images[i]),
                        if (i == 0)
                          const Positioned(
                            left: 6,
                            top: 6,
                            child: Tag(label: 'Cover', foreground: PataColors.ink, background: PataColors.saffronContainer),
                          ),
                      ]),
                    ),
                  ),
                ),
            ]),
    );
  }

  void _openViewer(BuildContext context, List<PropertyImage> images, int start) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(Space.xl),
        clipBehavior: Clip.antiAlias,
        child: _PhotoViewer(images: images, start: start),
      ),
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.images, required this.start});

  final List<PropertyImage> images;
  final int start;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late int _index = widget.start;

  @override
  Widget build(BuildContext context) {
    final count = widget.images.length;
    return Stack(children: [
      Positioned.fill(
        child: ColoredBox(
          color: Colors.black,
          child: ListingPhoto(image: widget.images[_index], thumbnail: false, fit: BoxFit.contain),
        ),
      ),
      Positioned(
        top: Space.sm,
        right: Space.sm,
        child: IconButton.filledTonal(
          tooltip: 'Close',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      Positioned(
        bottom: Space.lg,
        left: 0,
        right: 0,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton.filledTonal(
            tooltip: 'Previous photo',
            onPressed: _index == 0 ? null : () => setState(() => _index--),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Gap.lg,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(Radii.pill)),
            child: Text('${_index + 1} / $count', style: const TextStyle(color: Colors.white)),
          ),
          Gap.lg,
          IconButton.filledTonal(
            tooltip: 'Next photo',
            onPressed: _index == count - 1 ? null : () => setState(() => _index++),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ]),
      ),
    ]);
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.listing});

  final AdminListing listing;

  @override
  Widget build(BuildContext context) {
    final p = listing.property;
    String? time(String? t) => t == null || t.length < 5 ? t : t.substring(0, 5);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Panel(
        title: 'What guests will see',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Fact('Title', p.title),
          Fact('Type', p.propertyType?.label),
          Fact('Area', p.neighbourhood?.name),
          Fact('Area description', p.addressOrAreaDescription),
          Fact('Rooms', p.roomsSummary),
          Fact('Minimum stay', '${p.minimumNights} night${p.minimumNights == 1 ? '' : 's'}'),
          Fact('Nightly rate', p.nightlyRate > 0 ? Money.kes(p.nightlyRate) : null),
          Fact('Cleaning fee', p.cleaningFee > 0 ? Money.kes(p.cleaningFee) : 'None'),
          Fact('Refundable deposit', p.refundableDeposit > 0 ? Money.kes(p.refundableDeposit) : 'None'),
          Gap.sm,
          Text('Description', style: context.text.labelLarge),
          Gap.xs,
          SelectableText(p.description.trim().isEmpty ? '–' : p.description),
        ]),
      ),
      Panel(
        title: 'Amenities, check-in and rules',
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (p.amenities.isEmpty)
            const Text('No amenities listed.')
          else
            Wrap(spacing: Space.sm, runSpacing: Space.sm, children: [
              for (final a in p.amenities) Chip(label: Text(a.name), visualDensity: VisualDensity.compact),
            ]),
          Gap.lg,
          Fact('Check-in', [time(p.checkInTime), p.checkInInformation].whereType<String>().join(' · ')),
          Fact('Check-out', [time(p.checkOutTime), p.checkOutInformation].whereType<String>().join(' · ')),
          Fact('House rules', p.houseRules),
          Fact('Availability note', p.availabilityNote),
          Fact(
            'Availability confirmed',
            p.availabilityConfirmedAt == null ? 'Never' : Dates.relative(p.availabilityConfirmedAt!),
          ),
        ]),
      ),
    ]);
  }
}

class _LocationPanel extends ConsumerWidget {
  const _LocationPanel({required this.listing});

  final AdminListing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = listing.listing;
    if (!l.hasExactLocation) {
      return const Panel(title: 'Location', child: Text('The host has not dropped a pin yet.'));
    }
    final config = ref.watch(appConfigProvider);
    final exact = LatLng(l.exactLatitude!, l.exactLongitude!);
    final public = listing.property.hasLocation ? LatLng(listing.property.latitude!, listing.property.longitude!) : null;
    return Panel(
      title: 'Location',
      trailing: TextButton.icon(
        onPressed: () => launchUrl(
          Uri.parse('https://www.openstreetmap.org/?mlat=${exact.latitude}&mlon=${exact.longitude}#map=17/'
              '${exact.latitude}/${exact.longitude}'),
        ),
        icon: const Icon(Icons.open_in_new_rounded, size: 18),
        label: const Text('Open map'),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          'Red: the exact pin (private, only the host and admins see it). Blue: the approximate point guests see.',
          style: context.text.bodySmall,
        ),
        Gap.sm,
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.md),
          child: SizedBox(
            height: 280,
            child: FlutterMap(
              options: MapOptions(initialCenter: exact, initialZoom: 15.5),
              children: [
                TileLayer(urlTemplate: config.mapTileUrl, userAgentPackageName: 'com.patastay.admin', maxNativeZoom: 19),
                MarkerLayer(markers: [
                  if (public != null)
                    Marker(
                      point: public,
                      width: 32,
                      height: 32,
                      child: Icon(Icons.circle, size: 18, color: context.palette.verified),
                    ),
                  Marker(
                    point: exact,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: Icon(Icons.location_on_rounded, size: 40, color: context.palette.danger),
                  ),
                ]),
                SimpleAttributionWidget(source: Text(config.mapAttribution)),
              ],
            ),
          ),
        ),
        Gap.sm,
        Fact('Exact pin', '${exact.latitude.toStringAsFixed(6)}, ${exact.longitude.toStringAsFixed(6)}'),
      ]),
    );
  }
}

class _HostPanel extends StatelessWidget {
  const _HostPanel({required this.listing});

  final AdminListing listing;

  @override
  Widget build(BuildContext context) {
    final owner = listing.owner;
    final l = listing.listing;
    return Panel(
      title: 'Host and contact',
      trailing: owner == null
          ? null
          : TextButton(onPressed: () => context.go('/users/${owner.id}'), child: const Text('View host')),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Fact('Host', owner?.displayName),
        Fact('Email', owner?.email),
        Fact('Account phone', owner?.phone),
        Fact('Member since', owner == null ? null : Dates.day(owner.createdAt)),
        if (owner?.isSuspended ?? false) Fact('Account', 'Suspended: ${owner!.suspendedReason ?? ''}'),
        const Divider(),
        Fact('Listing phone', l.contactPhone),
        Fact('WhatsApp', l.whatsappPhone),
        Fact('Enquiries', '${listing.enquiryCount}'),
      ]),
    );
  }
}
