import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:patastay_core/patastay_core.dart';

import '../../../core/location/location_service.dart';
import '../../../core/widgets/form_widgets.dart';

/// Full-screen map for placing the private pin. Returns the chosen point, or
/// null when closed without choosing.
Future<LatLng?> openPinMap(BuildContext context, {required LatLng centre, LatLng? pin}) {
  return Navigator.of(context).push<LatLng>(
    MaterialPageRoute(fullscreenDialog: true, builder: (_) => PinMapScreen(centre: centre, pin: pin)),
  );
}

class PinMapScreen extends ConsumerStatefulWidget {
  const PinMapScreen({super.key, required this.centre, this.pin});

  final LatLng centre;
  final LatLng? pin;

  @override
  ConsumerState<PinMapScreen> createState() => _PinMapScreenState();
}

class _PinMapScreenState extends ConsumerState<PinMapScreen> {
  late LatLng? _pin = widget.pin;
  final _map = MapController();
  bool _locating = false;

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final p = await ref.read(locationServiceProvider).current();
      final point = LatLng(p.latitude, p.longitude);
      setState(() => _pin = point);
      _map.move(point, 17);
    } on AppFailure catch (failure) {
      if (mounted) context.showFailure(failure);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close map',
          icon: const Icon(Icons.close_fullscreen_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pin the building'),
        actions: [
          TextButton(
            onPressed: _pin == null ? null : () => Navigator.pop(context, _pin),
            child: const Text('Use this pin'),
          ),
          Gap.sm,
        ],
      ),
      body: Stack(children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: _pin ?? widget.centre,
            initialZoom: _pin == null ? 15 : 17,
            onTap: (_, point) => setState(() => _pin = point),
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            TileLayer(urlTemplate: config.mapTileUrl, userAgentPackageName: 'com.patastay.app'),
            if (_pin != null)
              MarkerLayer(markers: [
                Marker(
                  point: _pin!,
                  width: 48,
                  height: 48,
                  alignment: Alignment.topCenter,
                  child: Icon(Icons.location_on_rounded, size: 48, color: context.colors.primary),
                ),
              ]),
            RichAttributionWidget(
              showFlutterMapAttribution: false,
              attributions: [TextSourceAttribution(config.mapAttribution)],
            ),
          ],
        ),
        Positioned(
          left: Space.gutter,
          right: Space.gutter,
          top: Space.md,
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(Radii.md),
            color: context.colors.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
              child: Text(
                _pin == null ? 'Tap the map where the building is.' : 'Pin set. Tap elsewhere to move it.',
                style: context.text.bodyMedium,
              ),
            ),
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _locating ? null : _useMyLocation,
        icon: _locating
            ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
            : const Icon(Icons.my_location_rounded),
        label: const Text('I am here'),
      ),
    );
  }
}
