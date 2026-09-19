import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_service.dart';
import 'berp_cloud.dart';
import 'device_fingerprint.dart';

class ClockSession {
  const ClockSession({
    required this.id,
    required this.clockIn,
    this.clockOut,
    this.siteId,
    this.siteName,
    this.deviceId,
    this.deviceLabel,
    this.deviceModel,
    this.deviceOs,
    this.publicIp,
    this.multiDevicePriority = false,
  });

  final String id;
  final DateTime clockIn;
  final DateTime? clockOut;
  final String? siteId;
  final String? siteName;
  final String? deviceId;
  final String? deviceLabel;
  final String? deviceModel;
  final String? deviceOs;
  final String? publicIp;

  /// True when this user used more than 3 distinct devices in the last 7 days.
  final bool multiDevicePriority;

  bool get isOpen => clockOut == null;

  String get deviceShortId {
    final raw = (deviceId ?? '').replaceAll('-', '').toUpperCase();
    if (raw.length >= 8) return raw.substring(0, 8);
    return raw;
  }

  String get deviceSummary {
    final phone = (deviceLabel ?? deviceModel ?? '').trim();
    final id = deviceShortId;
    final ip = (publicIp ?? '').trim();
    final parts = <String>[
      if (phone.isNotEmpty) phone,
      if (id.isNotEmpty) 'ID $id',
      if (ip.isNotEmpty) 'IP $ip',
    ];
    return parts.isEmpty ? 'Device unknown' : parts.join('  ·  ');
  }

  Duration get elapsed {
    final end = clockOut ?? DateTime.now();
    return end.difference(clockIn);
  }

  Map<String, String> toMap() => {
    'id': id,
    'clockIn': clockIn.toIso8601String(),
    'clockOut': clockOut?.toIso8601String() ?? '',
    'siteId': siteId ?? '',
    'siteName': siteName ?? '',
    'deviceId': deviceId ?? '',
    'deviceLabel': deviceLabel ?? '',
    'deviceModel': deviceModel ?? '',
    'deviceOs': deviceOs ?? '',
    'publicIp': publicIp ?? '',
    'multiDevicePriority': multiDevicePriority ? '1' : '0',
  };

  factory ClockSession.fromMap(Map<String, dynamic> map) {
    final out = '${map['clockOut'] ?? ''}';
    final siteId = '${map['siteId'] ?? ''}';
    final siteName = '${map['siteName'] ?? ''}';
    final deviceId = '${map['deviceId'] ?? ''}';
    final deviceLabel = '${map['deviceLabel'] ?? ''}';
    final deviceModel = '${map['deviceModel'] ?? ''}';
    final deviceOs = '${map['deviceOs'] ?? ''}';
    final publicIp = '${map['publicIp'] ?? ''}';
    return ClockSession(
      id: '${map['id'] ?? ''}',
      clockIn: DateTime.tryParse('${map['clockIn'] ?? ''}') ?? DateTime.now(),
      clockOut: out.isEmpty ? null : DateTime.tryParse(out),
      siteId: siteId.isEmpty ? null : siteId,
      siteName: siteName.isEmpty ? null : siteName,
      deviceId: deviceId.isEmpty ? null : deviceId,
      deviceLabel: deviceLabel.isEmpty ? null : deviceLabel,
      deviceModel: deviceModel.isEmpty ? null : deviceModel,
      deviceOs: deviceOs.isEmpty ? null : deviceOs,
      publicIp: publicIp.isEmpty ? null : publicIp,
      multiDevicePriority:
          '${map['multiDevicePriority'] ?? ''}' == '1' ||
          map['multiDevicePriority'] == true,
    );
  }
}

enum LeaveKind { annual, sick, unpaid, compassionate }

extension LeaveKindLabel on LeaveKind {
  String get label => switch (this) {
    LeaveKind.annual => 'Annual leave',
    LeaveKind.sick => 'Sick leave',
    LeaveKind.unpaid => 'Unpaid leave',
    LeaveKind.compassionate => 'Compassionate',
  };
}

enum LeaveStatus { pending, approved, declined }

extension LeaveStatusLabel on LeaveStatus {
  String get label => switch (this) {
    LeaveStatus.pending => 'Pending',
    LeaveStatus.approved => 'Approved',
    LeaveStatus.declined => 'Declined',
  };
}

