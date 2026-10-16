import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:patastay_core/patastay_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/routes.dart';

const _nairobi = LatLng(-1.2864, 36.8172);
const _packageName = 'com.patastay.app';

/// Base map tiles from the configured provider (OpenStreetMap by default).
/// Tiles are dimmed in dark mode so the map matches the theme.
class _Tiles extends ConsumerWidget {
  const _Tiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return TileLayer(
      urlTemplate: config.mapTileUrl,
      // OpenStreetMap's usage policy requires apps to identify themselves.
      userAgentPackageName: _packageName,
      tileBuilder: dark ? darkModeTileBuilder : null,
      maxNativeZoom: 19,
    );
  }
}

class _Attribution extends ConsumerWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(appConfigProvider).mapAttribution;
    return RichAttributionWidget(
      showFlutterMapAttribution: false,
      attributions: [
        TextSourceAttribution(
          text,
          onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright'), mode: LaunchMode.externalApplication),
        ),
      ],
    );
  }
}

/// Shows the approximate area of a listing as a ~350 m circle. Public
/// coordinates are already offset from the real address by the database, and
/// no pin is drawn, so the exact door is never implied.
class AreaMap extends ConsumerWidget {
  const AreaMap({super.key, required this.property});

  final Property property;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(appConfigProvider).mapsEnabled;
    final p = property;
    final caption = Text(
      'Approximate area. The host shares the exact address after you contact them.',
      style: context.text.bodySmall,
    );
    if (!enabled || !p.hasLocation) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _MapFallback(
          title: p.neighbourhood?.name ?? 'Nairobi',
          message: !p.hasLocation ? 'The host has not set the area on the map yet.' : 'Map not available in this build.',
        ),
        Gap.sm,
        caption,
      ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: 'Map of the approximate area around ${p.neighbourhood?.name ?? 'this stay'}. Tap to open a larger map.',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.md),
            child: SizedBox(
              height: 200,
              child: Stack(
                children: [
                  // A fixed preview so the page scrolls smoothly; tap for the full map.
                  _AreaMapView(property: p, interactive: false),
                  Positioned.fill(
                    child: Material(
                      type: MaterialType.transparency,
                      child: InkWell(onTap: () => _openFullMap(context, p)),
                    ),
                  ),
                  Positioned(
                    right: Space.sm,
                    bottom: Space.lg + Space.md,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(Radii.pill),
                          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.open_in_full_rounded, size: 14, color: context.colors.onSurface),
                          const SizedBox(width: 4),
                          Text('Tap to explore', style: context.text.labelSmall),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Gap.sm,
        caption,
      ],
    );
  }

  void _openFullMap(BuildContext context, Property p) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(p.neighbourhood?.name ?? 'Area')),
        body: Column(
          children: [
            Expanded(child: _AreaMapView(property: p, interactive: true)),
            Material(
              color: context.colors.surface,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(Space.lg),
                  child: Text(
                    'The circle shows the approximate area. For safety, the exact address is shared by the host after you contact them.',
                    style: context.text.bodyMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

/// The area circle on a map. Interactive maps can pan and zoom, but zoom is
/// capped at street level since the circle is only an approximate area.
class _AreaMapView extends StatelessWidget {
  const _AreaMapView({required this.property, required this.interactive});

  final Property property;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final centre = LatLng(property.latitude!, property.longitude!);
    final colour = context.colors.primary;
    return FlutterMap(
      options: MapOptions(
        initialCenter: centre,
        initialZoom: interactive ? 15 : 14.6,
        minZoom: 10,
        maxZoom: 17,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
        ),
      ),
      children: [
        const _Tiles(),
        CircleLayer(circles: [
          CircleMarker(
            point: centre,
            radius: 350,
            useRadiusInMeter: true,
            color: colour.withValues(alpha: 0.18),
            borderColor: colour,
            borderStrokeWidth: 2,
          ),
        ]),
        const _Attribution(),
      ],
    );
  }
}

/// Search results on a map, as price pins at the approximate public points.
class SearchResultsMap extends ConsumerWidget {
  const SearchResultsMap({super.key, required this.properties, this.myLocation});

  final List<Property> properties;

  /// The guest's position, only when they turned on "Near me".
  final LatLng? myLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(appConfigProvider).mapsEnabled;
    if (!enabled) {
      return const Padding(
        padding: EdgeInsets.all(Space.gutter),
        child: _MapFallback(title: 'Map view', message: 'Map not available in this build. Use the list view.'),
      );
    }
    final located = properties.where((p) => p.hasLocation).toList();
    final points = [
      for (final p in located) LatLng(p.latitude!, p.longitude!),
      ?myLocation,
    ];
    final missing = properties.length - located.length;

    return Stack(
      children: [
        FlutterMap(
          // Rebuild the camera fit when the result set changes.
          key: ValueKey(points.length + (points.isEmpty ? 0 : points.first.latitude.hashCode)),
          options: MapOptions(
            initialCenter: _nairobi,
            initialZoom: 11.5,
            initialCameraFit: points.length > 1
                ? CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(56), maxZoom: 15)
                : null,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            const _Tiles(),
            MarkerLayer(markers: [
              if (myLocation != null)
                Marker(point: myLocation!, width: 22, height: 22, child: const _MyLocationDot()),
              for (final p in located)
                Marker(
                  point: LatLng(p.latitude!, p.longitude!),
                  width: 96,
                  height: 36,
                  child: _PricePin(property: p),
                ),
            ]),
            const _Attribution(),
          ],
        ),
        if (missing > 0)
          Positioned(
            left: Space.md,
            right: Space.md,
            top: Space.md,
            child: Material(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(Radii.md),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(Space.md),
                child: Text(
                  '$missing stay${missing == 1 ? ' has' : 's have'} no map area yet. Switch to the list to see all results.',
                  style: context.text.bodySmall,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PricePin extends StatelessWidget {
  const _PricePin({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${property.title}, ${Money.kes(property.nightlyRate)} per night',
      excludeSemantics: true,
      child: Center(
        child: Material(
          color: context.colors.surface,
          elevation: 3,
          shape: StadiumBorder(side: BorderSide(color: context.colors.primary, width: 1.5)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => context.push(Routes.property(property.id)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
              child: Text(
                Money.kesCompact(property.nightlyRate),
                style: context.text.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: context.colors.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MyLocationDot extends StatelessWidget {
  const _MyLocationDot();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Your location',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF1A73E8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 4)],
        ),
      ),
    );
  }
}

class _MapFallback extends StatelessWidget {
  const _MapFallback({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      width: double.infinity,
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: context.palette.neutralContainer,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          Icon(Icons.map_outlined, size: 32, color: context.palette.mutedText),
          Gap.md,
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleSmall),
                Text(message, style: context.text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
