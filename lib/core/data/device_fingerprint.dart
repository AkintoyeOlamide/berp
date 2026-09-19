import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Stable install fingerprint + public IP for clock-in audit trails.
class DeviceContext {
  const DeviceContext({
    required this.deviceId,
    required this.label,
    required this.model,
    required this.os,
    this.publicIp,
  });

  /// Persistent UUID for this install (not hardware IMEI).
  final String deviceId;
  final String label;
  final String model;
  final String os;
  final String? publicIp;

  /// Short code for HR tables, e.g. `A1B2C3D4`.
  String get shortId {
    final compact = deviceId.replaceAll('-', '').toUpperCase();
    if (compact.length >= 8) return compact.substring(0, 8);
    return compact;
  }

  String get displayLine {
    final ip = publicIp == null || publicIp!.isEmpty ? 'IP —' : 'IP $publicIp';
    return '$label  ·  ID $shortId  ·  $ip';
  }

  Map<String, dynamic> toPayload() => {
    'device_id': deviceId,
    'device_label': label,
    'device_model': model,
    'device_os': os,
    if (publicIp != null && publicIp!.isNotEmpty) 'public_ip': publicIp,
  };
}

abstract final class DeviceFingerprint {
  static const _prefsKey = 'berp_device_install_id';
  static DeviceContext? _cached;

  static Future<DeviceContext> current({bool refreshIp = true}) async {
    if (_cached != null && !refreshIp) return _cached!;

    final id = await _installId();
    final info = await _deviceInfo();
    final ip = refreshIp ? await _publicIp() : _cached?.publicIp;

    final context = DeviceContext(
      deviceId: id,
      label: info.label,
      model: info.model,
      os: info.os,
      publicIp: ip,
    );
    _cached = context;
    return context;
  }

  static Future<String> _installId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_prefsKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = const Uuid().v4();
    await prefs.setString(_prefsKey, created);
    return created;
  }

  static Future<({String label, String model, String os})> _deviceInfo() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final android = await plugin.androidInfo;
        final brand = android.brand.trim();
        final model = android.model.trim();
        final name = [
          if (brand.isNotEmpty) _title(brand),
          if (model.isNotEmpty && model.toLowerCase() != brand.toLowerCase())
            model,
        ].join(' ').trim();
        return (
          label: name.isEmpty ? 'Android phone' : name,
          model: model.isEmpty ? android.device : model,
          os: 'Android ${android.version.release}',
        );
      }
      if (Platform.isIOS) {
        final ios = await plugin.iosInfo;
        final name = ios.utsname.machine.trim().isEmpty
            ? ios.model
            : ios.utsname.machine;
        return (
          label: ios.name.trim().isEmpty ? name : ios.name.trim(),
          model: name,
          os: '${ios.systemName} ${ios.systemVersion}',
        );
      }
    } catch (_) {}
    return (
      label: Platform.operatingSystem,
      model: Platform.operatingSystem,
      os: Platform.operatingSystemVersion,
    );
  }

  static Future<String?> _publicIp() async {
    const endpoints = ['https://api.ipify.org', 'https://icanhazip.com'];
    for (final endpoint in endpoints) {
      try {
        final res = await http
            .get(Uri.parse(endpoint))
            .timeout(const Duration(seconds: 4));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final ip = res.body.trim();
          if (_looksLikeIp(ip)) return ip;
        }
      } catch (_) {}
    }
    return null;
  }

  static bool _looksLikeIp(String value) {
    if (value.isEmpty || value.length > 45) return false;
    return RegExp(r'^[0-9a-fA-F:.]+$').hasMatch(value);
  }

  static String _title(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
