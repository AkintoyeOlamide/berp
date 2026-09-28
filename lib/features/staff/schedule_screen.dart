import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/staff_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_bottom_nav.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<ClockSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await StaffStore.instance.sessions();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final now = DateTime.now();
    final week = lagosWeekHours(_sessions, now);
    final monday = lagosWeekMonday(now);
    final todayIndex = lagosWallClock(now).weekday - 1;
    final next = upcomingShift(now);
    ClockSession? open;
    for (final session in _sessions) {
      if (session.isOpen) {
        open = session;
        break;
      }
    }

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
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(20, top + 18, 20, 0),
                children: [
                  Text(
                    'Schedule',
                    style: _display(size: 28, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lagos office  ·  Mon–Fri  9:00',
                    style: _sans(size: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 18),
                  if (open != null) ...[
                    _InfoCard(
                      icon: Icons.timer_outlined,
                      iconColor: AppColors.green,
                      title: 'Active shift',
                      body: open.siteName == null
                          ? 'Started ${formatClock(open.clockIn)}'
                          : '${open.siteName}  ·  started ${formatClock(open.clockIn)}',
                    ),
                    const SizedBox(height: 10),
                  ],
                  _InfoCard(
                    icon: Icons.schedule_rounded,
                    iconColor: AppColors.secondary,
                    title: 'Next: ${next.when}',
                    body: '${next.time}  ·  clock in at an approved site',
                  ),
                  const SizedBox(height: 22),
                  Text('This week', style: _sans(size: 16, weight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  if (_loading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < 7; i++)
                      _DayRow(
                        label: weekdayName(monday.add(Duration(days: i))),
                        date: '${monday.add(Duration(days: i)).day}',
                        hours: week[i],
                        today: i == todayIndex,
                        weekend: i >= 5,
                      ),
                  const SizedBox(height: 18),
                  Text(
                    'My attendance',
                    style: _sans(size: 16, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  if (!_loading && _sessions.isEmpty)
                    Text(
                      'No clock-ins yet. Your shifts will show here after you clock in.',
                      style: _sans(size: 13, color: AppColors.muted, height: 1.4),
                    )
                  else
                    for (final session in _sessions.take(40))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _InfoCard(
                          icon: session.isOpen
                              ? Icons.play_circle_outline_rounded
                              : Icons.check_circle_outline_rounded,
                          iconColor: session.isOpen
                              ? AppColors.green
                              : AppColors.secondary,
                          title: session.siteName ?? 'Shift',
                          body:
                              '${formatLagosLongDay(session.clockIn)}  ·  ${formatClock(session.clockIn)} – ${session.clockOut == null ? 'Now' : formatClock(session.clockOut!)}  ·  ${formatHoursCompact(session.elapsed)}${session.clockInLat == null ? '' : '  ·  ${session.clockInLat!.toStringAsFixed(5)}, ${session.clockInLng!.toStringAsFixed(5)}'}',
                        ),
                      ),
                  const AppBottomNavSpacer(extra: 12),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNav(currentIndex: AppNavIndex.schedule),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.label,
    required this.date,
    required this.hours,
    required this.today,
    required this.weekend,
  });

  final String label;
  final String date;
  final Duration hours;
  final bool today;
  final bool weekend;

  @override
  Widget build(BuildContext context) {
    final worked = hours.inMinutes > 0;
    final color = today
        ? AppColors.green
        : worked
        ? AppColors.secondary
        : AppColors.mutedDark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: today ? AppColors.surfaceHigh : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: today
                ? AppColors.green.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 108,
              child: Text(
                weekend ? '$label  ·  off' : label,
                style: _sans(
                  size: 13,
                  weight: today ? FontWeight.w600 : FontWeight.w500,
                  color: weekend && !worked ? AppColors.mutedDark : Colors.white,
                ),
              ),
            ),
            Text(date, style: _sans(size: 12, color: AppColors.muted)),
            const Spacer(),
            Text(
              formatHoursCompact(hours),
              style: _display(size: 14, weight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _sans(size: 13, weight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: _sans(size: 11.5, color: AppColors.muted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle _display({
  required double size,
  FontWeight weight = FontWeight.w600,
  Color color = Colors.white,
}) {
  return TextStyle(
    fontFamily: 'Panchang',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.1,
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
