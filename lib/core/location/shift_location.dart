import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/staff_access.dart';
import '../data/berp_org.dart';
import '../data/clock_sites.dart';
import '../data/staff_store.dart';

/// Records location while a shift is open, and auto clock-out after 3h away.
abstract final class ShiftLocationPing {
  static const awayLimit = Duration(hours: 3);
  static const _awayKeyPrefix = 'berp_away_since_';

  static Timer? _timer;
  static String? _sessionId;
  static DateTime? _outsideSince;

  static void follow(String? sessionId) {
    if (sessionId == null || sessionId.isEmpty) {
      stop();
      return;
    }
    // Super Admin uses mock pins — do not track real GPS or auto clock-out.
    if (StaffAccess.role.value.isSuperAdmin) {
      stop();
      return;
    }
    if (_sessionId == sessionId && _timer != null) return;
    stop();
    _sessionId = sessionId;
    unawaited(_restoreAway(sessionId));
    unawaited(_ping(sessionId));
    _timer = Timer.periodic(const Duration(minutes: 3), (_) {
      unawaited(_ping(sessionId));
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    _sessionId = null;
    _outsideSince = null;
  }

  static Future<void> _restoreAway(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_awayKeyPrefix$sessionId');
      if (raw == null || raw.isEmpty) return;
      _outsideSince = DateTime.tryParse(raw)?.toLocal();
    } catch (_) {}
  }

  static Future<void> _setAway(String sessionId, DateTime? since) async {
    _outsideSince = since;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_awayKeyPrefix$sessionId';
      if (since == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, since.toUtc().toIso8601String());
      }
    } catch (_) {}
  }

  static Future<void> _ping(String sessionId) async {
    try {
      if (StaffAccess.role.value.isSuperAdmin) return;

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

      final sites = await BerpOrg.activeSites();
      final places = sites.isEmpty ? clockSites : sites;
      final inside = places.any((site) {
        final meters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          site.latitude,
          site.longitude,
        );
        return meters <= site.radiusMeters;
      });

      if (inside) {
        await _setAway(sessionId, null);
        return;
      }

      final since = _outsideSince ?? DateTime.now();
      if (_outsideSince == null) {
        await _setAway(sessionId, since);
      }

      if (DateTime.now().difference(since) >= awayLimit) {
        await StaffStore.instance.clockOut(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('$_awayKeyPrefix$sessionId');
        } catch (_) {}
        stop();
      }
    } catch (_) {}
  }
}
