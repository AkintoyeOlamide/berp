import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../data/clock_sites.dart';

class ClockFenceResult {
  const ClockFenceResult._({
    required this.ok,
    required this.message,
    this.site,
  });

  final bool ok;
  final String message;
  final ClockSite? site;

  factory ClockFenceResult.allowed(ClockSite site) {
    return ClockFenceResult._(ok: true, message: site.name, site: site);
  }

  factory ClockFenceResult.blocked(String message) {
    return ClockFenceResult._(ok: false, message: message);
  }
}

class ClockFence {
  static Future<ClockFenceResult> checkIn() async {
    if (clockSites.isEmpty) {
      return ClockFenceResult.blocked(
        'No clock-in sites are configured yet.',
      );
    }

    final serviceOn = await Geolocator.isLocationServiceEnabled();
    if (!serviceOn) {
      return ClockFenceResult.blocked(
        'Turn on location services to clock in.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return ClockFenceResult.blocked(
        'Location permission is needed to clock in.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      return ClockFenceResult.blocked(
        'Location is blocked. Enable it in Settings, then try again.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      ClockSite? nearest;
      var nearestMeters = double.infinity;
      for (final site in clockSites) {
        final meters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          site.latitude,
          site.longitude,
        );
        if (meters <= site.radiusMeters) {
          return ClockFenceResult.allowed(site);
        }
        if (meters < nearestMeters) {
          nearestMeters = meters;
          nearest = site;
        }
      }

      if (nearest == null) {
        return ClockFenceResult.blocked(
          'You must be at an approved clock-in site.',
        );
      }
      return ClockFenceResult.blocked(
        'You must be at an approved site. Nearest is ${nearest.name} '
        '(${nearestMeters.round()} m away).',
      );
    } on TimeoutException {
      return ClockFenceResult.blocked(
        'Could not get a GPS fix. Try again outdoors.',
      );
    } catch (_) {
      return ClockFenceResult.blocked(
        'Could not read your location. Try again.',
      );
    }
  }
}