class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.kind,
    required this.start,
    required this.end,
    required this.note,
    required this.status,
  });

  final String id;
  final LeaveKind kind;
  final DateTime start;
  final DateTime end;
  final String note;
  final LeaveStatus status;

  int get days {
    final from = DateTime(start.year, start.month, start.day);
    final to = DateTime(end.year, end.month, end.day);
    return to.difference(from).inDays + 1;
  }

  Map<String, String> toMap() => {
    'id': id,
    'kind': kind.name,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'note': note,
    'status': status.name,
  };

  factory LeaveRequest.fromMap(Map<String, dynamic> map) {
    return LeaveRequest(
      id: '${map['id'] ?? ''}',
      kind: LeaveKind.values.firstWhere(
        (k) => k.name == map['kind'],
        orElse: () => LeaveKind.annual,
      ),
      start: DateTime.tryParse('${map['start'] ?? ''}') ?? DateTime.now(),
      end: DateTime.tryParse('${map['end'] ?? ''}') ?? DateTime.now(),
      note: '${map['note'] ?? ''}',
      status: LeaveStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => LeaveStatus.pending,
      ),
    );
  }
}

class AppraisalRecord {
  const AppraisalRecord({
    required this.id,
    required this.title,
    required this.reviewer,
    required this.period,
    required this.summary,
    this.rating,
    this.completed = false,
  });

  final String id;
  final String title;
  final String reviewer;
  final String period;
  final String summary;
  final double? rating;
  final bool completed;

  Map<String, String> toMap() => {
    'id': id,
    'title': title,
    'reviewer': reviewer,
    'period': period,
    'summary': summary,
    'rating': rating?.toString() ?? '',
    'completed': completed ? '1' : '0',
  };

  factory AppraisalRecord.fromMap(Map<String, dynamic> map) {
    final rawRating = '${map['rating'] ?? ''}';
    return AppraisalRecord(
      id: '${map['id'] ?? ''}',
      title: '${map['title'] ?? ''}',
      reviewer: '${map['reviewer'] ?? ''}',
      period: '${map['period'] ?? ''}',
      summary: '${map['summary'] ?? ''}',
      rating: double.tryParse(rawRating),
      completed: map['completed'] == '1' || map['completed'] == true,
    );
  }
}

class StaffUpdate {
  const StaffUpdate({
    required this.id,
    required this.author,
    required this.role,
    required this.title,
    required this.body,
    required this.at,
  });

  final String id;
  final String author;
  final String role;
  final String title;
  final String body;
  final DateTime at;

  Map<String, String> toMap() => {
    'id': id,
    'author': author,
    'role': role,
    'title': title,
    'body': body,
    'at': at.toIso8601String(),
  };

  factory StaffUpdate.fromMap(Map<String, dynamic> map) {
    return StaffUpdate(
      id: '${map['id'] ?? ''}',
      author: '${map['author'] ?? ''}',
      role: '${map['role'] ?? ''}',
      title: '${map['title'] ?? ''}',
      body: '${map['body'] ?? ''}',
      at: DateTime.tryParse('${map['at'] ?? ''}') ?? DateTime.now(),
    );
  }
}

abstract final class StaffIdentity {
  static String get name {
    final user = AuthService.currentUser;
    final meta = user?.userMetadata;
    final raw = (meta?['full_name'] ?? meta?['name'])?.toString().trim();
    if (raw != null && raw.isNotEmpty) return raw;
    final email = user?.email;
    if (email != null && email.contains('@')) {
      final local = email.split('@').first;
      if (local.isNotEmpty) {
        return local[0].toUpperCase() + local.substring(1);
      }
    }
    return 'Staff';
  }

  static String get firstName {
    final parts = name.split(RegExp(r'\s+'));
    return parts.isEmpty ? 'Staff' : parts.first;
  }

  static String get email => AuthService.currentUser?.email ?? '';

  static String get role => 'BERP';

  static String get userId => AuthService.currentUser?.id ?? '';
}

class StaffStore {
  StaffStore._();
  static final StaffStore instance = StaffStore._();

  static const _clockKey = 'staff_clock_json';
  static const _leaveKey = 'staff_leave_json';
  static const _appraisalKey = 'staff_appraisal_json';
  static const _updatesKey = 'staff_updates_json';
  static const _seededKey = 'staff_content_seeded';

  static const annualAllowance = 21;

