import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/auth/auth_service.dart';
import '../../core/data/berp_org.dart';
import '../../core/data/staff_store.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/pattern_page.dart';

class LiveAttendanceScreen extends StatefulWidget {
  const LiveAttendanceScreen({super.key});

  @override
  State<LiveAttendanceScreen> createState() => _LiveAttendanceScreenState();
}

class _LiveAttendanceScreenState extends State<LiveAttendanceScreen> {
  List<LiveShift> _shifts = [];
  Timer? _tick;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    try {
      _channel = AuthService.client
          .channel('berp-live-clock')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'clock_sessions',
            callback: (_) => _load(),
          )
          .subscribe();
    } catch (_) {}
  }

  @override
  void dispose() {
    _tick?.cancel();
    final channel = _channel;
    if (channel != null) {
      AuthService.client.removeChannel(channel);
    }
    super.dispose();
  }

  Future<void> _load() async {
    final shifts = await BerpOrg.liveShifts();
    if (!mounted) return;
    setState(() => _shifts = shifts);
  }

  Future<void> _map(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Dashboard > Live',
      title: 'Live attendance',
      subtitle: '${_shifts.length} CLOCKED IN',
      bottom: const AppBottomNav(currentIndex: 2),
      child: _shifts.isEmpty
          ? Text(
              'Nobody is clocked in right now.',
              style: PatternPage.body(size: 13, color: PatternPage.muted),
            )
          : Column(
              children: [
                for (final shift in _shifts) ...[
                  _LiveCard(shift: shift, onMap: _map),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.shift, required this.onMap});

  final LiveShift shift;
  final Future<void> Function(double?, double?) onMap;

  @override
  Widget build(BuildContext context) {
    final latestLat = shift.latestLat ?? shift.clockLat;
    final latestLng = shift.latestLng ?? shift.clockLng;
    final duration = DateTime.now().difference(shift.clockIn);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PatternPage.row,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PatternPage.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: PatternPage.blue,
                backgroundImage: shift.photoUrl.isEmpty
                    ? null
                    : NetworkImage(shift.photoUrl),
                child: shift.photoUrl.isEmpty
                    ? Text(
                        shift.name.isEmpty ? '?' : shift.name[0].toUpperCase(),
                        style: PatternPage.body(size: 14, weight: FontWeight.w600),
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
                      style: PatternPage.body(size: 14, weight: FontWeight.w600),
                    ),
                    Text(
                      [
                        if (shift.jobTitle.isNotEmpty) shift.jobTitle,
                        if (shift.department.isNotEmpty) shift.department,
                        if (shift.company.isNotEmpty) shift.company,
                      ].join('  ·  '),
                      style: PatternPage.body(size: 11, color: PatternPage.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'In ${formatClock(shift.clockIn)}  ·  ${formatDurationHms(duration)}',
            style: PatternPage.body(size: 12),
          ),
          const SizedBox(height: 4),
          Text(
            shift.locationName.isEmpty ? 'Location not recorded' : shift.locationName,
            style: PatternPage.body(size: 12, color: PatternPage.muted),
          ),
          if (shift.clockLat != null)
            Text(
              'Clock-in ${shift.clockLat!.toStringAsFixed(5)}, ${shift.clockLng!.toStringAsFixed(5)}',
              style: PatternPage.body(size: 11, color: PatternPage.muted),
            ),
          if (shift.latestLat != null)
            Text(
              'Latest ${shift.latestLat!.toStringAsFixed(5)}, ${shift.latestLng!.toStringAsFixed(5)}',
              style: PatternPage.body(size: 11, color: PatternPage.muted),
            ),
          if (latestLat != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => onMap(latestLat, latestLng),
                child: Text(
                  'Open in Google Maps',
                  style: PatternPage.body(size: 12, color: PatternPage.blue),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
