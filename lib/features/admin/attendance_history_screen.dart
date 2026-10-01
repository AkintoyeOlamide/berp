import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/data/berp_org.dart';
import '../../core/data/staff_store.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/pattern_page.dart';

enum _Range { today, yesterday, week, month, custom }

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key, this.fixedUserId, this.fixedName});

  final String? fixedUserId;
  final String? fixedName;

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  _Range _range = _Range.today;
  DateTime? _customFrom;
  DateTime? _customTo;
  String? _employeeId;
  String? _department;
  String? _company;
  String? _location;
  List<OrgPerson> _people = [];
  List<String> _locations = [];
  List<AttendanceRow> _rows = [];
  bool _loading = true;
  bool _filtersOpen = false;
  String? _expandedId;

  bool get _individual => widget.fixedUserId != null;

  @override
  void initState() {
    super.initState();
    _employeeId = widget.fixedUserId;
    _load();
  }

  (DateTime, DateTime) _bounds() {
    final today = lagosToday();
    DateTime startDay = today;
    DateTime endDay = today.add(const Duration(days: 1));
    switch (_range) {
      case _Range.today:
        break;
      case _Range.yesterday:
        startDay = today.subtract(const Duration(days: 1));
        endDay = today;
      case _Range.week:
        startDay = lagosWeekMonday();
        endDay = startDay.add(const Duration(days: 7));
      case _Range.month:
        startDay = DateTime.utc(today.year, today.month);
        endDay = DateTime.utc(today.year, today.month + 1);
      case _Range.custom:
        final from = _customFrom ?? DateTime.now();
        final to = _customTo ?? from;
        startDay = DateTime.utc(from.year, from.month, from.day);
        endDay = DateTime.utc(
          to.year,
          to.month,
          to.day,
        ).add(const Duration(days: 1));
    }
    return (
      startDay.subtract(const Duration(hours: 1)),
      endDay.subtract(const Duration(hours: 1)),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final people = await BerpOrg.people();
    final places = await BerpOrg.locations();
    final bounds = _bounds();
    List<String>? userIds;
    if (!_individual &&
        ((_department != null && _department!.isNotEmpty) ||
            (_company != null && _company!.isNotEmpty) ||
            (_employeeId != null && _employeeId!.isNotEmpty))) {
      userIds = [
        for (final person in people)
          if ((_employeeId == null ||
                  _employeeId!.isEmpty ||
                  person.id == _employeeId) &&
              (_department == null ||
                  _department!.isEmpty ||
                  person.department == _department) &&
              (_company == null ||
                  _company!.isEmpty ||
                  person.company == _company))
            person.id,
      ];
    }
    final rows = await BerpOrg.history(
      from: bounds.$1,
      to: bounds.$2,
      userId: _individual ? widget.fixedUserId : null,
      userIds: userIds,
      locationName: _location,
    );
    if (!mounted) return;
    setState(() {
      _people = people;
      _locations = {
        for (final place in places)
          if (place.name.isNotEmpty) place.name,
      }.toList()
        ..sort();
      _rows = rows;
      _loading = false;
    });
  }

  Future<void> _pickCustom() async {
    final from = await showDatePicker(
      context: context,
      initialDate: _customFrom ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (from == null || !mounted) return;
    final to = await showDatePicker(
      context: context,
      initialDate: from,
      firstDate: from,
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (to == null) return;
    setState(() {
      _range = _Range.custom;
      _customFrom = from;
      _customTo = to;
    });
    await _load();
  }

  int get _presentCount {
    final ids = <String>{};
    for (final row in _rows) {
      final id = row.person?.id ?? row.session.id;
      ids.add(id);
    }
    return ids.length;
  }

  int get _lateCount {
    var late = 0;
    for (final row in _rows) {
      final wall = lagosWallClock(row.session.clockIn);
      if (wall.hour > 9 || (wall.hour == 9 && wall.minute > 30)) {
        late += 1;
      }
    }
    return late;
  }

  Duration get _logged {
    var total = Duration.zero;
    for (final row in _rows) {
      total += row.session.elapsed;
    }
    return total;
  }

  String get _subtitle {
    final count = _rows.length;
    final shifts = '$count shift${count == 1 ? '' : 's'}';
    return switch (_range) {
      _Range.today => 'Today · $shifts',
      _Range.yesterday => 'Yesterday · $shifts',
      _Range.week => 'This week · $shifts',
      _Range.month => 'This month · $shifts',
      _Range.custom => 'Custom · $shifts',
    };
  }

  String get _sectionLabel {
    if (_rows.isEmpty) return _label(_range);
    final first = lagosWallClock(_rows.first.session.clockIn);
    final day = first.day.toString().padLeft(2, '0');
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final stamp = '$day ${months[first.month - 1]}';
    return switch (_range) {
      _Range.today => 'Today · $stamp',
      _Range.yesterday => 'Yesterday · $stamp',
      _Range.week => 'This week',
      _Range.month => 'This month',
      _Range.custom => 'Custom range',
    };
  }

  @override
  Widget build(BuildContext context) {
    final departments = {
      for (final person in _people)
        if (person.department.isNotEmpty) person.department,
    }.toList()
      ..sort();
    final companies = {
      for (final person in _people)
        if (person.company.isNotEmpty) person.company,
    }.toList()
      ..sort();
    final present = _presentCount;
    final late = _lateCount;
    final logged = _logged;

    return PatternPage(
      breadcrumb: _individual ? 'Staff > Attendance' : 'Dashboard > History',
      title: _individual
          ? (widget.fixedName ?? 'Attendance')
          : 'Attendance history',
      subtitle: _loading ? 'Loading…' : _subtitle,
      bottom: _individual ? null : const AppBottomNav(currentIndex: 3),
      actions: const [
        _LiveBadge(),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: Icons.groups_rounded,
                  value: '$present',
                  label: 'Present',
                  accent: const Color(0xFF3B82F6),
                  tint: const Color(0xFF152238),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.schedule_rounded,
                  value: '$late',
                  label: 'Late',
                  accent: const Color(0xFFEF4444),
                  tint: const Color(0xFF2A1717),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryCard(
                  icon: Icons.bar_chart_rounded,
                  value: _shortLogged(logged),
                  label: 'Logged',
                  accent: const Color(0xFF22C55E),
                  tint: const Color(0xFF14241A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final range in _Range.values) ...[
                  if (range != _Range.values.first) const SizedBox(width: 8),
                  _RangeChip(
                    label: _label(range),
                    selected: _range == range,
                    onTap: () async {
                      if (range == _Range.custom) {
                        await _pickCustom();
                        return;
                      }
                      setState(() => _range = range);
                      await _load();
                    },
                  ),
                ],
              ],
            ),
          ),
          if (!_individual) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _filtersOpen = !_filtersOpen),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: PatternPage.row,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: PatternPage.divider),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.filter_list_rounded,
                      size: 18,
                      color: PatternPage.muted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filters',
                            style: PatternPage.body(
                              size: 13,
                              weight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Employee, Department, Company, Location',
                            style: PatternPage.body(
                              size: 11,
                              color: PatternPage.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _filtersOpen
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: PatternPage.muted,
                    ),
                  ],
                ),
              ),
            ),
            if (_filtersOpen) ...[
              const SizedBox(height: 10),
              _filter(
                'Employee',
                _employeeId,
                [
                  for (final person in _people)
                    (
                      person.id,
                      person.name.isEmpty ? person.email : person.name,
                    ),
                ],
                (value) {
                  setState(() => _employeeId = value);
                  _load();
                },
              ),
              _filter(
                'Department',
                _department,
                [for (final item in departments) (item, item)],
                (value) {
                  setState(() => _department = value);
                  _load();
                },
              ),
              _filter(
                'Company',
                _company,
                [for (final item in companies) (item, item)],
                (value) {
                  setState(() => _company = value);
                  _load();
                },
              ),
              _filter(
                'Location',
                _location,
                [for (final item in _locations) (item, item)],
                (value) {
                  setState(() => _location = value);
                  _load();
                },
              ),
            ],
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  _sectionLabel,
                  style: PatternPage.body(
                    size: 13,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${_rows.length} record${_rows.length == 1 ? '' : 's'}',
                style: PatternPage.body(size: 12, color: PatternPage.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_rows.isEmpty)
            Text(
              'No attendance in this range.',
              style: PatternPage.body(size: 13, color: PatternPage.muted),
            )
          else
            for (final row in _rows) ...[
              _HistoryCard(
                row: row,
                showName: !_individual,
                expanded: _expandedId == row.session.id,
                onToggle: () => setState(() {
                  _expandedId =
                      _expandedId == row.session.id ? null : row.session.id;
                }),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  String _label(_Range range) {
    return switch (range) {
      _Range.today => 'Today',
      _Range.yesterday => 'Yesterday',
      _Range.week => 'Week',
      _Range.month => 'Month',
      _Range.custom => 'Custom',
    };
  }

  String _shortLogged(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    if (hours <= 0) return '${minutes}m';
    return '${hours}h ${minutes}m';
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Live',
            style: PatternPage.body(
              size: 11,
              weight: FontWeight.w600,
              color: const Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
    required this.tint,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color accent;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: 10),
          Text(
            value,
            style: PatternPage.body(size: 20, weight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: PatternPage.body(size: 11, color: accent),
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.row,
    required this.showName,
    required this.expanded,
    required this.onToggle,
  });

  final AttendanceRow row;
  final bool showName;
  final bool expanded;
  final VoidCallback onToggle;

  static const _avatarColors = [
    Color(0xFF3044C4),
    Color(0xFF7C3AED),
    Color(0xFFEA580C),
    Color(0xFF0D9488),
    Color(0xFFDB2777),
  ];

  @override
  Widget build(BuildContext context) {
    final session = row.session;
    final name = row.person?.name.isNotEmpty == true
        ? row.person!.name
        : 'Staff';
    final department = row.person?.department ?? '';
    final open = session.isOpen;
    final lat = session.clockInLat;
    final lng = session.clockInLng;
    final color =
        _avatarColors[name.hashCode.abs() % _avatarColors.length];

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
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color,
                  backgroundImage:
                      (row.person?.avatarUrl.isNotEmpty ?? false)
                          ? NetworkImage(row.person!.avatarUrl)
                          : null,
                  child: (row.person?.avatarUrl.isNotEmpty ?? false)
                      ? null
                      : Text(
                          _initials(name),
                          style: PatternPage.body(
                            size: 12,
                            weight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        showName ? name : formatDay(lagosWallClock(session.clockIn)),
                        style: PatternPage.body(
                          size: 14,
                          weight: FontWeight.w700,
                        ),
                      ),
                      if (showName && department.isNotEmpty)
                        Text(
                          department,
                          style: PatternPage.body(
                            size: 11,
                            color: PatternPage.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (open
                            ? const Color(0xFF22C55E)
                            : PatternPage.muted)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: open
                              ? const Color(0xFF22C55E)
                              : PatternPage.muted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        open ? 'Open' : 'Closed',
                        style: PatternPage.body(
                          size: 11,
                          weight: FontWeight.w600,
                          color: open
                              ? const Color(0xFF22C55E)
                              : PatternPage.muted,
                        ),
                      ),
                    ],
                  ),
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetaCell(
                    icon: Icons.login_rounded,
                    label: 'Clock-in',
                    value: formatClock(session.clockIn),
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
                    label: 'Duration',
                    value: formatDurationHms(session.elapsed),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: PatternPage.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    session.siteName?.isNotEmpty == true
                        ? session.siteName!
                        : 'Location not recorded',
                    style: PatternPage.body(
                      size: 12,
                      color: PatternPage.muted,
                    ),
                  ),
                ),
              ],
            ),
            if (expanded) ...[
              if (lat != null && lng != null) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _openMap(lat, lng),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.my_location_rounded,
                        size: 15,
                        color: PatternPage.blue,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${lat.toStringAsFixed(7)}, ${lng.toStringAsFixed(7)}',
                          style: PatternPage.body(
                            size: 12,
                            color: PatternPage.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              _deviceLine(
                Icons.smartphone_rounded,
                'Device type',
                session.deviceType,
              ),
              const SizedBox(height: 8),
              _deviceLine(
                Icons.fingerprint_rounded,
                'Device ID',
                session.deviceShortId.isEmpty
                    ? 'Not recorded'
                    : session.deviceShortId,
              ),
              if (open) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: PatternPage.blue.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Live location',
                          style: PatternPage.body(
                            size: 11,
                            weight: FontWeight.w600,
                            color: PatternPage.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _deviceLine(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: PatternPage.muted),
        const SizedBox(width: 6),
        Text(
          '$label  ·  ',
          style: PatternPage.body(size: 12, color: PatternPage.muted),
        ),
        Expanded(
          child: Text(
            value,
            style: PatternPage.body(size: 12, weight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Future<void> _openMap(double lat, double lng) async {
    await launchUrl(
      Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      ),
      mode: LaunchMode.externalApplication,
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
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: PatternPage.muted),
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

Widget _filter(
  String label,
  String? value,
  List<(String, String)> options,
  ValueChanged<String?> onChanged,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: PatternPage.body(size: 12, color: PatternPage.muted),
        filled: true,
        fillColor: PatternPage.row,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PatternPage.divider),
        ),
      ),
      dropdownColor: const Color(0xFF161616),
      style: PatternPage.body(size: 13),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text('All', style: PatternPage.body(size: 13)),
        ),
        for (final option in options)
          DropdownMenuItem<String?>(
            value: option.$1,
            child: Text(option.$2, style: PatternPage.body(size: 13)),
          ),
      ],
      onChanged: onChanged,
    ),
  );
}
