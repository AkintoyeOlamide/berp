import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/berp_cloud.dart';
import '../../core/data/staff_store.dart';
import '../../core/location/clock_fence.dart';
import '../../core/notifications/push_inbox.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/premium_ui.dart';
import 'appraisals_screen.dart';
import 'leave_screen.dart';
import 'profile_screen.dart';
import 'updates_screen.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  static const _bg = Color(0xFF0A0A0A);
  static const _card = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF8E8E93);
  static const _blue = Color(0xFF3044C4);
  static const _green = Color(0xFF75BD42);

  ClockSession? _open;
  Duration _todayClosed = Duration.zero;
  int _leaveDays = StaffStore.annualAllowance;
  Timer? _tick;
  bool _busy = false;
  String? _avatarUrl;

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

  Future<void> _load() async {
    final open = await StaffStore.instance.openSession();
    final today = await StaffStore.instance.hoursToday();
    final leave = await StaffStore.instance.remainingAnnualDays();
    String? avatar;
    try {
      avatar = (await BerpCloud.fetchProfile())?.avatarUrl;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _open = open;
      final closed = today - (open?.elapsed ?? Duration.zero);
      _todayClosed = closed.isNegative ? Duration.zero : closed;
      _leaveDays = leave;
      _avatarUrl = (avatar ?? '').isEmpty ? null : avatar;
    });
    _tick?.cancel();
    if (open != null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
      });
    }
    unawaited(PushInbox.sync());
  }

  Future<void> _toggleClock() async {
    if (_busy) return;
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    try {
      if (_open == null) {
        final check = await ClockFence.checkIn();
        if (!mounted) return;
        if (!check.ok || check.site == null) {
          setState(() => _busy = false);
          _toast(check.message);
          return;
        }
        await StaffStore.instance.clockIn(
          siteId: check.site!.id,
          siteName: check.site!.name,
        );
      } else {
        await StaffStore.instance.clockOut();
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPage(Widget page) async {
    HapticFeedback.selectionClick();
    await Navigator.of(context).push(premiumRoute(page));
    if (mounted) await _load();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  TextStyle _panchang({
    required double size,
    FontWeight weight = FontWeight.w600,
    Color color = Colors.white,
    double height = 1.1,
  }) {
    return TextStyle(
      fontFamily: 'Panchang',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  TextStyle _body({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = Colors.white,
    double height = 1.3,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final onShift = _open != null;
    final elapsed = _open?.elapsed ?? Duration.zero;
    final today = _todayClosed + elapsed;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, top + 18, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting, style: _body(size: 13, color: _muted)),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _openPage(const ProfileScreen()),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: _card,
                                backgroundImage: _avatarUrl == null
                                    ? null
                                    : NetworkImage(_avatarUrl!),
                                child: _avatarUrl == null
                                    ? const Icon(
                                        Icons.person_rounded,
                                        color: _muted,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  StaffIdentity.firstName,
                                  style: _panchang(
                                    size: 28,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Staff portal  ·  ${formatDay(DateTime.now())}',
                          style: _body(size: 12, color: _muted),
                        ),
                        const SizedBox(height: 22),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: onShift ? _green : _muted,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          onShift ? 'On shift' : 'Off shift',
                                          style: _body(
                                            size: 11,
                                            weight: FontWeight.w500,
                                            color: onShift ? _green : _muted,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'Today ${formatDurationHms(today)}',
                                            overflow: TextOverflow.ellipsis,
                                            style: _body(
                                              size: 11,
                                              color: _muted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      onShift
                                          ? formatDurationHms(elapsed)
                                          : 'Clock in to start your day',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          _panchang(
                                            size: onShift ? 18 : 12.5,
                                            weight: FontWeight.w700,
                                          ).copyWith(
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                            letterSpacing: onShift ? 0.6 : 0,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      onShift
                                          ? _open!.siteName == null
                                                ? 'Since ${formatClock(_open!.clockIn)}'
                                                : 'At ${_open!.siteName}  ·  since ${formatClock(_open!.clockIn)}'
                                          : 'Only at approved workplaces',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _body(size: 11, color: _muted),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 34,
                                child: FilledButton(
                                  onPressed: _busy ? null : _toggleClock,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: onShift
                                        ? const Color(0xFFFF453A)
                                        : _blue,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: _blue.withValues(
                                      alpha: 0.4,
                                    ),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    _busy && !onShift
                                        ? 'Checking…'
                                        : onShift
                                        ? 'Clock out'
                                        : 'Clock in',
                                    style: _panchang(
                                      size: 11,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text('Your desk', style: _panchang(size: 13)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _DeskTile(
                                title: 'Leave',
                                subtitle: '$_leaveDays days left',
                                icon: Icons.beach_access_outlined,
                                accent: _green,
                                panchang: _panchang,
                                body: _body,
                                onTap: () => _openPage(const LeaveScreen()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _DeskTile(
                                title: 'Appraisals',
                                subtitle: 'Reviews & goals',
                                icon: Icons.workspace_premium_outlined,
                                accent: _blue,
                                panchang: _panchang,
                                body: _body,
                                onTap: () =>
                                    _openPage(const AppraisalsScreen()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _DeskTile(
                          title: 'Updates',
                          subtitle: 'Team posts & notices',
                          icon: Icons.campaign_outlined,
                          accent: const Color(0xFFFF9F0A),
                          panchang: _panchang,
                          body: _body,
                          onTap: () => _openPage(const UpdatesScreen()),
                          wide: true,
                        ),
                        const AppBottomNavSpacer(extra: 24),
                      ],
                    ),
                  ),
                ),
              ],
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

class _DeskTile extends StatelessWidget {
  const _DeskTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.panchang,
    required this.body,
    required this.onTap,
    this.wide = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
  })
  panchang;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
  })
  body;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF121212),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 16, 14, wide ? 16 : 18),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: panchang(size: 13)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: body(size: 11.5, color: const Color(0xFF8E8E93)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8E8E93)),
            ],
          ),
        ),
      ),
    );
  }
}
