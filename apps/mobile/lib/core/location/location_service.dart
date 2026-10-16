import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:patastay_core/patastay_core.dart';

class GuestPosition {
  const GuestPosition(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// Gets the guest's position for "Near me". Medium accuracy is enough to
/// rank nearby stays and is faster and lighter on battery. The position is
/// only sent as a search parameter and is never stored.
class LocationService {
  const LocationService();

  Future<GuestPosition> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure('Turn on location on your phone to see stays near you.', canOpenSettings: true);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw const LocationFailure('Location permission is needed to show stays near you.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        'Location is blocked for PataStay. Allow it in your phone settings to use Near me.',
        canOpenSettings: true,
      );
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 15)),
      );
      return GuestPosition(p.latitude, p.longitude);
    } on TimeoutException {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return GuestPosition(last.latitude, last.longitude);
      throw const LocationFailure('We could not find your location. Try again in an open area or search by area name.');
    }
  }

  Future<void> openSettings() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}

final locationServiceProvider = Provider<LocationService>((ref) => const LocationService());