  Future<void> _seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededKey) ?? false) return;

    final now = DateTime.now();
    final appraisals = [
      AppraisalRecord(
        id: 'apr-q1',
        title: 'Q1 performance review',
        reviewer: 'Ngozi Adeyemi · People',
        period: 'Jan – Mar 2026',
        summary:
            'Strong ownership on ground coordination. Keep building handover notes so the next shift is never guessing.',
        rating: 4.4,
        completed: true,
      ),
      AppraisalRecord(
        id: 'apr-mid',
        title: 'Mid-year check-in',
        reviewer: 'Ibrahim Bello · Operations',
        period: 'Due Jul 2026',
        summary:
            'A short conversation on goals, support, and any blockers before the second half of the year.',
      ),
    ];

    final updates = [
      StaffUpdate(
        id: 'upd-1',
        author: 'Adaeze Okafor',
        role: 'Operations',
        title: 'Lagos roster is live',
        body:
            'Next week’s ground and hangar roster is posted. Confirm your shifts before Friday close of play.',
        at: now.subtract(const Duration(hours: 3)),
      ),
      StaffUpdate(
        id: 'upd-2',
        author: 'Chinedu Bassey',
        role: 'People',
        title: 'Appraisal window opens Monday',
        body:
            'Self-reviews open Monday 09:00. Please complete yours before the manager conversation is booked.',
        at: now.subtract(const Duration(hours: 9)),
      ),
      StaffUpdate(
        id: 'upd-3',
        author: 'Fatima Yusuf',
        role: 'People',
        title: 'Leave requests — 10 working days',
        body:
            'Annual leave still needs 10 working days’ notice except for sick or emergency cover.',
        at: now.subtract(const Duration(days: 1, hours: 2)),
      ),
    ];

    await prefs.setString(
      _appraisalKey,
      jsonEncode([for (final item in appraisals) item.toMap()]),
    );
    await prefs.setString(
      _updatesKey,
      jsonEncode([for (final item in updates) item.toMap()]),
    );
    await prefs.setBool(_seededKey, true);
  }

  Future<List<ClockSession>> _localSessions() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_clockKey), ClockSession.fromMap);
  }

  Future<void> _clearLocalClock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_clockKey);
  }

  /// Only recover a just-failed cloud write. Do not upload leftover clocks from
  /// another phone or an older install — those times are not live attendance.
  Future<void> _syncLocalOpenToCloud() async {
    if (!AuthService.isSignedIn) return;
    ClockSession? localOpen;
    for (final session in await _localSessions()) {
      if (session.isOpen) {
        localOpen = session;
        break;
      }
    }
    if (localOpen == null) return;
    final age = DateTime.now().difference(localOpen.clockIn);
    if (age > const Duration(minutes: 2) || age.isNegative) {
      await _clearLocalClock();
      return;
    }
    final cloud = await BerpCloud.clockSessions();
    if (cloud.any((session) => session.isOpen)) {
      await _clearLocalClock();
      return;
    }
    await BerpCloud.insertClockIn(
      siteId: localOpen.siteId,
      siteName: localOpen.siteName,
      clockIn: localOpen.clockIn,
      device: await DeviceFingerprint.current(),
    );
    await _clearLocalClock();
  }

  Future<List<ClockSession>> sessions() async {
    try {
      if (AuthService.isSignedIn) {
        await _syncLocalOpenToCloud();
        return await BerpCloud.clockSessions();
      }
      final cloud = await BerpCloud.clockSessions();
      if (cloud.isNotEmpty) return cloud;
    } catch (_) {}
    return _localSessions();
  }

  Future<ClockSession?> openSession() async {
    final all = await sessions();
    for (final session in all) {
      if (session.isOpen) return session;
    }
    return null;
  }

  Future<Duration> hoursToday() async {
    final start = DateTime.now();
    final day = DateTime(start.year, start.month, start.day);
    var total = Duration.zero;
    for (final session in await sessions()) {
      final end = session.clockOut ?? DateTime.now();
      if (end.isBefore(day)) continue;
      final from = session.clockIn.isBefore(day) ? day : session.clockIn;
      total += end.difference(from);
    }
    return total;
  }

  Future<ClockSession> clockIn({String? siteId, String? siteName}) async {
    final existing = await openSession();
    if (existing != null) return existing;
    final device = await DeviceFingerprint.current();
    if (AuthService.isSignedIn) {
      final cloud = await BerpCloud.insertClockIn(
        siteId: siteId,
        siteName: siteName,
        device: device,
      );
      if (cloud == null) {
        throw StateError('Could not save clock-in to BERP.');
      }
      return cloud;
    }
    final session = ClockSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clockIn: DateTime.now(),
      siteId: siteId,
      siteName: siteName,
      deviceId: device.deviceId,
      deviceLabel: device.label,
      deviceModel: device.model,
      deviceOs: device.os,
      publicIp: device.publicIp,
    );
    final all = [...await _localSessions(), session];
    await _save(_clockKey, [for (final item in all) item.toMap()]);
    return session;
  }

  Future<ClockSession?> clockOut() async {
    final open = await openSession();
    if (open == null) return null;
    try {
      final cloud = await BerpCloud.clockOut(open.id);
      if (cloud != null) {
        await _clearLocalClock();
        return cloud;
      }
    } catch (_) {}
    final all = [...await sessions()];
    final index = all.indexWhere((s) => s.isOpen);
    if (index < 0) return null;
    final current = all[index];
    final updated = ClockSession(
      id: current.id,
      clockIn: current.clockIn,
      clockOut: DateTime.now(),
      siteId: current.siteId,
      siteName: current.siteName,
      deviceId: current.deviceId,
      deviceLabel: current.deviceLabel,
      deviceModel: current.deviceModel,
      deviceOs: current.deviceOs,
      publicIp: current.publicIp,
      multiDevicePriority: current.multiDevicePriority,
    );
    all[index] = updated;
    await _save(_clockKey, [for (final item in all) item.toMap()]);
    return updated;
  }

  Future<List<LeaveRequest>> leaveRequests() async {
    try {
      final cloud = await BerpCloud.leaveRequests();
      if (cloud.isNotEmpty || AuthService.isSignedIn) {
        cloud.sort((a, b) => b.start.compareTo(a.start));
        return cloud;
      }
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    final list = _decode(prefs.getString(_leaveKey), LeaveRequest.fromMap);
    list.sort((a, b) => b.start.compareTo(a.start));
    return list;
  }

  Future<int> remainingAnnualDays() async {
    var used = 0;
    for (final request in await leaveRequests()) {
      if (request.kind != LeaveKind.annual) continue;
      if (request.status == LeaveStatus.declined) continue;
      used += request.days;
    }
    return annualAllowance - used;
  }

  Future<void> submitLeave(LeaveRequest request) async {
    try {
      final cloud = await BerpCloud.insertLeave(request);
      if (cloud != null) return;
    } catch (_) {}
    final all = [...await leaveRequests(), request];
    await _save(_leaveKey, [for (final item in all) item.toMap()]);
  }

  Future<List<AppraisalRecord>> appraisals() async {
    try {
      final cloud = await BerpCloud.appraisals();
      if (cloud.isNotEmpty) return cloud;
    } catch (_) {}
    await _seedIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_appraisalKey), AppraisalRecord.fromMap);
  }

  Future<List<StaffUpdate>> updates() async {
    try {
      final cloud = await BerpCloud.updates();
      if (cloud.isNotEmpty || AuthService.isSignedIn) {
        cloud.sort((a, b) => b.at.compareTo(a.at));
        return cloud;
      }
    } catch (_) {}
    await _seedIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    final list = _decode(prefs.getString(_updatesKey), StaffUpdate.fromMap);
    list.sort((a, b) => b.at.compareTo(a.at));
    return list;
  }

  Future<void> postUpdate({required String title, required String body}) async {
    try {
      final cloud = await BerpCloud.insertUpdate(title: title, body: body);
      if (cloud != null) return;
    } catch (_) {}
    final item = StaffUpdate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: StaffIdentity.name,
      role: StaffIdentity.role,
      title: title,
      body: body,
      at: DateTime.now(),
    );
    final all = [item, ...await updates()];
    await _save(_updatesKey, [for (final row in all) row.toMap()]);
  }

  List<T> _decode<T>(String? raw, T Function(Map<String, dynamic>) parse) {
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return [
      for (final item in decoded)
        if (item is Map) parse(item.map((k, v) => MapEntry(k.toString(), v))),
    ];
  }

  Future<void> _save(String key, List<Map<String, String>> rows) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(rows));
  }
}

String formatDurationHours(Duration value) {
  return formatDurationHms(value);
}

/// Live shift timer, e.g. 01:04:09
String formatDurationHms(Duration value) {
  var elapsed = value;
  if (elapsed.isNegative) elapsed = Duration.zero;
  final hours = elapsed.inHours.toString().padLeft(2, '0');
  final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

/// Attendance clock in West Africa Time (Lagos, UTC+1, no DST).
DateTime lagosWallClock(DateTime value) {
  return value.toUtc().add(const Duration(hours: 1));
}

String formatLagosStamp(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final t = lagosWallClock(value);
  final day = t.day.toString().padLeft(2, '0');
  return '$day ${months[t.month - 1]} ${t.year}, ${formatClock(value)}';
}

String formatClock(DateTime value) {
  final t = lagosWallClock(value);
  final hour = t.hour.toString().padLeft(2, '0');
  final minute = t.minute.toString().padLeft(2, '0');
  final second = t.second.toString().padLeft(2, '0');
  return '$hour:$minute:$second';
}

String formatDay(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}
