import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_service.dart';
import 'berp_cloud.dart';
import 'clock_sites.dart';
import 'staff_store.dart';

class OrgPerson {
  const OrgPerson({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.company,
    required this.jobTitle,
    this.managerId,
    this.avatarUrl = '',
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String department;
  final String company;
  final String jobTitle;
  final String? managerId;
  final String avatarUrl;

  factory OrgPerson.fromRow(Map<String, dynamic> row) {
    return OrgPerson(
      id: '${row['id']}',
      name: '${row['full_name'] ?? ''}'.trim(),
      email: '${row['email'] ?? ''}'.trim(),
      role: '${row['role'] ?? 'staff'}',
      department: '${row['department'] ?? ''}',
      company: '${row['company'] ?? ''}',
      jobTitle: '${row['job_title'] ?? ''}',
      managerId: '${row['manager_id'] ?? ''}'.isEmpty
          ? null
          : '${row['manager_id']}',
      avatarUrl: '${row['avatar_url'] ?? ''}',
    );
  }
}

class OrgClockPlace {
  const OrgClockPlace({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.isActive,
  });

  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool isActive;

  ClockSite toSite() {
    return ClockSite(
      id: id,
      name: name,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
    );
  }
}

class LiveShift {
  const LiveShift({
    required this.sessionId,
    required this.userId,
    required this.name,
    required this.department,
    required this.company,
    required this.jobTitle,
    required this.clockIn,
    required this.locationName,
    this.photoUrl = '',
    this.clockLat,
    this.clockLng,
    this.latestLat,
    this.latestLng,
    this.latestAt,
  });

  final String sessionId;
  final String userId;
  final String name;
  final String department;
  final String company;
  final String jobTitle;
  final DateTime clockIn;
  final String locationName;
  final String photoUrl;
  final double? clockLat;
  final double? clockLng;
  final double? latestLat;
  final double? latestLng;
  final DateTime? latestAt;
}

class AttendanceRow {
  const AttendanceRow({
    required this.session,
    required this.person,
  });

  final ClockSession session;
  final OrgPerson? person;
}

class TeamLeave {
  const TeamLeave({required this.request, required this.person});

  final LeaveRequest request;
  final OrgPerson? person;
}

class AppNotice {
  const AppNotice({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.referenceId,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final String? referenceId;
}

class AttendanceSummary {
  const AttendanceSummary({
    required this.totalStaff,
    required this.clockedIn,
    required this.clockInsToday,
  });

  final int totalStaff;
  final int clockedIn;
  final int clockInsToday;

  int get notClockedIn => (totalStaff - clockedIn).clamp(0, totalStaff);
}

/// Organisation data for managers and admins. Queries stay inside the
/// caller's RLS scope, and missing tables fail softly.
abstract final class BerpOrg {
  static SupabaseClient? get _db {
    if (AuthService.currentUser == null) return null;
    try {
      return AuthService.client;
    } catch (_) {
      return null;
    }
  }

  static Future<List<ClockSite>> activeSites() async {
    final places = await locations(activeOnly: true);
    if (places.isEmpty) return clockSites;
    return [for (final place in places) place.toSite()];
  }

  static Future<List<OrgClockPlace>> locations({bool activeOnly = false}) async {
    final db = _db;
    if (db == null) return [];
    try {
      var query = db.from('clock_locations').select().eq('app_id', BerpCloud.appId);
      if (activeOnly) query = query.eq('is_active', true);
      final res = await query.order('name');
      return [
        for (final row in res as List<dynamic>)
          if (row is Map)
            OrgClockPlace(
              id: '${row['id']}',
              name: '${row['name'] ?? ''}',
              address: '${row['address'] ?? ''}',
              latitude: (row['latitude'] as num?)?.toDouble() ?? 0,
              longitude: (row['longitude'] as num?)?.toDouble() ?? 0,
              radiusMeters: (row['radius_meters'] as num?)?.toDouble() ?? 150,
              isActive: row['is_active'] != false,
            ),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveLocation({
    String? id,
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    double radiusMeters = 150,
    bool isActive = true,
  }) async {
    final db = _db;
    final uid = AuthService.currentUser?.id;
    if (db == null) return;
    final payload = {
      'app_id': BerpCloud.appId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters.round(),
      'is_active': isActive,
      if (uid != null && (id == null || id.isEmpty)) 'created_by': uid,
    };
    if (id == null || id.isEmpty) {
      await db.from('clock_locations').insert(payload);
    } else {
      payload.remove('created_by');
      await db.from('clock_locations').update(payload).eq('id', id);
    }
  }

  static Future<void> setLocationActive(String id, bool active) async {
    final db = _db;
    if (db == null) return;
    await db.from('clock_locations').update({'is_active': active}).eq('id', id);
  }

  static Future<List<OrgPerson>> people() async {
    final db = _db;
    if (db == null) return [];
    try {
      final res = await db
          .from('profiles')
          .select(
            'id, full_name, email, role, department, job_title, company, manager_id, avatar_url',
          )
          .order('full_name');
      return [
        for (final row in res as List<dynamic>)
          if (row is Map<String, dynamic>) OrgPerson.fromRow(row)
          else if (row is Map)
            OrgPerson.fromRow(row.map((k, v) => MapEntry('$k', v))),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<List<OrgPerson>> team() async {
    final db = _db;
    final uid = AuthService.currentUser?.id;
    if (db == null || uid == null) return [];
    try {
      final res = await db
          .from('profiles')
          .select(
            'id, full_name, email, role, department, job_title, company, manager_id, avatar_url',
          )
          .eq('manager_id', uid)
          .order('full_name');
      return [
        for (final row in res as List<dynamic>)
          if (row is Map)
            OrgPerson.fromRow(Map<String, dynamic>.from(row)),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<void> assignManager(String staffId, String? managerId) async {
    final db = _db;
    if (db == null) return;
    await db.from('profiles').update({'manager_id': managerId}).eq('id', staffId);
  }

  static Future<void> assignRole(String staffId, String role) async {
    final db = _db;
    if (db == null) return;
    await db.from('profiles').update({'role': role}).eq('id', staffId);
  }

  static Future<AttendanceSummary> summary() async {
    final db = _db;
    if (db == null) {
      return const AttendanceSummary(totalStaff: 0, clockedIn: 0, clockInsToday: 0);
    }
    final peopleRows = await people();
    final open = await _openSessions();
    final today = lagosToday();
    final start = DateTime.utc(today.year, today.month, today.day).subtract(
      const Duration(hours: 1),
    );
    final end = start.add(const Duration(days: 1));
    var clockInsToday = 0;
    try {
      final res = await db
          .from('clock_sessions')
          .select('id')
          .eq('app_id', BerpCloud.appId)
          .gte('clock_in', start.toIso8601String())
          .lt('clock_in', end.toIso8601String());
      clockInsToday = (res as List).length;
    } catch (_) {}
    final clocked = open.map((row) => '${row['user_id']}').toSet().length;
    return AttendanceSummary(
      totalStaff: peopleRows.length,
      clockedIn: clocked,
      clockInsToday: clockInsToday,
    );
  }

  static Future<List<LiveShift>> liveShifts() async {
    final open = await _openSessions();
    if (open.isEmpty) return [];
    final directory = {for (final person in await people()) person.id: person};
    final latest = await _latestPoints([
      for (final row in open) '${row['id']}',
    ]);
    return [
      for (final row in open)
        LiveShift(
          sessionId: '${row['id']}',
          userId: '${row['user_id']}',
          name: directory['${row['user_id']}']?.name ?? 'Staff',
          department: directory['${row['user_id']}']?.department ?? '',
          company: directory['${row['user_id']}']?.company ?? '',
          jobTitle: directory['${row['user_id']}']?.jobTitle ?? '',
          photoUrl: directory['${row['user_id']}']?.avatarUrl ?? '',
          clockIn:
              DateTime.tryParse('${row['clock_in']}')?.toLocal() ??
              DateTime.now(),
          locationName: '${row['site_name'] ?? ''}',
          clockLat: (row['clock_in_lat'] as num?)?.toDouble(),
          clockLng: (row['clock_in_lng'] as num?)?.toDouble(),
          latestLat: latest['${row['id']}']?.$1,
          latestLng: latest['${row['id']}']?.$2,
          latestAt: latest['${row['id']}']?.$3,
        ),
    ];
  }

  static Future<List<AttendanceRow>> history({
    required DateTime from,
    required DateTime to,
    String? userId,
    List<String>? userIds,
    String? locationName,
    int limit = 400,
  }) async {
    final db = _db;
    if (db == null) return [];
    try {
      var query = db
          .from('clock_sessions')
          .select()
          .eq('app_id', BerpCloud.appId)
          .gte('clock_in', from.toUtc().toIso8601String())
          .lt('clock_in', to.toUtc().toIso8601String());
      if (userId != null && userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      } else if (userIds != null) {
        if (userIds.isEmpty) return [];
        query = query.inFilter('user_id', userIds);
      }
      if (locationName != null && locationName.isNotEmpty) {
        query = query.eq('site_name', locationName);
      }
      final res = await query
          .order('clock_in', ascending: false)
          .limit(limit);
      final directory = {for (final person in await people()) person.id: person};
      return [
        for (final row in res as List<dynamic>)
          if (row is Map)
            AttendanceRow(
              session: BerpCloud.clockFromRow(
                Map<String, dynamic>.from(row),
              ),
              person: directory['${row['user_id']}'],
            ),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<List<TeamLeave>> leaveQueue() async {
    final db = _db;
    if (db == null) return [];
    try {
      final res = await db
          .from('leave_requests')
          .select()
          .eq('app_id', BerpCloud.appId)
          .order('created_at', ascending: false)
          .limit(200);
      final directory = {for (final person in await people()) person.id: person};
      final uid = AuthService.currentUser?.id;
      return [
        for (final row in res as List<dynamic>)
          if (row is Map && '${row['user_id']}' != uid)
            TeamLeave(
              request: BerpCloud.leaveFromRow(
                Map<String, dynamic>.from(row),
              ),
              person: directory['${row['user_id']}'],
            ),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<void> decideLeave(String id, LeaveStatus status) async {
    final db = _db;
    final uid = AuthService.currentUser?.id;
    if (db == null) return;
    final payload = <String, dynamic>{
      'status': status.name,
      if (uid != null) 'decided_by': uid,
      'decided_at': DateTime.now().toUtc().toIso8601String(),
    };
    try {
      await db.from('leave_requests').update(payload).eq('id', id);
    } catch (_) {
      await db
          .from('leave_requests')
          .update({'status': status.name})
          .eq('id', id);
    }
  }

  static Future<List<AppNotice>> notifications() async {
    final db = _db;
    final uid = AuthService.currentUser?.id;
    if (db == null || uid == null) return [];
    try {
      final res = await db
          .from('notifications')
          .select()
          .eq('recipient_user_id', uid)
          .order('created_at', ascending: false)
          .limit(80);
      return [
        for (final row in res as List<dynamic>)
          if (row is Map)
            AppNotice(
              id: '${row['id']}',
              title: '${row['title'] ?? ''}',
              message: '${row['message'] ?? ''}',
              type: '${row['type'] ?? ''}',
              isRead: row['is_read'] == true,
              createdAt:
                  DateTime.tryParse('${row['created_at']}')?.toLocal() ??
                  DateTime.now(),
              referenceId: '${row['reference_id'] ?? ''}'.isEmpty
                  ? null
                  : '${row['reference_id']}',
            ),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<void> markNoticeRead(String id) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.from('notifications').update({'is_read': true}).eq('id', id);
    } catch (_) {}
  }

  static Future<void> recordLocation({
    required String sessionId,
    required double latitude,
    required double longitude,
  }) async {
    final db = _db;
    final uid = AuthService.currentUser?.id;
    if (db == null || uid == null) return;
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(sessionId)) {
      return;
    }
    try {
      await db.from('clock_session_locations').insert({
        'clock_session_id': sessionId,
        'user_id': uid,
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> _openSessions() async {
    final db = _db;
    if (db == null) return [];
    try {
      final res = await db
          .from('clock_sessions')
          .select()
          .eq('app_id', BerpCloud.appId)
          .filter('clock_out', 'is', null)
          .order('clock_in', ascending: false)
          .limit(300);
      return [
        for (final row in res as List<dynamic>)
          if (row is Map) Map<String, dynamic>.from(row),
      ];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, (double, double, DateTime)>> _latestPoints(
    List<String> sessionIds,
  ) async {
    final db = _db;
    if (db == null || sessionIds.isEmpty) return {};
    try {
      final res = await db
          .from('clock_session_locations')
          .select('clock_session_id, latitude, longitude, recorded_at')
          .inFilter('clock_session_id', sessionIds)
          .order('recorded_at', ascending: false)
          .limit(500);
      final out = <String, (double, double, DateTime)>{};
      for (final row in res as List<dynamic>) {
        if (row is! Map) continue;
        final id = '${row['clock_session_id']}';
        if (out.containsKey(id)) continue;
        final lat = (row['latitude'] as num?)?.toDouble();
        final lng = (row['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;
        out[id] = (
          lat,
          lng,
          DateTime.tryParse('${row['recorded_at']}')?.toLocal() ??
              DateTime.now(),
        );
      }
      return out;
    } catch (_) {
      return {};
    }
  }
}
