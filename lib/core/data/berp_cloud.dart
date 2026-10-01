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
          clockInLat: row.clockInLat,
          clockInLng: row.clockInLng,
          clockOutLat: row.clockOutLat,
          clockOutLng: row.clockOutLng,
        ),
    ];
  }

  static Future<ClockSession?> insertClockIn({
    String? siteId,
    String? siteName,
    DateTime? clockIn,
    DeviceContext? device,
    double? latitude,
    double? longitude,
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
      if (latitude != null) 'clock_in_lat': latitude,
      if (longitude != null) 'clock_in_lng': longitude,
      if (_isUuid(siteId)) 'location_id': siteId,
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
      payload.remove('clock_in_lat');
      payload.remove('clock_in_lng');
      payload.remove('location_id');
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

  static Future<ClockSession?> clockOut(
    String sessionId, {
    double? latitude,
    double? longitude,
  }) async {
    final db = _client;
    final uid = userId;
    if (db == null || uid == null) return null;
    final out = DateTime.now();
    final payload = {
      'clock_out': out.toUtc().toIso8601String(),
      'clock_out_lagos': formatLagosStamp(out),
      if (latitude != null) 'clock_out_lat': latitude,
      if (longitude != null) 'clock_out_lng': longitude,
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
      payload.remove('clock_out_lat');
      payload.remove('clock_out_lng');
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
    final payload = <String, dynamic>{
      'app_id': appId,
      'user_id': uid,
      'kind': request.kind.name,
      'start_date': _dateOnly(request.start),
      'end_date': _dateOnly(request.end),
      'note': request.note,
      'status': request.status.name,
      'handover_email': request.handoverEmail,
      'handover_note': request.handoverNote,
      'handover_file_url': request.handoverFileUrl,
    };
    try {
      final res = await db.from('leave_requests').insert(payload).select().single();
      return _leaveFromRow(Map<String, dynamic>.from(res as Map));
    } catch (_) {
      payload.remove('handover_email');
      payload.remove('handover_note');
      payload.remove('handover_file_url');
      final res = await db.from('leave_requests').insert(payload).select().single();
      return _leaveFromRow(Map<String, dynamic>.from(res as Map));
    }
  }

  static Future<List<StaffUpdate>> updates() async {
    final db = _client;
    if (db == null) return [];
    final uid = userId;
    final res = await db
        .from('staff_updates')
        .select()
        .eq('app_id', appId)
        .order('created_at', ascending: false)
        .limit(80);
    final rows = [
      for (final row in res as List<dynamic>)
        if (row is Map) Map<String, dynamic>.from(row),
    ];
    if (rows.isEmpty) return [];

    final ids = [for (final row in rows) '${row['id']}'];
    final reactionCounts = <String, Map<String, int>>{};
    final myReactions = <String, String>{};
    final commentsByUpdate = <String, List<StaffUpdateComment>>{};

    try {
      final reactionRes = await db
          .from('staff_update_reactions')
          .select()
          .eq('app_id', appId)
          .inFilter('update_id', ids);
      for (final row in reactionRes as List<dynamic>) {
        if (row is! Map) continue;
        final updateId = '${row['update_id']}';
        final reaction = '${row['reaction'] ?? 'like'}';
        final bucket = reactionCounts.putIfAbsent(updateId, () => {});
        bucket[reaction] = (bucket[reaction] ?? 0) + 1;
        if (uid != null && '${row['user_id']}' == uid) {
          myReactions[updateId] = reaction;
        }
      }
    } catch (_) {}

    try {
      final commentRes = await db
          .from('staff_update_comments')
          .select()
          .eq('app_id', appId)
          .inFilter('update_id', ids)
          .order('created_at', ascending: true);
      for (final row in commentRes as List<dynamic>) {
        if (row is! Map) continue;
        final comment = _commentFromRow(Map<String, dynamic>.from(row));
        commentsByUpdate
            .putIfAbsent(comment.updateId, () => [])
            .add(comment);
      }
    } catch (_) {}

    return [
      for (final row in rows)
        _updateFromRow(
          row,
          reactions: reactionCounts['${row['id']}'] ?? const {},
          myReaction: myReactions['${row['id']}'],
          comments: commentsByUpdate['${row['id']}'] ?? const [],
        ),
    ];
  }

  static Future<FeedStats> feedStats() async {
    final items = await updates();
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    var reactions = 0;
    var comments = 0;
    var thisWeek = 0;
    for (final item in items) {
      reactions += item.reactionTotal;
      comments += item.commentCount;
      if (item.at.isAfter(weekAgo)) thisWeek += 1;
    }
    return FeedStats(
      posts: items.length,
      reactions: reactions,
      comments: comments,
      thisWeek: thisWeek,
    );
  }

  static Future<StaffUpdate?> insertUpdate({
    required String title,
    required String body,
    bool sendPush = false,
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
    final update = _updateFromRow(Map<String, dynamic>.from(res as Map));
    if (sendPush) {
      await scheduleAdminPush(
        title: title,
        body: body,
        scheduledAt: DateTime.now(),
      );
    }
    return update;
  }

  static Future<void> scheduleAdminPush({
    required String title,
    required String body,
    DateTime? scheduledAt,
    String audience = 'all',
  }) async {
    final db = _client;
    final uid = userId;
    if (db == null || uid == null) return;
    final when = (scheduledAt ?? DateTime.now()).toUtc();
    try {
      await db.from('berp_push_messages').insert({
        'app_id': appId,
        'kind': 'admin',
        'title': title,
        'body': body,
        'scheduled_at': when.toIso8601String(),
        'status': 'scheduled',
        'created_by': uid,
        'audience': audience,
      });
    } catch (_) {
      try {
        await db.from('berp_push_messages').insert({
          'app_id': appId,
          'kind': 'admin',
          'title': title,
          'body': body,
          'scheduled_at': when.toIso8601String(),
          'status': 'scheduled',
          'created_by': uid,
        });
      } catch (_) {}
    }
  }

  static Future<List<SupportTicket>> tickets({bool mineOnly = false}) async {
    final db = _client;
    final uid = userId;
    if (db == null) return [];
    try {
      var query = db.from('support_tickets').select().eq('app_id', appId);
      if (mineOnly && uid != null) {
        query = query.eq('reporter_id', uid);
      }
      final res = await query.order('created_at', ascending: false).limit(200);
      return [
        for (final row in res as List<dynamic>)
          if (row is Map) _ticketFromRow(Map<String, dynamic>.from(row)),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<SupportTicket?> createTicket({
    required TicketCategory category,
    required String title,
    required String description,
    required String locationLabel,
    List<Uint8List> images = const [],
  }) async {
    final db = _client;
    final uid = userId;
    if (db == null || uid == null) return null;
    final urls = <String>[];
    for (var i = 0; i < images.length && i < 3; i++) {
      final url = await uploadTicketImage(images[i], index: i);
      if (url.isNotEmpty) urls.add(url);
    }
    final profile = await fetchProfile();
    final res = await db
        .from('support_tickets')
        .insert({
          'app_id': appId,
          'reporter_id': uid,
          'reporter_name':
              profile?.fullName.trim().isNotEmpty == true
                  ? profile!.fullName.trim()
                  : StaffIdentity.name,
          'reporter_email':
              (profile?.email ?? AuthService.currentUser?.email ?? '').trim(),
          'category': category.storageValue,
          'title': title.trim(),
          'description': description.trim(),
          'location_label': locationLabel.trim(),
          'image_urls': urls,
          'status': TicketStatus.pending.storageValue,
        })
        .select()
        .single();
    return _ticketFromRow(Map<String, dynamic>.from(res as Map));
  }

  static Future<String> uploadTicketImage(
    Uint8List bytes, {
    int index = 0,
  }) async {
    final db = _client;
    final uid = userId;
    if (db == null || uid == null) return '';
    try {
      final path =
          '$uid/tickets/${DateTime.now().millisecondsSinceEpoch}-$index.jpg';
      await db.storage.from('berp-avatars').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      return db.storage.from('berp-avatars').getPublicUrl(path);
    } catch (_) {
      return '';
    }
  }

  static Future<SupportTicket?> updateTicketStatus({
    required String id,
    required TicketStatus status,
    String? adminNote,
  }) async {
    final db = _client;
    final uid = userId;
    if (db == null || uid == null || id.isEmpty) return null;
    final payload = <String, dynamic>{
      'status': status.storageValue,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'assigned_to': uid,
      if (adminNote != null) 'admin_note': adminNote.trim(),
    };
    try {
      final res = await db
          .from('support_tickets')
          .update(payload)
          .eq('id', id)
          .eq('app_id', appId)
          .select()
          .single();
      return _ticketFromRow(Map<String, dynamic>.from(res as Map));
    } catch (_) {
      return null;
    }
  }

  static SupportTicket _ticketFromRow(Map<String, dynamic> row) {
    final rawImages = row['image_urls'];
    final images = <String>[];
    if (rawImages is List) {
      for (final item in rawImages) {
        final text = '$item'.trim();
        if (text.isNotEmpty) images.add(text);
      }
    }
    return SupportTicket(
      id: '${row['id']}',
      reporterId: '${row['reporter_id'] ?? ''}',
      reporterName: '${row['reporter_name'] ?? ''}',
      reporterEmail: '${row['reporter_email'] ?? ''}',
      category: TicketCategoryX.parse('${row['category']}'),
      title: '${row['title'] ?? ''}',
      description: '${row['description'] ?? ''}',
      locationLabel: '${row['location_label'] ?? ''}',
      imageUrls: images,
      status: TicketStatusX.parse('${row['status']}'),
      adminNote: '${row['admin_note'] ?? ''}',
      assignedTo: '${row['assigned_to'] ?? ''}'.isEmpty
          ? null
          : '${row['assigned_to']}',
      createdAt:
          DateTime.tryParse('${row['created_at']}')?.toLocal() ??
          DateTime.now(),
      updatedAt: DateTime.tryParse('${row['updated_at']}')?.toLocal(),
    );
  }

  static Future<void> setUpdateReaction({
    required String updateId,
    required String? reaction,
  }) async {
    final db = _client;
    final uid = userId;
    if (db == null || uid == null || updateId.isEmpty) return;
    try {
      await db
          .from('staff_update_reactions')
          .delete()
          .eq('update_id', updateId)
          .eq('user_id', uid);
      if (reaction == null || reaction.isEmpty) return;
      await db.from('staff_update_reactions').insert({
        'app_id': appId,
        'update_id': updateId,
        'user_id': uid,
        'reaction': reaction,
      });
    } catch (_) {}
  }

  static Future<StaffUpdateComment?> addUpdateComment({
    required String updateId,
    required String body,
  }) async {
    final db = _client;
    final uid = userId;
    final text = body.trim();
    if (db == null || uid == null || updateId.isEmpty || text.isEmpty) {
      return null;
    }
    try {
      final res = await db
          .from('staff_update_comments')
          .insert({
            'app_id': appId,
            'update_id': updateId,
            'user_id': uid,
            'author_name': StaffIdentity.name,
            'body': text,
          })
          .select()
          .single();
      return _commentFromRow(Map<String, dynamic>.from(res as Map));
    } catch (_) {
      return null;
    }
  }

  static StaffUpdateComment _commentFromRow(Map<String, dynamic> row) {
    return StaffUpdateComment(
      id: '${row['id']}',
      updateId: '${row['update_id']}',
      userId: '${row['user_id'] ?? ''}',
      author: '${row['author_name'] ?? ''}',
      body: '${row['body'] ?? ''}',
      at: DateTime.tryParse('${row['created_at']}')?.toLocal() ??
          DateTime.now(),
    );
  }

  static const _appraisalSelect =
      'id, employee_id, reviewer_id, cycle_id, job_title, review_period, department, goals, strengths, achievements, development_plan, manager_comments, overall_score, status, created_at, submitted_at, completed_at, employee:legacy_employee_profiles!employee_id!inner(email, full_name), reviewer:legacy_employee_profiles!reviewer_id(email, full_name, job_title), cycle:appraisal_cycles!cycle_id(title, start_date, end_date, status)';

  /// BHR links each appraisal to a work email on legacy_employee_profiles.
  static Future<List<AppraisalRecord>> appraisals() async {
    final db = _client;
    final email = AuthService.currentUser?.email?.trim();
    if (db == null || email == null || email.isEmpty) return [];
    final res = await db
        .from('appraisals')
        .select(
          _appraisalSelect,
        )
        .ilike('employee.email', email)
        .order('created_at', ascending: false);
    return [
      for (final row in res as List<dynamic>)
        if (row is Map<String, dynamic>) _appraisalFromRow(row),
    ];
  }

  static Future<List<AppraisalRecord>> reviewerAppraisals() async {
    final db = _client;
    final email = AuthService.currentUser?.email?.trim();
    if (db == null || email == null || email.isEmpty) return [];
    final res = await db
        .from('appraisals')
        .select(
          'id, employee_id, reviewer_id, cycle_id, job_title, review_period, department, goals, strengths, achievements, development_plan, manager_comments, overall_score, status, created_at, submitted_at, completed_at, employee:legacy_employee_profiles!employee_id(email, full_name), reviewer:legacy_employee_profiles!reviewer_id!inner(email, full_name, job_title), cycle:appraisal_cycles!cycle_id(title, start_date, end_date, status)',
        )
        .ilike('reviewer.email', email)
        .order('created_at', ascending: false);
    return [
      for (final row in res as List<dynamic>)
        if (row is Map<String, dynamic>) _appraisalFromRow(row),
    ];
  }

  static Future<List<AppraisalRecord>> appraisalsForEmails(
    List<String> emails,
  ) async {
    final db = _client;
    final cleaned = emails
        .map((email) => email.trim())
        .where((email) => email.isNotEmpty)
        .toSet()
        .toList();
    if (db == null || cleaned.isEmpty) return [];
    final res = await db
        .from('appraisals')
        .select(_appraisalSelect)
        .or(cleaned.map((email) => 'employee.email.ilike.$email').join(','))
        .order('created_at', ascending: false)
        .limit(200);
    return [
      for (final row in res as List<dynamic>)
        if (row is Map<String, dynamic>) _appraisalFromRow(row),
    ];
  }

  static Future<List<AppraisalRecord>> organisationAppraisals() async {
    final db = _client;
    if (db == null) return [];
    final res = await db
        .from('appraisals')
        .select(
          'id, employee_id, reviewer_id, cycle_id, job_title, review_period, department, goals, strengths, achievements, development_plan, manager_comments, overall_score, status, created_at, submitted_at, completed_at, employee:legacy_employee_profiles!employee_id(email, full_name), reviewer:legacy_employee_profiles!reviewer_id(email, full_name, job_title), cycle:appraisal_cycles!cycle_id(title, start_date, end_date, status)',
        )
        .order('created_at', ascending: false)
        .limit(200);
    return [
      for (final row in res as List<dynamic>)
        if (row is Map<String, dynamic>) _appraisalFromRow(row),
    ];
  }

  static Future<void> submitAppraisal({
    required String id,
    required String comments,
    required double score,
  }) async {
    final db = _client;
    if (db == null) return;
    final payload = <String, dynamic>{
      'manager_comments': comments,
      'overall_score': score,
      'status': 'submitted',
      'submitted_at': DateTime.now().toUtc().toIso8601String(),
    };
    try {
      await db.from('appraisals').update(payload).eq('id', id);
    } catch (_) {
      payload.remove('submitted_at');
      await db.from('appraisals').update(payload).eq('id', id);
    }
  }

  static ClockSession clockFromRow(Map<String, dynamic> row) =>
      _clockFromRow(row);

  static LeaveRequest leaveFromRow(Map<String, dynamic> row) =>
      _leaveFromRow(row);

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
      clockInLat: (row['clock_in_lat'] as num?)?.toDouble(),
      clockInLng: (row['clock_in_lng'] as num?)?.toDouble(),
      clockOutLat: (row['clock_out_lat'] as num?)?.toDouble(),
      clockOutLng: (row['clock_out_lng'] as num?)?.toDouble(),
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
      handoverEmail: '${row['handover_email'] ?? ''}',
      handoverNote: '${row['handover_note'] ?? ''}',
      handoverFileUrl: '${row['handover_file_url'] ?? ''}',
      status: LeaveStatus.values.firstWhere(
        (s) => s.name == row['status'],
        orElse: () => LeaveStatus.pending,
      ),
    );
  }

  static StaffUpdate _updateFromRow(
    Map<String, dynamic> row, {
    Map<String, int> reactions = const {},
    String? myReaction,
    List<StaffUpdateComment> comments = const [],
  }) {
    return StaffUpdate(
      id: '${row['id']}',
      userId: '${row['user_id'] ?? ''}',
      author: '${row['author_name'] ?? ''}',
      role: '${row['author_role'] ?? ''}',
      title: '${row['title'] ?? ''}',
      body: '${row['body'] ?? ''}',
      at:
          DateTime.tryParse('${row['created_at']}')?.toLocal() ??
          DateTime.now(),
      reactions: reactions,
      myReaction: myReaction,
      comments: comments,
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

  static Future<String> uploadHandover(Uint8List bytes) async {
    final db = _client;
    final uid = userId;
    if (db == null || uid == null) return '';
    try {
      final path = '$uid/handover-${DateTime.now().millisecondsSinceEpoch}.jpg';
      await db.storage.from('berp-avatars').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      return db.storage.from('berp-avatars').getPublicUrl(path);
    } catch (_) {
      return '';
    }
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
      role: _emptyToNull(row?['role']) ?? 'staff',
      managerId: _emptyToNull(row?['manager_id']),
      suspended: row?['suspended'] == true,
    );
  }

  static AppraisalRecord _appraisalFromRow(Map<String, dynamic> row) {
    final reviewerRow = _asMap(row['reviewer']);
    final employeeRow = _asMap(row['employee']);
    final cycle = _asMap(row['cycle']);
    final reviewerName = _text(reviewerRow?['full_name']);
    final reviewerRole = _text(reviewerRow?['job_title']);
    final reviewer = reviewerName.isEmpty
        ? 'Reviewer'
        : reviewerRole.isEmpty
        ? reviewerName
        : '$reviewerName · $reviewerRole';
    final cycleTitle = _text(cycle?['title']);
    final jobTitle = _text(row['job_title']);
    final reviewPeriod = _text(row['review_period']);
    final start = _text(cycle?['start_date']);
    final end = _text(cycle?['end_date']);
    final period = reviewPeriod.isNotEmpty
        ? reviewPeriod
        : (start.isNotEmpty && end.isNotEmpty)
        ? '$start – $end'
        : cycleTitle;
    final title = cycleTitle.isNotEmpty
        ? cycleTitle
        : jobTitle.isNotEmpty
        ? jobTitle
        : period.isNotEmpty
        ? period
        : 'Performance review';
    final status = _text(row['status']);
    final completed =
        _text(row['completed_at']).isNotEmpty ||
        const {
          'completed',
          'closed',
          'approved',
          'done',
          'finalized',
          'finalised',
        }.contains(status.toLowerCase());
    final goals = _text(row['goals']);
    final strengths = _text(row['strengths']);
    final achievements = _text(row['achievements']);
    final developmentPlan = _text(row['development_plan']);
    final managerComments = _text(row['manager_comments']);
    final summary = [
      if (managerComments.isNotEmpty) managerComments,
      if (strengths.isNotEmpty) strengths,
      if (achievements.isNotEmpty) achievements,
      if (goals.isNotEmpty) goals,
      if (developmentPlan.isNotEmpty) developmentPlan,
    ].join('\n\n');
    final score = row['overall_score'];
    return AppraisalRecord(
      id: '${row['id']}',
      title: title,
      reviewer: reviewer,
      period: period,
      summary: summary,
      statusLabel: status.isEmpty
          ? ''
          : '${status[0].toUpperCase()}${status.substring(1)}',
      department: _text(row['department']),
      goals: goals,
      strengths: strengths,
      achievements: achievements,
      developmentPlan: developmentPlan,
      managerComments: managerComments,
      rating: score is num ? score.toDouble() : double.tryParse('$score'),
      completed: completed,
      employeeName: _text(employeeRow?['full_name']),
      reviewerEmail: _text(reviewerRow?['email']),
    );
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    if (value is List && value.isNotEmpty) return _asMap(value.first);
    return null;
  }

  static String _text(Object? value) => '${value ?? ''}'.trim();

  static bool _isUuid(String? value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value ?? '');
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
