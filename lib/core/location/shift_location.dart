import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../data/berp_org.dart';

/// Records a location point while a shift is open, then stops.
abstract final class ShiftLocationPing {
  static Timer? _timer;
  static String? _sessionId;

  static void follow(String? sessionId) {
    if (sessionId == null || sessionId.isEmpty) {
      stop();
      return;
    }
    if (_sessionId == sessionId && _timer != null) return;
    stop();
    _sessionId = sessionId;
    unawaited(_ping(sessionId));
    _timer = Timer.periodic(const Duration(minutes: 3), (_) {
      unawaited(_ping(sessionId));
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    _sessionId = null;
  }

  static Future<void> _ping(String sessionId) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      await BerpOrg.recordLocation(
        sessionId: sessionId,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {}
  }
}
