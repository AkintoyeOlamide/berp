import 'dart:convert';
import 'dart:typed_data';

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
    this.clockInLat,
    this.clockInLng,
    this.clockOutLat,
    this.clockOutLng,
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
  final double? clockInLat;
  final double? clockInLng;
  final double? clockOutLat;
  final double? clockOutLng;

  bool get isOpen => clockOut == null;

  String get deviceShortId {
    final raw = (deviceId ?? '').replaceAll('-', '').toUpperCase();
    if (raw.length >= 8) return raw.substring(0, 8);
    return raw;
  }

  String get deviceType {
    final label = (deviceLabel ?? '').trim();
    if (label.isNotEmpty) return label;
    final model = (deviceModel ?? '').trim();
    if (model.isNotEmpty) return model;
    final os = (deviceOs ?? '').trim();
    if (os.isNotEmpty) return os;
    return 'Unknown device';
  }

  String get deviceSummary {
    final phone = deviceType == 'Unknown device' ? '' : deviceType;
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
    'clockInLat': clockInLat?.toString() ?? '',
    'clockInLng': clockInLng?.toString() ?? '',
    'clockOutLat': clockOutLat?.toString() ?? '',
    'clockOutLng': clockOutLng?.toString() ?? '',
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
      clockInLat: double.tryParse('${map['clockInLat'] ?? ''}'),
      clockInLng: double.tryParse('${map['clockInLng'] ?? ''}'),
      clockOutLat: double.tryParse('${map['clockOutLat'] ?? ''}'),
      clockOutLng: double.tryParse('${map['clockOutLng'] ?? ''}'),
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
    this.handoverEmail = '',
    this.handoverNote = '',
    this.handoverFileUrl = '',
  });

  final String id;
  final LeaveKind kind;
  final DateTime start;
  final DateTime end;
  final String note;
  final LeaveStatus status;
  final String handoverEmail;
  final String handoverNote;
  final String handoverFileUrl;

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
    'handoverEmail': handoverEmail,
    'handoverNote': handoverNote,
    'handoverFileUrl': handoverFileUrl,
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
      handoverEmail: '${map['handoverEmail'] ?? ''}',
      handoverNote: '${map['handoverNote'] ?? ''}',
      handoverFileUrl: '${map['handoverFileUrl'] ?? ''}',
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
    this.statusLabel = '',
    this.department = '',
    this.goals = '',
    this.strengths = '',
    this.achievements = '',
    this.developmentPlan = '',
    this.managerComments = '',
    this.rating,
    this.completed = false,
    this.employeeName = '',
    this.reviewerEmail = '',
  });

  final String id;
  final String title;
  final String reviewer;
  final String period;
  final String summary;
  final String statusLabel;
  final String department;
  final String goals;
  final String strengths;
  final String achievements;
  final String developmentPlan;
  final String managerComments;
  final double? rating;
  final bool completed;
  final String employeeName;
  final String reviewerEmail;

  String get statusText {
    if (statusLabel.trim().isNotEmpty) return statusLabel.trim();
    return completed ? 'Completed' : 'Open';
  }

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
    this.userId = '',
    this.myReaction,
    this.reactions = const {},
    this.comments = const [],
  });

  final String id;
  final String userId;
  final String author;
  final String role;
  final String title;
  final String body;
  final DateTime at;
  final String? myReaction;
  final Map<String, int> reactions;
  final List<StaffUpdateComment> comments;

  int get reactionTotal =>
      reactions.values.fold<int>(0, (sum, value) => sum + value);

  int get commentCount => comments.length;

  Map<String, String> toMap() => {
    'id': id,
    'userId': userId,
    'author': author,
    'role': role,
    'title': title,
    'body': body,
    'at': at.toIso8601String(),
    'myReaction': myReaction ?? '',
  };

  factory StaffUpdate.fromMap(Map<String, dynamic> map) {
    return StaffUpdate(
      id: '${map['id'] ?? ''}',
      userId: '${map['userId'] ?? ''}',
      author: '${map['author'] ?? ''}',
      role: '${map['role'] ?? ''}',
      title: '${map['title'] ?? ''}',
      body: '${map['body'] ?? ''}',
      at: DateTime.tryParse('${map['at'] ?? ''}') ?? DateTime.now(),
      myReaction: '${map['myReaction'] ?? ''}'.isEmpty
          ? null
          : '${map['myReaction']}',
    );
  }
}

class StaffUpdateComment {
  const StaffUpdateComment({
    required this.id,
    required this.updateId,
    required this.userId,
    required this.author,
    required this.body,
    required this.at,
  });

  final String id;
  final String updateId;
  final String userId;
  final String author;
  final String body;
  final DateTime at;
}

class FeedStats {
  const FeedStats({
    required this.posts,
    required this.reactions,
    required this.comments,
    required this.thisWeek,
  });

  final int posts;
  final int reactions;
  final int comments;
  final int thisWeek;
}

