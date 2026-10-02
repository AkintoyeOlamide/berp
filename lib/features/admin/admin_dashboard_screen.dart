import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/auth/staff_access.dart';
import '../../core/data/berp_cloud.dart';
import '../../core/data/berp_org.dart';
import '../../core/data/staff_store.dart';
import '../../core/location/clock_fence.dart';
import '../../core/location/shift_location.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/pattern_page.dart';
import '../../core/widgets/premium_ui.dart';
import '../settings/settings_screen.dart';
import '../staff/leave_screen.dart';
import '../staff/tickets_screen.dart';
import '../staff/updates_screen.dart';
import 'attendance_history_screen.dart';
import 'live_attendance_screen.dart';
import 'locations_screen.dart';
import 'notifications_screen.dart';
import 'staff_directory_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AttendanceSummary _summary = const AttendanceSummary(
    totalStaff: 0,
    clockedIn: 0,
    clockInsToday: 0,
  );
  List<LiveShift> _live = [];
  List<TeamLeave> _pendingLeave = [];
  List<SupportTicket> _openTickets = [];
  List<int> _weekCounts = List<int>.filled(7, 0);
  ClockSession? _open;
  bool _busy = false;
  bool _loading = true;
  int _unread = 0;
  String _name = StaffIdentity.name;

  bool get _super => StaffAccess.role.value.isSuperAdmin;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final profile = await BerpCloud.fetchProfile();
      StaffAccess.apply(profile);
      if (profile != null && profile.fullName.trim().isNotEmpty) {
        _name = profile.fullName.trim();
      }
    } catch (_) {}
    final results = await Future.wait([
      BerpOrg.summary(),
      BerpOrg.liveShifts(),
      BerpOrg.leaveQueue(),
      StaffStore.instance.sessions(),
      BerpOrg.notifications(),
      BerpOrg.weekClockInCounts(),
      StaffStore.instance.tickets(),
    ]);
    if (!mounted) return;
    final sessions = results[3] as List<ClockSession>;
    ClockSession? open;
    for (final session in sessions) {
      if (session.isOpen) {
        open = session;
        break;
      }
    }
    ShiftLocationPing.follow(open?.id);
    final leave = results[2] as List<TeamLeave>;
    final tickets = results[6] as List<SupportTicket>;
    setState(() {
      _summary = results[0] as AttendanceSummary;
      _live = results[1] as List<LiveShift>;
      _pendingLeave = leave
          .where((item) => item.request.status == LeaveStatus.pending)
          .take(5)
          .toList();
      _openTickets = tickets
          .where((item) => item.status != TicketStatus.done)
          .take(5)
          .toList();
      _open = open;
      _unread = (results[4] as List<AppNotice>)
          .where((item) => !item.isRead)
          .length;
      _weekCounts = results[5] as List<int>;
      _loading = false;
    });
  }

  Future<void> _toggleClock() async {
    if (_busy) return;
    if (StaffAccess.suspended.value) {
      _toast('This account is suspended.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_open == null) {
        final sites = await BerpOrg.activeSites();
        final check = await ClockFence.checkIn(sites: sites);
        if (!check.ok || check.site == null) {
          if (mounted) _toast(check.message);
          return;
        }
        await StaffStore.instance.clockIn(
          siteId: check.site!.id,
          siteName: check.site!.name,
          latitude: check.latitude,
          longitude: check.longitude,
        );
      } else {
        double? latitude;
        double? longitude;
        try {
          final sites = await BerpOrg.activeSites();
          final check = await ClockFence.checkIn(sites: sites);
          latitude = check.latitude;
          longitude = check.longitude;
        } catch (_) {}
        await StaffStore.instance.clockOut(
          latitude: latitude,
          longitude: longitude,
        );
        ShiftLocationPing.stop();
      }
    } catch (error) {
      if (mounted) {
        _toast(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load();
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPage(Widget page) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(premiumRoute(page));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _greeting;
    return PatternPage(
      breadcrumb: _super ? 'SUPER ADMIN' : 'ADMIN',
      title: _super ? 'Control centre' : 'Admin dashboard',
      subtitle: '${StaffAccess.role.value.label.toUpperCase()}  ·  LAGOS',
      bottom: const AppBottomNav(currentIndex: 0),
      scrollBody: true,
      actions: [
        IconButton(
          onPressed: () => _openPage(const NotificationsScreen()),
          icon: Badge(
            isLabelVisible: _unread > 0,
            label: Text('$_unread'),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
            ),
          ),
        ),
      ],
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroBanner(
                  greeting: greeting,
                  name: _name,
                  superAdmin: _super,
                  clockedIn: _summary.clockedIn,
                  total: _summary.totalStaff,
                  onTap: () => _openPage(const LiveAttendanceScreen()),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Organisation stats',
                        style: PatternPage.body(
                          size: 13,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: PatternPage.row,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: PatternPage.divider),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: PatternPage.muted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Today',
                            style: PatternPage.body(
                              size: 11,
                              color: PatternPage.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _OrganisationStats(
                  summary: _summary,
                  clockedIds: {for (final shift in _live) shift.userId},
                  onOpen: _openPage,
                ),
                const SizedBox(height: 12),
                _ChartCard(
                  title: 'Clock-ins · last 7 days',
                  onTap: () => _openPage(const AttendanceHistoryScreen()),
                  child: SizedBox(
                    height: 110,
                    child: CustomPaint(
                      painter: _LineChartPainter(
                        values: _weekCounts,
                        lineColor: AppColors.orange,
                        fillColor: AppColors.orange.withValues(alpha: 0.18),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _MetricGrid(
                  summary: _summary,
                  superAdmin: _super,
                  clockedIds: {for (final shift in _live) shift.userId},
                  onOpen: _openPage,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap any card for the full list. Not clocked in is a live count, not an absence mark.',
                  style: PatternPage.body(
                    size: 11.5,
                    color: PatternPage.muted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                const PatternSectionLabel('Operations'),
                const SizedBox(height: 10),
                _QuickActions(
                  superAdmin: _super,
                  onOpen: _openPage,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: PatternSectionLabel(
                        'Open tickets  ·  ${_openTickets.length}',
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openPage(const TicketsScreen()),
                      child: Text(
                        'View all',
                        style: PatternPage.body(
                          size: 12,
                          color: PatternPage.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_openTickets.isEmpty)
                  Text(
                    'No open IT or facility tickets.',
                    style: PatternPage.body(
                      size: 13,
                      color: PatternPage.muted,
                    ),
                  )
                else
                  for (final ticket in _openTickets) ...[
                    _TicketDashTile(
                      ticket: ticket,
                      onTap: () => _openPage(const TicketsScreen()),
                    ),
                    const SizedBox(height: 8),
                  ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: PatternSectionLabel(
                        'Live now  ·  ${_live.length}',
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openPage(const LiveAttendanceScreen()),
                      child: Text(
                        'See all',
                        style: PatternPage.body(
                          size: 12,
                          color: PatternPage.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_live.isEmpty)
                  Text(
                    'Nobody is clocked in right now.',
                    style: PatternPage.body(
                      size: 13,
                      color: PatternPage.muted,
                    ),
                  )
                else
                  for (final shift in _live.take(4))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _LiveTile(
                        shift: shift,
                        onTap: () => _openPage(const LiveAttendanceScreen()),
                      ),
                    ),
                if (_pendingLeave.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: PatternSectionLabel('Pending leave'),
                      ),
                      TextButton(
                        onPressed: () => _openPage(const LeaveScreen()),
                        child: Text(
                          'Review',
                          style: PatternPage.body(
                            size: 12,
                            color: PatternPage.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  PatternGroup(
                    children: [
                      for (final item in _pendingLeave)
                        PatternListRow(
                          title: item.person?.name.isNotEmpty == true
                              ? item.person!.name
                              : 'Staff',
                          subtitle:
                              '${item.request.kind.label}  ·  ${formatDay(item.request.start)} – ${formatDay(item.request.end)}',
                          onTap: () => _openPage(const LeaveScreen()),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                const PatternSectionLabel('Your shift'),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _busy ? null : _toggleClock,
                    style: FilledButton.styleFrom(
                      backgroundColor: _open == null
                          ? AppColors.secondary
                          : AppColors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _busy
                          ? 'Please wait'
                          : _open == null
                          ? 'Clock in'
                          : 'Clock out  ·  ${formatDurationHms(_open!.elapsed)}',
                      style: PatternPage.panchang(
                        size: 11,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (_super) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Use Settings from More to manage account options.',
                    style: PatternPage.body(
                      size: 11.5,
                      color: PatternPage.muted,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  String get _greeting {
    final hour = lagosWallClock(DateTime.now()).hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.greeting,
    required this.name,
    required this.superAdmin,
    required this.clockedIn,
    required this.total,
    required this.onTap,
  });

  final String greeting;
  final String name;
  final bool superAdmin;
  final int clockedIn;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: superAdmin
                  ? const [
                      Color(0xFF1C1C1E),
                      Color(0xFF17171A),
                      Color(0xFF121214),
                    ]
                  : const [
                      Color(0xFF1A1A1C),
                      Color(0xFF141416),
                      Color(0xFF101012),
                    ],
            ),
            border: Border.all(color: const Color(0xFF2C2C2E)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  superAdmin ? 'SUPER ADMIN ACCESS' : 'ADMIN ACCESS',
                  style: PatternPage.panchang(size: 9, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$greeting,',
                style: PatternPage.body(size: 13, color: Colors.white70),
              ),
              Text(
                name,
                style: PatternPage.panchang(size: 22, weight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                superAdmin
                    ? 'Full system control: staff roles, live attendance, history, locations, and suspensions.'
                    : 'Organisation staff, live attendance, history, locations, and updates.',
                style: PatternPage.body(
                  size: 12.5,
                  color: Colors.white.withValues(alpha: 0.78),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$clockedIn of $total staff currently clocked in',
                      style: PatternPage.body(
                        size: 12,
                        weight: FontWeight.w600,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                  Text(
                    'Open live',
                    style: PatternPage.body(
                      size: 11,
                      weight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrganisationStats extends StatelessWidget {
  const _OrganisationStats({
    required this.summary,
    required this.clockedIds,
    required this.onOpen,
  });

  final AttendanceSummary summary;
  final Set<String> clockedIds;
  final Future<void> Function(Widget page) onOpen;

  @override
  Widget build(BuildContext context) {
    final total = summary.totalStaff <= 0 ? 1 : summary.totalStaff;
    final presentPct = (summary.clockedIn / total * 100);
    final viewerIsSuper = StaffAccess.role.value.isSuperAdmin;
    final roles = <(String, String, IconData, Color, int, Widget)>[
      if (viewerIsSuper)
        (
          'Super Admin',
          'super_admin',
          Icons.workspace_premium_rounded,
          AppColors.orange,
          summary.superAdmins,
          const StaffDirectoryScreen(
            title: 'Super Admins',
            roleFilter: 'super_admin',
            hideBottomNav: true,
          ),
        ),
      (
        'Admin',
        'admin',
        Icons.verified_user_outlined,
        AppColors.green,
        summary.admins,
        const StaffDirectoryScreen(
          title: 'Admins',
          roleFilter: 'admin',
          hideBottomNav: true,
        ),
      ),
      (
        'Operations',
        'operations',
        Icons.groups_rounded,
        AppColors.orange,
        summary.operations,
        const StaffDirectoryScreen(
          title: 'Operations',
          roleFilter: 'operations',
          hideBottomNav: true,
        ),
      ),
      (
        'Staff',
        'staff',
        Icons.person_outline_rounded,
        const Color(0xFF8B7CF6),
        summary.staffCount,
        const StaffDirectoryScreen(
          title: 'Staff',
          roleFilter: 'staff',
          hideBottomNav: true,
        ),
      ),
      (
        'Others',
        'others',
        Icons.more_horiz_rounded,
        PatternPage.muted,
        summary.others,
        const StaffDirectoryScreen(
          title: 'Others',
          roleFilter: 'others',
          hideBottomNav: true,
        ),
      ),
    ];

    return Column(
      children: [
        _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Presence now',
                          style: PatternPage.body(
                            size: 14,
                            weight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Live staff presence across all locations.',
                          style: PatternPage.body(
                            size: 11,
                            color: PatternPage.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Live',
                      style: PatternPage.body(
                        size: 10,
                        weight: FontWeight.w700,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CustomPaint(
                      painter: _DonutPainter(
                        slices: [
                          (summary.clockedIn / total, AppColors.green),
                          (summary.notClockedIn / total, Colors.transparent),
                        ],
                        trackColor: Colors.white.withValues(alpha: 0.08),
                        centerLabel: '${presentPct.round()}%',
                        centerSub: 'Present now',
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      children: [
                        _presenceRow(
                          label: 'Clocked in',
                          color: AppColors.green,
                          count: summary.clockedIn,
                          pct: summary.pct(summary.clockedIn),
                          onTap: () => onOpen(const LiveAttendanceScreen()),
                        ),
                        const SizedBox(height: 10),
                        _presenceRow(
                          label: 'Not in',
                          color: AppColors.orange,
                          count: summary.notClockedIn,
                          pct: summary.pct(summary.notClockedIn),
                          onTap: () => onOpen(
                            StaffDirectoryScreen(
                              title: 'Not clocked in',
                              excludeUserIds: clockedIds,
                              hideBottomNav: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Material(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => onOpen(
                    const StaffDirectoryScreen(hideBottomNav: true),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.groups_outlined,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Total Staff',
                            style: PatternPage.body(
                              size: 13,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          '${summary.totalStaff}',
                          style: PatternPage.panchang(
                            size: 16,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: PatternPage.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Roles',
                          style: PatternPage.body(
                            size: 14,
                            weight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total staff by role.',
                          style: PatternPage.body(
                            size: 11,
                            color: PatternPage.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => onOpen(
                      const StaffDirectoryScreen(hideBottomNav: true),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'View all >',
                      style: PatternPage.body(
                        size: 12,
                        color: AppColors.secondary,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final role in roles)
                if (role.$5 > 0 ||
                    role.$2 == 'staff' ||
                    role.$2 == 'admin' ||
                    (viewerIsSuper && role.$2 == 'super_admin'))
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onOpen(role.$6),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: role.$4.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(role.$3, size: 16, color: role.$4),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                role.$1,
                                style: PatternPage.body(
                                  size: 13,
                                  weight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${role.$5}',
                              style: PatternPage.body(
                                size: 13,
                                weight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 44,
                              child: Text(
                                '${(summary.pct(role.$5) * 100).toStringAsFixed(1)}%',
                                textAlign: TextAlign.right,
                                style: PatternPage.body(
                                  size: 11,
                                  color: PatternPage.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: PatternPage.row,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatternPage.divider),
      ),
      child: child,
    );
  }

  Widget _presenceRow({
    required String label,
    required Color color,
    required int count,
    required double pct,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: PatternPage.body(size: 12, color: PatternPage.muted),
                ),
              ),
              Text(
                '$count',
                style: PatternPage.body(size: 13, weight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Text(
                '${(pct * 100).round()}%',
                style: PatternPage.body(size: 11, color: PatternPage.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    required this.onTap,
  });

  final String title;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PatternPage.row,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: PatternPage.body(size: 11, color: PatternPage.muted),
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.summary,
    required this.superAdmin,
    required this.clockedIds,
    required this.onOpen,
  });

  final AttendanceSummary summary;
  final bool superAdmin;
  final Set<String> clockedIds;
  final Future<void> Function(Widget page) onOpen;

  @override
  Widget build(BuildContext context) {
    final tiles = <(String, String, Color, Widget)>[
      (
        'Total staff',
        '${summary.totalStaff}',
        AppColors.secondary,
        const StaffDirectoryScreen(hideBottomNav: true),
      ),
      (
        'Clocked in',
        '${summary.clockedIn}',
        AppColors.green,
        const LiveAttendanceScreen(),
      ),
      (
        'Not clocked in',
        '${summary.notClockedIn}',
        AppColors.orange,
        StaffDirectoryScreen(
          title: 'Not clocked in',
          excludeUserIds: clockedIds,
          hideBottomNav: true,
        ),
      ),
      (
        'Clock-ins today',
        '${summary.clockInsToday}',
        AppColors.brandBlueSoft,
        const AttendanceHistoryScreen(),
      ),
      if (superAdmin) ...[
        (
          'Operations',
          '${summary.managers}',
          AppColors.orange,
          const StaffDirectoryScreen(
            title: 'Operations',
            roleFilter: 'operations',
            hideBottomNav: true,
          ),
        ),
        (
          'Admins',
          '${summary.admins}',
          AppColors.brandBlue,
          const StaffDirectoryScreen(
            title: 'Admins',
            roleFilter: 'admin',
            hideBottomNav: true,
          ),
        ),
        (
          'Super Admins',
          '${summary.superAdmins}',
          AppColors.secondary,
          const StaffDirectoryScreen(
            title: 'Super Admins',
            roleFilter: 'super_admin',
            hideBottomNav: true,
          ),
        ),
        (
          'Suspended',
          '${summary.suspended}',
          const Color(0xFFE25555),
          const StaffDirectoryScreen(
            title: 'Suspended',
            suspendedOnly: true,
            hideBottomNav: true,
          ),
        ),
        (
          'Pending leave',
          '${summary.pendingLeave}',
          AppColors.orange,
          const LeaveScreen(),
        ),
        (
          'Active sites',
          '${summary.activeLocations}',
          AppColors.green,
          const LocationsScreen(),
        ),
      ] else ...[
        (
          'Pending leave',
          '${summary.pendingLeave}',
          AppColors.orange,
          const LeaveScreen(),
        ),
        (
          'Active sites',
          '${summary.activeLocations}',
          AppColors.green,
          const LocationsScreen(),
        ),
      ],
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tile in tiles)
          SizedBox(
            width: (MediaQuery.sizeOf(context).width - 52) / 2,
            child: Material(
              color: PatternPage.row,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onOpen(tile.$4);
                },
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tile.$1,
                              style: PatternPage.body(
                                size: 11,
                                color: PatternPage.muted,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tile.$2,
                        style: PatternPage.panchang(
                          size: 22,
                          weight: FontWeight.w700,
                          color: tile.$3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View details',
                        style: PatternPage.body(
                          size: 10,
                          color: tile.$3.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.superAdmin, required this.onOpen});

  final bool superAdmin;
  final Future<void> Function(Widget page) onOpen;

  @override
  Widget build(BuildContext context) {
    final actions = <(String, IconData, Widget)>[
      ('Staff', Icons.groups_rounded, const StaffDirectoryScreen()),
      ('Live', Icons.my_location_rounded, const LiveAttendanceScreen()),
      ('History', Icons.history_rounded, const AttendanceHistoryScreen()),
      ('Leave', Icons.edit_note_rounded, const LeaveScreen()),
      ('Locations', Icons.place_outlined, const LocationsScreen()),
      ('Feed', Icons.dynamic_feed_outlined, const UpdatesScreen()),
      ('Tickets', Icons.confirmation_number_outlined, const TicketsScreen()),
      ('Alerts', Icons.notifications_outlined, const NotificationsScreen()),
      if (superAdmin)
        ('Settings', Icons.settings_outlined, const SettingsScreen()),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final action in actions)
          InkWell(
            onTap: () => onOpen(action.$3),
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              width: (MediaQuery.sizeOf(context).width - 52) / 2,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: PatternPage.row,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: PatternPage.divider),
              ),
              child: Row(
                children: [
                  Icon(action.$2, color: AppColors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      action.$1,
                      style: PatternPage.body(
                        size: 13,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TicketDashTile extends StatelessWidget {
  const _TicketDashTile({required this.ticket, required this.onTap});

  final SupportTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (ticket.status) {
      TicketStatus.pending => const Color(0xFFF97316),
      TicketStatus.inProgress => const Color(0xFF3B82F6),
      TicketStatus.done => const Color(0xFF22C55E),
    };
    return Material(
      color: PatternPage.row,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: PatternPage.blue.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  ticket.category == TicketCategory.it
                      ? Icons.computer_rounded
                      : Icons.apartment_rounded,
                  color: PatternPage.blue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PatternPage.body(
                        size: 13,
                        weight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      [
                        ticket.category.label,
                        if (ticket.reporterName.isNotEmpty) ticket.reporterName,
                        ticket.status.label,
                      ].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PatternPage.body(
                        size: 11,
                        color: PatternPage.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveTile extends StatelessWidget {
  const _LiveTile({required this.shift, required this.onTap});

  final LiveShift shift;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PatternPage.row,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.brandBlue,
                backgroundImage: shift.photoUrl.isEmpty
                    ? null
                    : NetworkImage(shift.photoUrl),
                child: shift.photoUrl.isEmpty
                    ? Text(
                        shift.name.isEmpty ? '?' : shift.name[0].toUpperCase(),
                        style: PatternPage.body(
                          size: 13,
                          weight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift.name,
                      style: PatternPage.body(
                        size: 13,
                        weight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      [
                        if (shift.locationName.isNotEmpty) shift.locationName,
                        formatClock(shift.clockIn),
                        formatDurationHms(
                          DateTime.now().difference(shift.clockIn),
                        ),
                      ].join('  ·  '),
                      style: PatternPage.body(
                        size: 11,
                        color: PatternPage.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: PatternPage.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.centerLabel,
    required this.centerSub,
    this.trackColor,
  });

  final List<(double, Color)> slices;
  final String centerLabel;
  final String centerSub;
  final Color? trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final stroke = radius * 0.22;
    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2);
    final track = trackColor ?? Colors.white12;
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track
        ..strokeCap = StrokeCap.butt,
    );
    var start = -math.pi / 2;
    for (final slice in slices) {
      if (slice.$1 <= 0 || slice.$2 == Colors.transparent) {
        start += (slice.$1.clamp(0.0, 1.0)) * math.pi * 2;
        continue;
      }
      final sweep = (slice.$1.clamp(0.0, 1.0)) * math.pi * 2;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = slice.$2
          ..strokeCap = StrokeCap.round,
      );
      start += sweep;
    }
    final label = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$centerLabel\n',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.05,
            ),
          ),
          TextSpan(
            text: centerSub,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: radius * 1.4);
    label.paint(
      canvas,
      center - Offset(label.width / 2, label.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.centerLabel != centerLabel ||
        oldDelegate.slices.length != slices.length;
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
  });

  final List<int> values;
  final Color lineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final data = values.isEmpty ? List<int>.filled(7, 0) : values;
    final maxV = data.fold<int>(0, (a, b) => a > b ? a : b);
    final peak = maxV <= 0 ? 1 : maxV.toDouble();
    final pad = 10.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    final step = data.length <= 1 ? w : w / (data.length - 1);

    final points = <Offset>[
      for (var i = 0; i < data.length; i++)
        Offset(
          pad + step * i,
          pad + h - (data[i] / peak) * h,
        ),
    ];

    // Grid lines
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = pad + h * i / 2;
      canvas.drawLine(Offset(pad, y), Offset(size.width - pad, y), grid);
    }

    if (points.length >= 2) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      final fill = Path.from(path)
        ..lineTo(points.last.dx, size.height - pad)
        ..lineTo(points.first.dx, size.height - pad)
        ..close();
      canvas.drawPath(fill, Paint()..color = fillColor);
      canvas.drawPath(
        path,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 3.2, Paint()..color = lineColor);
      canvas.drawCircle(points[i], 1.6, Paint()..color = Colors.white);
      final label = TextPainter(
        text: TextSpan(
          text: '${data[i]}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        points[i] - Offset(label.width / 2, label.height + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
