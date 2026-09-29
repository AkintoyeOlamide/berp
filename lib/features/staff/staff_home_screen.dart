import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/staff_access.dart';
import '../../core/data/berp_cloud.dart';
import '../../core/data/berp_org.dart';
import '../../core/data/clock_sites.dart';
import '../../core/data/staff_store.dart';
import '../../core/location/clock_fence.dart';
import '../../core/location/shift_location.dart';
import '../../core/notifications/push_inbox.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/premium_ui.dart';
import 'appraisals_screen.dart';
import 'leave_screen.dart';
import 'profile_screen.dart';
import 'schedule_screen.dart';
import 'updates_screen.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  List<ClockSession> _sessions = [];
  int _leaveDays = StaffStore.annualAllowance;
  List<AppraisalRecord> _appraisals = [];
  List<StaffUpdate> _updates = [];
  String? _avatarUrl;
  Timer? _tick;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  ClockSession? get _open {
    for (final session in _sessions) {
      if (session.isOpen) return session;
    }
    return null;
  }

  Future<void> _load() async {
    final results = await Future.wait<Object?>([
      StaffStore.instance.sessions(),
      StaffStore.instance.remainingAnnualDays(),
      StaffStore.instance.appraisals(),
      StaffStore.instance.updates(),
      _avatar(),
    ]);
    if (!mounted) return;
    setState(() {
      _sessions = results[0]! as List<ClockSession>;
      _leaveDays = results[1]! as int;
      _appraisals = results[2]! as List<AppraisalRecord>;
      _updates = results[3]! as List<StaffUpdate>;
      _avatarUrl = results[4] as String?;
    });
    _syncTicker();
    unawaited(PushInbox.sync());
    try {
      StaffAccess.apply(await BerpCloud.fetchProfile());
    } catch (_) {}
  }

  Future<String?> _avatar() async {
    try {
      final url = (await BerpCloud.fetchProfile())?.avatarUrl ?? '';
      return url.isEmpty ? null : url;
    } catch (_) {
      return null;
    }
  }

  void _syncTicker() {
    ShiftLocationPing.follow(_open?.id);
    if (_open == null) {
      _tick?.cancel();
      _tick = null;
      return;
    }
    _tick ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _toggleClock() async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      if (_open == null) {
        final sites = await BerpOrg.activeSites();
        final check = await ClockFence.checkIn(sites: sites);
        if (!mounted) return;
        if (!check.ok || check.site == null) {
          setState(() => _busy = false);
          _toast(check.message);
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
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(error.toString().replaceFirst('Exception: ', ''));
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    await _load();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPage(Widget page) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(premiumRoute(page));
    if (mounted) await _load();
  }

  String get _greeting {
    final hour = lagosWallClock(DateTime.now()).hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _place {
    final site = _open?.siteName?.trim();
    if (site != null && site.isNotEmpty) return site;
    if (clockSites.isEmpty) return 'Approved workplace';
    return clockSites.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final now = DateTime.now();
    final onShift = _open != null;
    final week = lagosWeekHours(_sessions, now);
    final todayIndex = lagosWallClock(now).weekday - 1;
    final today = week[todayIndex];
    final due = _appraisals.where((item) => !item.completed).length;
    final done = _appraisals.where((item) => item.completed).length;
    final next = upcomingShift(now);
    final notice = _updates.isEmpty ? null : _updates.first;
    final freshNotice = _updates.any(
      (item) => now.difference(item.at) < const Duration(hours: 24),
    );
    final leaveRatio = (_leaveDays / StaffStore.annualAllowance).clamp(0.0, 1.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: Stack(
          children: [
            RefreshIndicator(
              color: AppColors.secondary,
              backgroundColor: AppColors.surface,
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _openPage(const ProfileScreen()),
                                child: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.surfaceHigh,
                                  backgroundImage: _avatarUrl == null
                                      ? null
                                      : NetworkImage(_avatarUrl!),
                                  child: _avatarUrl == null
                                      ? const Icon(
                                          Icons.person_rounded,
                                          color: AppColors.muted,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '$_greeting, ${StaffIdentity.firstName} 👋',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _sans(size: 12, weight: FontWeight.w500),
                                ),
                              ),
                              _BellButton(
                                showDot: freshNotice,
                                onTap: () => _openPage(const UpdatesScreen()),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () => _openPage(const ProfileScreen()),
                            child: Text(
                              StaffIdentity.firstName,
                              style: _display(size: 20, weight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Staff Portal  •  ${formatLagosLongDay(now)}',
                            style: _sans(size: 11, color: AppColors.muted),
                          ),
                          const SizedBox(height: 18),
                          _ClockCard(
                            onShift: onShift,
                            busy: _busy,
                            today: today,
                            elapsed: _open?.elapsed ?? Duration.zero,
                            started: _open == null ? null : formatClock(_open!.clockIn),
                            place: _place,
                            onPressed: _toggleClock,
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'My stats',
                                  style: _sans(
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
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: AppColors.hairline),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 12,
                                      color: AppColors.muted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Today',
                                      style: _sans(
                                        size: 11,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _PersonalStatsCard(
                            onShift: onShift,
                            hoursToday: today,
                            weekTotal: week.fold<Duration>(
                              Duration.zero,
                              (sum, item) => sum + item,
                            ),
                            leaveDays: _leaveDays,
                            notices: _updates.length,
                            clocksThisWeek: _sessions
                                .where((session) {
                                  final day = lagosToday(session.clockIn);
                                  final monday = lagosWeekMonday(now);
                                  return !day.isBefore(monday) &&
                                      day.isBefore(
                                        monday.add(const Duration(days: 7)),
                                      );
                                })
                                .length,
                            onHistory: () => _openPage(const ScheduleScreen()),
                            onLeave: () => _openPage(const LeaveScreen()),
                            onNotices: () => _openPage(const UpdatesScreen()),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'At a Glance',
                            style: _sans(size: 11.5, weight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 168,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _LeaveCard(
                                    days: _leaveDays,
                                    ratio: leaveRatio,
                                    onTap: () => _openPage(const LeaveScreen()),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _AppraisalCard(
                                    due: due,
                                    done: done,
                                    total: _appraisals.length,
                                    onTap: () =>
                                        _openPage(const AppraisalsScreen()),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 176,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _NoticeCard(
                                    notice: notice,
                                    onTap: () => _openPage(const UpdatesScreen()),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ShiftCard(
                                    when: next.when,
                                    time: next.time,
                                    onTap: () => _openPage(const ScheduleScreen()),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 214,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _WeekCard(
                                    hours: week,
                                    todayIndex: todayIndex,
                                    onTap: () => _openPage(const ScheduleScreen()),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: _TeamCard(
                                    updates: _updates,
                                    onTap: () => _openPage(const UpdatesScreen()),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const AppBottomNavSpacer(extra: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNav(currentIndex: AppNavIndex.home),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalStatsCard extends StatelessWidget {
  const _PersonalStatsCard({
    required this.onShift,
    required this.hoursToday,
    required this.weekTotal,
    required this.leaveDays,
    required this.notices,
    required this.clocksThisWeek,
    required this.onHistory,
    required this.onLeave,
    required this.onNotices,
  });

  final bool onShift;
  final Duration hoursToday;
  final Duration weekTotal;
  final int leaveDays;
  final int notices;
  final int clocksThisWeek;
  final VoidCallback onHistory;
  final VoidCallback onLeave;
  final VoidCallback onNotices;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
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
                      'Your presence',
                      style: _sans(size: 14, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your clock history, leave, and notices.',
                      style: _sans(size: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (onShift ? AppColors.green : AppColors.orange)
                      .withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  onShift ? 'On shift' : 'Off shift',
                  style: _sans(
                    size: 10,
                    weight: FontWeight.w700,
                    color: onShift ? AppColors.green : AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: CustomPaint(
                  painter: _MiniRingPainter(
                    progress: onShift ? 1 : (hoursToday.inMinutes / (8 * 60)).clamp(0.0, 1.0),
                    color: onShift ? AppColors.green : AppColors.secondary,
                    label: formatHoursCompact(hoursToday),
                    sub: 'today',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    _statLink(
                      'Clock-ins this week',
                      '$clocksThisWeek',
                      onHistory,
                    ),
                    _statLink(
                      'Hours this week',
                      formatHoursCompact(weekTotal),
                      onHistory,
                    ),
                    _statLink(
                      'Leave remaining',
                      '$leaveDays d',
                      onLeave,
                    ),
                    _statLink(
                      'Notices for you',
                      '$notices',
                      onNotices,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onHistory,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'My attendance history',
                        style: _sans(size: 13, weight: FontWeight.w500),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statLink(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: _sans(size: 11.5, color: AppColors.muted),
              ),
            ),
            Text(
              value,
              style: _sans(size: 12.5, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniRingPainter extends CustomPainter {
  _MiniRingPainter({
    required this.progress,
    required this.color,
    required this.label,
    required this.sub,
  });

  final double progress;
  final Color color;
  final String label;
  final String sub;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final stroke = 8.0;
    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.08),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      (progress.clamp(0.0, 1.0)) * math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
    final text = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label\n',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          TextSpan(
            text: sub,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(covariant _MiniRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.label != label;
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.showDot, required this.onTap});

  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications_none_rounded, color: Colors.white),
              if (showDot)
                const Positioned(
                  top: 10,
                  right: 11,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(width: 7, height: 7),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClockCard extends StatelessWidget {
  const _ClockCard({
    required this.onShift,
    required this.busy,
    required this.today,
    required this.elapsed,
    required this.started,
    required this.place,
    required this.onPressed,
  });

  final bool onShift;
  final bool busy;
  final Duration today;
  final Duration elapsed;
  final String? started;
  final String place;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A3CB8),
            AppColors.brandBlue,
            AppColors.brandBlueDeep,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandBlue.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.7),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                onShift ? 'Active shift' : 'Off shift',
                style: _sans(size: 11, weight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                onShift ? 'Started at $started' : 'Today: ${formatDurationHms(today)}',
                style: _sans(size: 10.5, color: Colors.white.withValues(alpha: 0.78)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (onShift)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _Waveform(),
                const SizedBox(width: 10),
                Text(
                  formatDurationHms(elapsed),
                  style: _display(size: 22, weight: FontWeight.w700).copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(width: 10),
                const _Waveform(flip: true),
              ],
            )
          else
            Text(
              'Clock in to start your day',
              style: _display(size: 14, weight: FontWeight.w600, height: 1.2),
            ),
          const SizedBox(height: 8),
          Text(
            onShift ? 'Current shift duration' : 'Only at an approved workplace',
            style: _sans(size: 11, color: Colors.white.withValues(alpha: 0.72)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  place,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _sans(size: 11, weight: FontWeight.w500),
                ),
              ),
              if (!onShift) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.check_circle_rounded,
                  size: 15,
                  color: AppColors.secondary,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: busy ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: onShift ? AppColors.orange : AppColors.secondary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: (onShift ? AppColors.orange : AppColors.secondary)
                    .withValues(alpha: 0.45),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: onShift
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          busy ? 'Saving...' : 'Clock Out',
                          style: _display(size: 11, weight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.timer_outlined, size: 18),
                      ],
                    )
                  : Text(
                      busy ? 'Checking location...' : 'Clock In',
                      style: _display(size: 11, weight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({this.flip = false});

  final bool flip;

  @override
  Widget build(BuildContext context) {
    const bars = [7.0, 12.0, 18.0, 24.0, 16.0, 10.0];
    final heights = flip ? bars.reversed.toList() : bars;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final height in heights)
          Container(
            width: 3,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 1.4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({
    required this.days,
    required this.ratio,
    required this.onTap,
  });

  final int days;
  final double ratio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _BadgeIcon(icon: Icons.beach_access_rounded, color: AppColors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Leave', style: _sans(size: 11.5, weight: FontWeight.w600)),
              ),
              const _Chevron(),
            ],
          ),
          const Spacer(),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$days',
                            style: _display(size: 18, weight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: ' days',
                            style: _sans(size: 11, weight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'available',
                      style: _sans(size: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(
                  value: ratio,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  color: AppColors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppraisalCard extends StatelessWidget {
  const _AppraisalCard({
    required this.due,
    required this.done,
    required this.total,
    required this.onTap,
  });

  final int due;
  final int done;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;
    final headline = total == 0
        ? 'None yet'
        : due == 0
        ? 'All complete'
        : '$due review${due == 1 ? '' : 's'} due';
    return _SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _BadgeIcon(
                icon: Icons.track_changes_rounded,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Appraisals',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _sans(size: 11.5, weight: FontWeight.w600),
                ),
              ),
              const _Chevron(),
            ],
          ),
          const Spacer(),
          const SizedBox(height: 16),
          Text(
            headline,
            style: _sans(
              size: 12,
              weight: FontWeight.w600,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 10),
          Text('Completed', style: _sans(size: 11, color: AppColors.muted)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: AppColors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice, required this.onTap});

  final StaffUpdate? notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent Notices',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _sans(size: 11.5, weight: FontWeight.w600),
                ),
              ),
              const _Chevron(),
            ],
          ),
          const SizedBox(height: 14),
          if (notice == null)
            Text(
              'No notices yet.',
              style: _sans(size: 12, color: AppColors.muted),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BadgeIcon(
                  icon: Icons.campaign_rounded,
                  color: AppColors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notice!.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _sans(size: 11.5, weight: FontWeight.w600, height: 1.25),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notice!.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _sans(size: 10.5, color: AppColors.muted, height: 1.35),
            ),
            const SizedBox(height: 10),
            Text(
              formatTimeAgo(notice!.at),
              style: _sans(size: 11, color: AppColors.mutedDark),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({
    required this.when,
    required this.time,
    required this.onTap,
  });

  final String when;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Shifts', style: _sans(size: 11.5, weight: FontWeight.w600)),
              ),
              const _Chevron(),
            ],
          ),
          const SizedBox(height: 14),
          const _BadgeIcon(icon: Icons.schedule_rounded, color: AppColors.secondary),
          const Spacer(),
          const SizedBox(height: 12),
          Text(
            'Next: $when',
            style: _sans(size: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 2),
          Text(time, style: _display(size: 16, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.hours,
    required this.todayIndex,
    required this.onTap,
  });

  final List<Duration> hours;
  final int todayIndex;
  final VoidCallback onTap;

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    var maxMinutes = 8 * 60;
    for (final day in hours) {
      if (day.inMinutes > maxMinutes) maxMinutes = day.inMinutes;
    }
    return _SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Weekly Shift Timeline',
                  maxLines: 2,
                  style: _sans(size: 11.5, weight: FontWeight.w600, height: 1.2),
                ),
              ),
              const _Chevron(),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 118,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: _WeekBar(
                      letter: _letters[i],
                      hours: hours[i],
                      today: i == todayIndex,
                      maxMinutes: maxMinutes,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekBar extends StatelessWidget {
  const _WeekBar({
    required this.letter,
    required this.hours,
    required this.today,
    required this.maxMinutes,
  });

  final String letter;
  final Duration hours;
  final bool today;
  final int maxMinutes;

  @override
  Widget build(BuildContext context) {
    final fraction = maxMinutes == 0 ? 0.0 : hours.inMinutes / maxMinutes;
    final barHeight = hours.inMinutes == 0 ? 6.0 : (10 + fraction * 62).clamp(10.0, 72.0);
    final color = hours.inMinutes == 0
        ? AppColors.surfaceHigh
        : today || hours.inHours >= 8
        ? AppColors.green
        : AppColors.secondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            formatHoursCompact(hours),
            maxLines: 1,
            style: _sans(
              size: 8,
              weight: FontWeight.w500,
              color: today ? Colors.white : AppColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            height: barHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            letter,
            style: _sans(
              size: 10,
              weight: today ? FontWeight.w600 : FontWeight.w500,
              color: today ? Colors.white : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.updates, required this.onTap});

  final List<StaffUpdate> updates;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final people = updates.take(2).toList();
    return _SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 14, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Team Activity',
                  maxLines: 2,
                  style: _sans(size: 11.5, weight: FontWeight.w600, height: 1.2),
                ),
              ),
              const _Chevron(),
            ],
          ),
          const SizedBox(height: 12),
          if (people.isEmpty)
            Text(
              'No team posts yet.',
              style: _sans(size: 10.5, color: AppColors.muted, height: 1.35),
            )
          else
            for (var i = 0; i < people.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _TeamRow(update: people[i]),
            ],
        ],
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({required this.update});

  final StaffUpdate update;

  @override
  Widget build(BuildContext context) {
    final name = update.author.trim();
    final first = name.split(RegExp(r'\s+')).first;
    final initial = first.isEmpty ? '?' : first[0].toUpperCase();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: AppColors.surfaceHigh,
          child: Text(
            initial,
            style: _sans(size: 10, weight: FontWeight.w600, color: AppColors.secondary),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                first.isEmpty ? 'Team' : first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _sans(size: 11.5, weight: FontWeight.w600),
              ),
              Text(
                update.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _sans(size: 10, color: AppColors.muted),
              ),
              Text(
                formatTimeAgo(update.at),
                style: _sans(size: 9.5, color: AppColors.mutedDark),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.fromLTRB(14, 14, 12, 14),
  });

  final Widget child;
  final VoidCallback onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Material(
      color: AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 18);
  }
}

TextStyle _display({
  required double size,
  FontWeight weight = FontWeight.w600,
  Color color = Colors.white,
  double height = 1.05,
}) {
  return TextStyle(
    fontFamily: 'Panchang',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}

TextStyle _sans({
  required double size,
  FontWeight weight = FontWeight.w400,
  Color color = Colors.white,
  double height = 1.25,
}) {
  return GoogleFonts.poppins(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}