enum TicketCategory { it, facility }

extension TicketCategoryX on TicketCategory {
  String get storageValue => switch (this) {
    TicketCategory.it => 'it',
    TicketCategory.facility => 'facility',
  };

  String get label => switch (this) {
    TicketCategory.it => 'IT',
    TicketCategory.facility => 'Facility',
  };

  static TicketCategory parse(String? raw) {
    return switch ((raw ?? '').trim().toLowerCase()) {
      'facility' => TicketCategory.facility,
      _ => TicketCategory.it,
    };
  }
}

enum TicketStatus { pending, inProgress, done }

extension TicketStatusX on TicketStatus {
  String get storageValue => switch (this) {
    TicketStatus.pending => 'pending',
    TicketStatus.inProgress => 'in_progress',
    TicketStatus.done => 'done',
  };

  String get label => switch (this) {
    TicketStatus.pending => 'Pending',
    TicketStatus.inProgress => 'In progress',
    TicketStatus.done => 'Done',
  };

  static TicketStatus parse(String? raw) {
    return switch ((raw ?? '').trim().toLowerCase()) {
      'in_progress' => TicketStatus.inProgress,
      'done' => TicketStatus.done,
      _ => TicketStatus.pending,
    };
  }
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.reporterEmail,
    required this.category,
    required this.title,
    required this.description,
    required this.locationLabel,
    required this.imageUrls,
    required this.status,
    required this.createdAt,
    this.adminNote = '',
    this.assignedTo,
    this.updatedAt,
  });

  final String id;
  final String reporterId;
  final String reporterName;
  final String reporterEmail;
  final TicketCategory category;
  final String title;
  final String description;
  final String locationLabel;
  final List<String> imageUrls;
  final TicketStatus status;
  final String adminNote;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime? updatedAt;
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
  static const _mockUpdateIds = {'upd-1', 'upd-2', 'upd-3'};

  static const annualAllowance = 21;

  /// Drops the sample reviews and notices that older installs saved locally.
  Future<void> _forgetMockContent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_appraisalKey);
    await prefs.remove(_seededKey);
    final updates = _decode(
      prefs.getString(_updatesKey),
      StaffUpdate.fromMap,
    ).where((item) => !_mockUpdateIds.contains(item.id)).toList();
    if (updates.isEmpty) {
      await prefs.remove(_updatesKey);
      return;
    }
    await _save(_updatesKey, [for (final row in updates) row.toMap()]);
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
    final now = DateTime.now();
    return hoursOnLagosDay(await sessions(), lagosToday(now), now);
  }

  Future<ClockSession> clockIn({
    String? siteId,
    String? siteName,
    double? latitude,
    double? longitude,
  }) async {
    final existing = await openSession();
    if (existing != null) return existing;
    final device = await DeviceFingerprint.current();
    if (AuthService.isSignedIn) {
      final cloud = await BerpCloud.insertClockIn(
        siteId: siteId,
        siteName: siteName,
        device: device,
        latitude: latitude,
        longitude: longitude,
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
      clockInLat: latitude,
      clockInLng: longitude,
    );
    final all = [...await _localSessions(), session];
    await _save(_clockKey, [for (final item in all) item.toMap()]);
    return session;
  }

  Future<ClockSession?> clockOut({
    double? latitude,
    double? longitude,
  }) async {
    final open = await openSession();
    if (open == null) return null;
    try {
      final cloud = await BerpCloud.clockOut(
        open.id,
        latitude: latitude,
        longitude: longitude,
      );
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
      clockInLat: current.clockInLat,
      clockInLng: current.clockInLng,
      clockOutLat: latitude ?? current.clockOutLat,
      clockOutLng: longitude ?? current.clockOutLng,
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
    await _forgetMockContent();
    try {
      return await BerpCloud.appraisals();
    } catch (_) {
      return [];
    }
  }

  Future<List<StaffUpdate>> updates() async {
    await _forgetMockContent();
    try {
      final cloud = await BerpCloud.updates();
      if (cloud.isNotEmpty || AuthService.isSignedIn) {
        cloud.sort((a, b) => b.at.compareTo(a.at));
        return cloud;
      }
    } catch (_) {
      if (AuthService.isSignedIn) return [];
    }
    final prefs = await SharedPreferences.getInstance();
    final list = _decode(
      prefs.getString(_updatesKey),
      StaffUpdate.fromMap,
    ).where((item) => !_mockUpdateIds.contains(item.id)).toList();
    list.sort((a, b) => b.at.compareTo(a.at));
    return list;
  }

  Future<void> postUpdate({
    required String title,
    required String body,
    bool sendPush = false,
  }) async {
    try {
      final cloud = await BerpCloud.insertUpdate(
        title: title,
        body: body,
        sendPush: sendPush,
      );
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

  Future<void> reactToUpdate(String updateId, String? reaction) async {
    await BerpCloud.setUpdateReaction(updateId: updateId, reaction: reaction);
  }

  Future<StaffUpdateComment?> commentOnUpdate({
    required String updateId,
    required String body,
  }) {
    return BerpCloud.addUpdateComment(updateId: updateId, body: body);
  }

  Future<FeedStats> feedStats() => BerpCloud.feedStats();

  Future<List<SupportTicket>> tickets({bool mineOnly = false}) {
    return BerpCloud.tickets(mineOnly: mineOnly);
  }

  Future<SupportTicket?> createTicket({
    required TicketCategory category,
    required String title,
    required String description,
    required String locationLabel,
    List<Uint8List> images = const [],
  }) {
    return BerpCloud.createTicket(
      category: category,
      title: title,
      description: description,
      locationLabel: locationLabel,
      images: images,
    );
  }

  Future<SupportTicket?> updateTicketStatus({
    required String id,
    required TicketStatus status,
    String? adminNote,
  }) {
    return BerpCloud.updateTicketStatus(
      id: id,
      status: status,
      adminNote: adminNote,
    );
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

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _shortMonths = [
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

/// Lagos calendar date for [instant], stored as a UTC date-only value.
DateTime lagosToday([DateTime? instant]) {
  final wall = lagosWallClock(instant ?? DateTime.now());
  return DateTime.utc(wall.year, wall.month, wall.day);
}

DateTime lagosWeekMonday([DateTime? instant]) {
  final today = lagosToday(instant);
  return today.subtract(Duration(days: today.weekday - 1));
}

/// Hours worked on a Lagos calendar day. Open sessions count up to [now].
Duration hoursOnLagosDay(
  List<ClockSession> sessions,
  DateTime day, [
  DateTime? now,
]) {
  final clock = now ?? DateTime.now();
  final start = DateTime.utc(day.year, day.month, day.day).subtract(
    const Duration(hours: 1),
  );
  final end = start.add(const Duration(days: 1));
  var total = Duration.zero;
  for (final session in sessions) {
    final stop = session.clockOut ?? clock;
    final from = session.clockIn.isBefore(start) ? start : session.clockIn;
    final to = stop.isAfter(end) ? end : stop;
    if (to.isAfter(from)) total += to.difference(from);
  }
  return total;
}

List<Duration> lagosWeekHours(List<ClockSession> sessions, [DateTime? now]) {
  final clock = now ?? DateTime.now();
  final monday = lagosWeekMonday(clock);
  return [
    for (var i = 0; i < 7; i++)
      hoursOnLagosDay(sessions, monday.add(Duration(days: i)), clock),
  ];
}

/// Office start is 09:00 Lagos, Monday to Friday.
class ShiftCue {
  const ShiftCue({required this.when, required this.time});

  final String when;
  final String time;
}

ShiftCue upcomingShift([DateTime? now]) {
  final wall = lagosWallClock(now ?? DateTime.now());
  var day = DateTime.utc(wall.year, wall.month, wall.day);
  final beforeOpen = wall.hour < 9;
  if (!(beforeOpen && day.weekday <= DateTime.friday)) {
    do {
      day = day.add(const Duration(days: 1));
    } while (day.weekday > DateTime.friday);
  }
  final today = DateTime.utc(wall.year, wall.month, wall.day);
  final diff = day.difference(today).inDays;
  final when = switch (diff) {
    0 => 'Today',
    1 => 'Tomorrow',
    _ => _weekdays[day.weekday - 1],
  };
  return ShiftCue(when: when, time: '9 AM');
}

String formatLagosLongDay(DateTime instant) {
  final wall = lagosWallClock(instant);
  return '${_weekdays[wall.weekday - 1]}, ${wall.day} ${_shortMonths[wall.month - 1]} ${wall.year}';
}

String weekdayName(DateTime day) => _weekdays[day.weekday - 1];

String formatHoursCompact(Duration value) {
  final minutes = value.inMinutes;
  if (minutes <= 0) return '0h';
  if (minutes < 60) return '${minutes}m';
  final whole = minutes ~/ 60;
  final tenths = (((minutes % 60) / 60) * 10).round();
  if (tenths <= 0) return '${whole}h';
  if (tenths >= 10) return '${whole + 1}h';
  return '$whole.${tenths}h';
}

String formatTimeAgo(DateTime value) {
  final delta = DateTime.now().difference(value);
  if (delta.isNegative || delta.inSeconds < 45) return 'Just now';
  if (delta.inMinutes < 60) {
    final m = delta.inMinutes;
    return m == 1 ? '1 minute ago' : '$m minutes ago';
  }
  if (delta.inHours < 24) {
    final h = delta.inHours;
    return h == 1 ? '1 hour ago' : '$h hours ago';
  }
  if (delta.inDays < 14) {
    final d = delta.inDays;
    return d == 1 ? '1 day ago' : '$d days ago';
  }
  return formatDay(value);
}
