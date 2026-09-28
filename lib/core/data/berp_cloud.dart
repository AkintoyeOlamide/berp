import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_service.dart';
import '../notifications/push_inbox.dart';
import '../theme/app_colors.dart';
import 'device_fingerprint.dart';
import 'staff_profile.dart';
import 'staff_store.dart';

/// Reads and writes BERP rows in the shared BHR Supabase project.
/// Every row is tagged with [BerpBrand.appId] and the signed-in [userId].
abstract final class BerpCloud {
  static const appId = BerpBrand.appId;

  static String? get userId => AuthService.currentUser?.id;

  static SupabaseClient? get _client {
    if (userId == null) return null;
    try {
      return AuthService.client;
    } catch (_) {
      return null;
    }
  }

  static Future<List<ClockSession>> clockSessions() async {
    final db = _client;
    final uid = userId;
    if (db == null || uid == null) return [];
    final res = await db
        .from('clock_sessions')
        .select()
        .eq('app_id', appId)
        .eq('user_id', uid)
        .order('clock_in', ascending: false);
    final rows = [
      for (final row in res as List<dynamic>)
        if (row is Map<String, dynamic>) _clockFromRow(row),
    ];
    return _withDevicePriority(rows);
  }

  /// Marks sessions when the staff member used more than 3 devices in 7 days.
  static List<ClockSession> _withDevicePriority(List<ClockSession> rows) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final devices = <String>{};
    for (final row in rows) {
      final id = row.deviceId?.trim() ?? '';
      if (id.isEmpty) continue;
      if (row.clockIn.isBefore(weekAgo)) continue;
      devices.add(id);
    }
    final priority = devices.length > 3;
    if (!priority) return rows;
    return [
      for (final row in rows)
        ClockSession(
          id: row.id,
          clockIn: row.clockIn,
          clockOut: row.clockOut,
          siteId: row.siteId,
          siteName: row.siteName,
          deviceId: row.deviceId,
          deviceLabel: row.deviceLabel,
          deviceModel: row.deviceModel,
          deviceOs: row.deviceOs,
          publicIp: row.publicIp,
          multiDevicePriority: true,
        ),
    ];
  }

  static Future<ClockSession?> insertClockIn({
    String? siteId,
    String? siteName,
    DateTime? clockIn,
    DeviceContext? device,
  }) async {
    final db = _client;
    final uid = userId;
    if (db == null || uid == null) return null;
    final at = clockIn ?? DateTime.now();
    final fingerprint = device ?? await DeviceFingerprint.current();
    final payload = <String, dynamic>{
      'app_id': appId,
      'user_id': uid,
      'clock_in': at.toUtc().toIso8601String(),
      'clock_in_lagos': formatLagosStamp(at),
      'site_id': siteId,
      'site_name': siteName,
      ...fingerprint.toPayload(),
    };
    try {
      final res = await db
          .from('clock_sessions')
          .insert(payload)
          .select()
          .single();
      await _touchDevice(fingerprint);
      return _clockFromRow(Map<String, dynamic>.from(res as Map));
    } catch (_) {
      payload.remove('clock_in_lagos');
      try {
        final res = await db
            .from('clock_sessions')
            .insert(payload)
            .select()
            .single();
        await _touchDevice(fingerprint);
        return _clockFromRow(Map<String, dynamic>.from(res as Map));
      } catch (_) {
        // Schema may not have device columns yet — retry without them.
        for (final key in [
          'device_id',
          'device_label',
          'device_model',
          'device_os',
          'public_ip',
        ]) {
          payload.remove(key);
        }
        final res = await db
            .from('clock_sessions')
            .insert(payload)
            .select()
            .single();
        return _clockFromRow(Map<String, dynamic>.from(res as Map));
      }
    }
  }

  static Future<void> _touchDevice(DeviceContext device) async {
    final db = _client;
    final uid = userId;
    if (db == null || uid == null) return;
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await db.from('clock_devices').upsert({
        'app_id': appId,
        'user_id': uid,
        'device_id': device.deviceId,
        'device_label': device.label,
        'device_model': device.model,
        'device_os': device.os,
        'last_public_ip': device.publicIp,
        'last_seen_at': now,
      }, onConflict: 'app_id,user_id,device_id');
    } catch (_) {}
  }

  static Future<ClockSession?> clockOut(String sessionId) async {
    final db = _client;
    final uid = userId;
    if (db == null || uid == null) return null;
    final out = DateTime.now();
    final payload = {
      'clock_out': out.toUtc().toIso8601String(),
      'clock_out_lagos': formatLagosStamp(out),
    };
    try {
      final res = await db
          .from('clock_sessions')
          .update(payload)
          .eq('id', sessionId)
          .eq('app_id', appId)
          .eq('user_id', uid)
          .select()
          .maybeSingle();
      if (res == null) return null;
      return _clockFromRow(Map<String, dynamic>.from(res));
    } catch (_) {
      payload.remove('clock_out_lagos');
      final res = await db
          .from('clock_sessions')
          .update(payload)
          .eq('id', sessionId)
          .eq('app_id', appId)
          .eq('user_id', uid)
          .select()
          .maybeSingle();
      if (res == null) return null;
      return _clockFromRow(Map<String, dynamic>.from(res));
    }
  }

  static Future<List<LeaveRequest>> leaveRequests() async {
    final db = _client;
    final uid = userId;
    if (db == null || uid == null) return [];
    final res = await db
        .from('leave_requests')
        .select()
        .eq('app_id', appId)
        .eq('user_id', uid)
        .order('start_date', ascending: false);
    return [
      for (final row in res as List<dynamic>)
        if (row is Map<String, dynamic>) _leaveFromRow(row),
    ];
  }

  static Future<LeaveRequest?> insertLeave(LeaveRequest request) async {
    final db = _client;
    final uid = userId;
    if (db == null || uid == null) return null;
    final res = await db
        .from('leave_requests')
        .insert({
          'app_id': appId,
          'user_id': uid,
          'kind': request.kind.name,
          'start_date': _dateOnly(request.start),
          'end_date': _dateOnly(request.end),
          'note': request.note,
          'status': request.status.name,
        })
        .select()
        .single();
    return _leaveFromRow(Map<String, dynamic>.from(res as Map));
  }

  static Future<List<StaffUpdate>> updates() async {
    final db = _client;
    if (db == null) return [];
    final res = await db
        .from('staff_updates')
        .select()
        .eq('app_id', appId)
        .order('created_at', ascending: false)
        .limit(80);
    return [
      for (final row in res as List<dynamic>)
        if (row is Map<String, dynamic>) _updateFromRow(row),
    ];
  }

  static Future<StaffUpdate?> insertUpdate({
    required String title,
    required String body,
  }) async {
    final db = _client;
    final uid = userId;
    if (db == null || uid == null) return null;
    final res = await db
        .from('staff_updates')
        .insert({
          'app_id': appId,
          'user_id': uid,
          'author_name': StaffIdentity.name,
          'author_role': StaffIdentity.role,
          'title': title,
          'body': body,
        })
        .select()
        .single();
    return _updateFromRow(Map<String, dynamic>.from(res as Map));
  }

  static Future<List<AppraisalRecord>> appraisals() async {
    final db = _client;
    final uid = userId;
    if (db == null || uid == null) return [];
    final res = await db
        .from('appraisals')
        .select()
        .eq('employee_id', uid)
        .order('created_at', ascending: false);
    return [
      for (final row in res as List<dynamic>)
        if (row is Map<String, dynamic>) _appraisalFromRow(row),
    ];
  }

  static ClockSession _clockFromRow(Map<String, dynamic> row) {
    return ClockSession(
      id: '${row['id']}',
      clockIn:
          DateTime.tryParse('${row['clock_in']}')?.toLocal() ?? DateTime.now(),
      clockOut: DateTime.tryParse('${row['clock_out'] ?? ''}')?.toLocal(),
      siteId: _emptyToNull(row['site_id']),
      siteName: _emptyToNull(row['site_name']),
      deviceId: _emptyToNull(row['device_id']),
      deviceLabel: _emptyToNull(row['device_label']),
      deviceModel: _emptyToNull(row['device_model']),
      deviceOs: _emptyToNull(row['device_os']),
      publicIp: _emptyToNull(row['public_ip']),
    );
  }

  static LeaveRequest _leaveFromRow(Map<String, dynamic> row) {
    return LeaveRequest(
      id: '${row['id']}',
      kind: LeaveKind.values.firstWhere(
        (k) => k.name == row['kind'],
        orElse: () => LeaveKind.annual,
      ),
      start: DateTime.tryParse('${row['start_date']}') ?? DateTime.now(),
      end: DateTime.tryParse('${row['end_date']}') ?? DateTime.now(),
      note: '${row['note'] ?? ''}',
      status: LeaveStatus.values.firstWhere(
        (s) => s.name == row['status'],
        orElse: () => LeaveStatus.pending,
      ),
    );
  }

  static StaffUpdate _updateFromRow(Map<String, dynamic> row) {
    return StaffUpdate(
      id: '${row['id']}',
      author: '${row['author_name'] ?? ''}',
      role: '${row['author_role'] ?? ''}',
      title: '${row['title'] ?? ''}',
      body: '${row['body'] ?? ''}',
      at:
          DateTime.tryParse('${row['created_at']}')?.toLocal() ??
          DateTime.now(),
    );
  }

  static Future<StaffProfile?> fetchProfile() async {
    final db = _client;
    final uid = userId;
    final user = AuthService.currentUser;
    if (db == null || uid == null || user == null) return null;
    final res = await db.from('profiles').select().eq('id', uid).maybeSingle();
    return _profileFromRow(
      uid: uid,
      user: user,
      row: res == null ? null : Map<String, dynamic>.from(res),
    );
  }

  static Future<StaffProfile?> saveProfile(
    StaffProfile profile, {
    Uint8List? photoBytes,
  }) async {
    final db = _client;
    final uid = userId;
    final user = AuthService.currentUser;
    if (db == null || uid == null || user == null) return null;
    final email = (user.email ?? profile.email).trim().toLowerCase();
    final fullName = profile.fullName.trim().isEmpty
        ? StaffIdentity.name
        : profile.fullName.trim();
    var avatarUrl = profile.avatarUrl.trim();
    if (photoBytes != null && photoBytes.isNotEmpty) {
      avatarUrl = await _uploadAvatar(db, uid, photoBytes);
    }
    final fields = {
      'full_name': fullName,
      'department': profile.department.trim(),
      'job_title': profile.designation.trim(),
      'company': profile.company.trim(),
      'joined_year': profile.joinedYear,
      if (avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
    };
    final existing = await db
        .from('profiles')
        .select('id')
        .eq('id', uid)
        .maybeSingle();
    final Map<String, dynamic> res;
    if (existing == null) {
      res = Map<String, dynamic>.from(
        await db
                .from('profiles')
                .insert({
                  'id': uid,
                  'email': email,
                  'role': 'employee',
                  ...fields,
                })
                .select()
                .single()
            as Map,
      );
    } else {
      res = Map<String, dynamic>.from(
        await db.from('profiles').update(fields).eq('id', uid).select().single()
            as Map,
      );
    }
    return _profileFromRow(uid: uid, user: user, row: res);
  }

  static Future<String> _uploadAvatar(
    SupabaseClient db,
    String uid,
    Uint8List bytes,
  ) async {
    final path = '$uid/avatar.jpg';
    await db.storage
        .from('berp-avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
    final publicUrl = db.storage.from('berp-avatars').getPublicUrl(path);
    return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  static StaffProfile _profileFromRow({
    required String uid,
    required User user,
    Map<String, dynamic>? row,
  }) {
    final meta = user.userMetadata;
    final metaName = '${meta?['full_name'] ?? meta?['name'] ?? ''}'.trim();
    return StaffProfile(
      id: uid,
      fullName:
          _emptyToNull(row?['full_name']) ??
          (metaName.isEmpty ? StaffIdentity.name : metaName),
      email: _emptyToNull(row?['email']) ?? user.email ?? '',
      department: _emptyToNull(row?['department']) ?? '',
      company: _emptyToNull(row?['company']) ?? '',
      designation: _emptyToNull(row?['job_title']) ?? '',
      joinedYear: row?['joined_year'] is num
          ? (row!['joined_year'] as num).toInt()
          : int.tryParse('${row?['joined_year'] ?? ''}'),
      avatarUrl: _emptyToNull(row?['avatar_url']) ?? '',
    );
  }

  static AppraisalRecord _appraisalFromRow(Map<String, dynamic> row) {
    final reviewer = '${row['reviewer_id'] ?? ''}'.trim();
    final status = '${row['status'] ?? ''}';
    return AppraisalRecord(
      id: '${row['id']}',
      title: '${row['job_title'] ?? 'Performance review'}',
      reviewer: reviewer.isEmpty ? 'People' : 'Line manager',
      period: '${row['review_period'] ?? ''}',
      summary: '${row['manager_comments'] ?? status}',
      rating: (row['overall_score'] as num?)?.toDouble(),
      completed: status == 'completed' || status == 'submitted',
    );
  }

  static Future<List<BerpPushMessage>> pendingAdminPushes() async {
    final db = _client;
    if (db == null) return [];
    try {
      final since = DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 48))
          .toIso8601String();
      final res = await db
          .from('berp_push_messages')
          .select()
          .eq('app_id', appId)
          .eq('kind', 'admin')
          .inFilter('status', ['scheduled', 'sent'])
          .gte('scheduled_at', since)
          .order('scheduled_at', ascending: true)
          .limit(50);
      return [
        for (final row in res as List<dynamic>)
          if (row is Map<String, dynamic>) BerpPushMessage.fromJson(row),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<void> markPushSent(String messageId) async {
    final db = _client;
    if (db == null || messageId.isEmpty) return;
    try {
      await db
          .from('berp_push_messages')
          .update({
            'status': 'sent',
            'sent_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', messageId)
          .eq('app_id', appId);
    } catch (_) {}
  }

  static Future<void> logPushDelivery({
    String? messageId,
    required String title,
    required String body,
    required String status,
    String? deviceId,
    Map<String, dynamic>? meta,
  }) async {
    final db = _client;
    final uid = userId;
    if (db == null || uid == null) return;
    try {
      await db.from('berp_push_deliveries').insert({
        'app_id': appId,
        'message_id': messageId,
        'user_id': uid,
        'device_id': deviceId,
        'status': status,
        'title': title,
        'body': body,
        'meta': meta ?? {},
        'at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }

  /// Same as [logPushDelivery], but skips if this device already logged
  /// [dedupeKey] today (stored in SharedPreferences via meta is not enough —
  /// we check recent rows lightly via prefs).
  static Future<void> logPushDeliveryOncePerDay({
    String? messageId,
    required String dedupeKey,
    required String title,
    required String body,
    required String status,
    String? deviceId,
    Map<String, dynamic>? meta,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'berp_push_dedupe_$dedupeKey';
      if (prefs.getBool(key) == true) return;
      await logPushDelivery(
        messageId: messageId,
        title: title,
        body: body,
        status: status,
        deviceId: deviceId,
        meta: {...?meta, 'dedupe': dedupeKey},
      );
      await prefs.setBool(key, true);
    } catch (_) {}
  }

  static String _dateOnly(DateTime value) {
    final local = value.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String? _emptyToNull(Object? value) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty ? null : text;
  }
}
