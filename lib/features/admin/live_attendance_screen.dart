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
  int _totalStaff = 0;
  int _clockedOutToday = 0;
  String _query = '';
  String? _department;
  String? _expandedId;
  Timer? _tick;
  RealtimeChannel? _channel;
  final _search = TextEditingController();

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
    _search.dispose();
    final channel = _channel;
    if (channel != null) {
      AuthService.client.removeChannel(channel);
    }
    super.dispose();
  }

  Future<void> _load() async {
    final today = lagosToday();
    final shifts = await BerpOrg.liveShifts();
    final summary = await BerpOrg.summary();
    final history = await BerpOrg.history(
      from: today.subtract(const Duration(hours: 1)),
      to: today.add(const Duration(days: 1)).subtract(const Duration(hours: 1)),
      limit: 800,
    );
    final out = history.where((row) => row.session.clockOut != null).length;
    if (!mounted) return;
    setState(() {
      _shifts = shifts;
      _totalStaff = summary.totalStaff;
      _clockedOutToday = out;
    });
  }

  Future<void> _map(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<LiveShift> get _filtered {
    final q = _query.trim().toLowerCase();
    return [
      for (final shift in _shifts)
        if ((_department == null ||
                _department!.isEmpty ||
                shift.department == _department) &&
            (q.isEmpty ||
                shift.name.toLowerCase().contains(q) ||
                shift.department.toLowerCase().contains(q) ||
                shift.locationName.toLowerCase().contains(q) ||
                shift.jobTitle.toLowerCase().contains(q) ||
                shift.company.toLowerCase().contains(q)))
          shift,
    ];
  }

  Map<String, int> get _deptCounts {
    final counts = <String, int>{};
    for (final shift in _shifts) {
      final key = shift.department.trim().isEmpty
          ? 'Unassigned'
          : shift.department.trim();
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final depts = _deptCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final online = _shifts.length;

    return PatternPage(
      breadcrumb: 'Dashboard > Live',
      title: 'Live attendance',
      subtitle: 'Currently clocked in',
      bottom: const AppBottomNav(currentIndex: 2),
      actions: [
        _StatusPill(
          label: '$online online',
          color: const Color(0xFF22C55E),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: '$online',
                  label: 'Clocked in',
                  icon: Icons.groups_rounded,
                  accent: const Color(0xFF3B82F6),
                  progress: _totalStaff == 0 ? 0 : online / _totalStaff,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: _StatTile(
                  value: '0',
                  label: 'On break',
                  icon: Icons.coffee_rounded,
                  accent: Color(0xFFA855F7),
                  progress: 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  value: '$_clockedOutToday',
                  label: 'Clocked out',
                  icon: Icons.logout_rounded,
                  accent: const Color(0xFFF97316),
                  progress: _totalStaff == 0
                      ? 0
                      : _clockedOutToday / _totalStaff,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  value: '$_totalStaff',
                  label: 'Total staff',
                  icon: Icons.person_rounded,
                  accent: const Color(0xFF22C55E),
                  progress: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: PatternPage.row,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PatternPage.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: PatternPage.muted,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _search,
                          onChanged: (value) =>
                              setState(() => _query = value),
                          style: PatternPage.body(size: 13),
                          cursorColor: PatternPage.blue,
                          decoration: InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText:
                                'Search by name, department or location...',
                            hintStyle: PatternPage.body(
                              size: 12,
                              color: PatternPage.muted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: PatternPage.row,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PatternPage.divider),
                ),
                child: IconButton(
                  onPressed: () => setState(() {
                    _query = '';
                    _department = null;
                    _search.clear();
                  }),
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: PatternPage.muted,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _DeptChip(
                  label: 'All ($online)',
                  selected: _department == null,
                  onTap: () => setState(() => _department = null),
                ),
                for (final entry in depts) ...[
                  const SizedBox(width: 8),
                  _DeptChip(
                    label: '${entry.key} (${entry.value})',
                    selected: _department == entry.key,
                    onTap: () => setState(() {
                      _department =
                          _department == entry.key ? null : entry.key;
                    }),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  online == 0
                      ? 'Nobody is clocked in right now.'
                      : 'No matches for this filter.',
                  style: PatternPage.body(
                    size: 13,
                    color: PatternPage.muted,
                  ),
                ),
              ),
            )
          else
            for (final shift in filtered) ...[
              _LiveCard(
                shift: shift,
                expanded: _expandedId == shift.sessionId,
                onToggle: () => setState(() {
                  _expandedId = _expandedId == shift.sessionId
                      ? null
                      : shift.sessionId;
                }),
                onMap: _map,
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: PatternPage.body(
              size: 11,
              weight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
    required this.progress,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color accent;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: PatternPage.row,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PatternPage.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(height: 8),
          Text(
            value,
            style: PatternPage.body(size: 18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PatternPage.body(size: 10, color: PatternPage.muted),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: accent.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeptChip extends StatelessWidget {
  const _DeptChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? PatternPage.blue : PatternPage.row,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? PatternPage.blue : PatternPage.divider,
          ),
        ),
        child: Text(
          label,
          style: PatternPage.body(
            size: 12,
            weight: FontWeight.w600,
            color: selected ? Colors.white : PatternPage.muted,
          ),
        ),
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({
    required this.shift,
    required this.expanded,
    required this.onToggle,
    required this.onMap,
  });

  final LiveShift shift;
  final bool expanded;
  final VoidCallback onToggle;
  final Future<void> Function(double?, double?) onMap;

  @override
  Widget build(BuildContext context) {
    final latestLat = shift.latestLat ?? shift.clockLat;
    final latestLng = shift.latestLng ?? shift.clockLng;
    final duration = DateTime.now().difference(shift.clockIn);
    final roleLine = [
      if (shift.jobTitle.isNotEmpty) shift.jobTitle,
      if (shift.department.isNotEmpty) shift.department,
    ].join(' / ');
    final company = shift.company.isEmpty ? '' : ' · ${shift.company}';
    final deviceId = shift.deviceShortId;
    final deviceType = shift.deviceType;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PatternPage.row,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PatternPage.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: PatternPage.blue,
                      backgroundImage: shift.photoUrl.isEmpty
                          ? null
                          : NetworkImage(shift.photoUrl),
                      child: shift.photoUrl.isEmpty
                          ? Text(
                              _initials(shift.name),
                              style: PatternPage.body(
                                size: 13,
                                weight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: PatternPage.row,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shift.name.isEmpty ? 'Staff' : shift.name,
                        style: PatternPage.body(
                          size: 14,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$roleLine$company'.trim().isEmpty
                            ? 'Staff'
                            : '$roleLine$company',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: PatternPage.body(
                          size: 11,
                          color: PatternPage.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const _StatusPill(
                  label: 'Live',
                  color: Color(0xFF22C55E),
                ),
                const SizedBox(width: 4),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.chevron_right_rounded,
                  color: PatternPage.muted,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetaCell(
                    icon: Icons.login_rounded,
                    iconColor: const Color(0xFF22C55E),
                    label: 'Clock-in',
                    value: formatClock(shift.clockIn),
                  ),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: PatternPage.divider,
                ),
                Expanded(
                  child: _MetaCell(
                    icon: Icons.timer_outlined,
                    iconColor: PatternPage.muted,
                    label: 'Duration',
                    value: formatDurationHms(duration),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: PatternPage.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    shift.locationName.isEmpty
                        ? 'Location not recorded'
                        : shift.locationName,
                    style: PatternPage.body(
                      size: 12,
                      color: PatternPage.muted,
                    ),
                  ),
                ),
                if (latestLat != null && latestLng != null)
                  TextButton.icon(
                    onPressed: () => onMap(latestLat, latestLng),
                    icon: const Icon(Icons.map_outlined, size: 14),
                    label: Text(
                      'Open in Maps',
                      style: PatternPage.body(
                        size: 11,
                        weight: FontWeight.w600,
                        color: PatternPage.blue,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: PatternPage.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 10),
              if (latestLat != null && latestLng != null)
                _DetailLine(
                  icon: Icons.my_location_rounded,
                  text:
                      '${latestLat.toStringAsFixed(7)}, ${latestLng.toStringAsFixed(7)}',
                  color: PatternPage.blue,
                  onTap: () => onMap(latestLat, latestLng),
                ),
              _DetailLine(
                icon: Icons.smartphone_rounded,
                text: 'Device  ·  $deviceType',
              ),
              if (deviceId.isNotEmpty)
                _DetailLine(
                  icon: Icons.fingerprint_rounded,
                  text: 'Device ID  ·  $deviceId',
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _MetaCell extends StatelessWidget {
  const _MetaCell({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: PatternPage.body(
                    size: 10,
                    color: PatternPage.muted,
                  ),
                ),
                Text(
                  value,
                  style: PatternPage.body(
                    size: 13,
                    weight: FontWeight.w600,
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

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.text,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final String text;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color ?? PatternPage.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: PatternPage.body(
                size: 12,
                color: color ?? Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}
