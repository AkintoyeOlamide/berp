import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/auth/staff_access.dart';
import '../../core/data/berp_cloud.dart';
import '../../core/data/berp_org.dart';
import '../../core/data/staff_store.dart';
import '../../core/location/clock_fence.dart';
import '../../core/location/shift_location.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/pattern_page.dart';
import 'notifications_screen.dart';

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
  ClockSession? _open;
  bool _busy = false;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final profile = await BerpCloud.fetchProfile();
      StaffAccess.apply(profile);
    } catch (_) {}
    final summary = await BerpOrg.summary();
    final sessions = await StaffStore.instance.sessions();
    final notices = await BerpOrg.notifications();
    ClockSession? open;
    for (final session in sessions) {
      if (session.isOpen) {
        open = session;
        break;
      }
    }
    ShiftLocationPing.follow(open?.id);
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _open = open;
      _unread = notices.where((item) => !item.isRead).length;
    });
  }

  Future<void> _toggleClock() async {
    if (_busy) return;
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
        final position = await _optionalFix();
        await StaffStore.instance.clockOut(
          latitude: position?.$1,
          longitude: position?.$2,
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

  Future<(double, double)?> _optionalFix() async {
    try {
      final sites = await BerpOrg.activeSites();
      final check = await ClockFence.checkIn(sites: sites);
      if (check.latitude == null || check.longitude == null) return null;
      return (check.latitude!, check.longitude!);
    } catch (_) {
      return null;
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'BERP',
      title: 'Dashboard',
      subtitle: StaffAccess.role.value.label.toUpperCase(),
      bottom: const AppBottomNav(currentIndex: 0),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsScreen(),
              ),
            );
          },
          icon: Badge(
            isLabelVisible: _unread > 0,
            label: Text('$_unread'),
            child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PatternGroup(
            children: [
              _stat('Total staff', '${_summary.totalStaff}'),
              _stat('Currently clocked in', '${_summary.clockedIn}'),
              _stat('Not clocked in', '${_summary.notClockedIn}'),
              _stat('Clock-ins today', '${_summary.clockInsToday}'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Not clocked in is a live count. It is not an absence mark.',
            style: PatternPage.body(size: 12, color: PatternPage.muted, height: 1.4),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: _busy ? null : _toggleClock,
              style: FilledButton.styleFrom(
                backgroundColor: _open == null
                    ? PatternPage.blue
                    : const Color(0xFFF69306),
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
                    : 'Clock out',
                style: PatternPage.panchang(size: 11, weight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

PatternListRow _stat(String title, String value) {
  return PatternListRow(
    title: title,
    subtitle: value,
    trailing: const SizedBox.shrink(),
    onTap: () {},
  );
}
