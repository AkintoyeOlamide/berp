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
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
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
        endDay = DateTime.utc(to.year, to.month, to.day).add(const Duration(days: 1));
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
      }.toList()..sort();
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

  @override
  Widget build(BuildContext context) {
    final departments = {
      for (final person in _people)
        if (person.department.isNotEmpty) person.department,
    }.toList()..sort();
    final companies = {
      for (final person in _people)
        if (person.company.isNotEmpty) person.company,
    }.toList()..sort();

    return PatternPage(
      breadcrumb: _individual ? 'Staff > Attendance' : 'Dashboard > History',
      title: _individual ? (widget.fixedName ?? 'Attendance') : 'Attendance history',
      subtitle: _loading ? 'LOADING' : '${_rows.length} SHIFTS',
      bottom: _individual ? null : const AppBottomNav(currentIndex: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final range in _Range.values)
                ChoiceChip(
                  label: Text(_label(range)),
                  selected: _range == range,
                  onSelected: (_) async {
                    if (range == _Range.custom) {
                      await _pickCustom();
                      return;
                    }
                    setState(() => _range = range);
                    await _load();
                  },
                ),
            ],
          ),
          if (!_individual) ...[
            const SizedBox(height: 14),
            _filter(
              'Employee',
              _employeeId,
              [for (final person in _people) (person.id, person.name.isEmpty ? person.email : person.name)],
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
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (_rows.isEmpty)
            Text(
              'No attendance in this range.',
              style: PatternPage.body(size: 13, color: PatternPage.muted),
            )
          else
            for (final row in _rows) _HistoryCard(row: row, showName: !_individual),
        ],
      ),
    );
  }

  String _label(_Range range) {
    return switch (range) {
      _Range.today => 'Today',
      _Range.yesterday => 'Yesterday',
      _Range.week => 'This week',
      _Range.month => 'This month',
      _Range.custom => 'Custom',
    };
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.row, required this.showName});

  final AttendanceRow row;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final session = row.session;
    final out = session.clockOut;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PatternPage.row,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                formatDay(lagosWallClock(session.clockIn)),
                if (showName) row.person?.name ?? 'Staff',
                if (showName && (row.person?.department.isNotEmpty ?? false))
                  row.person!.department,
              ].join('  ·  '),
              style: PatternPage.body(size: 12, weight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${formatClock(session.clockIn)} – ${out == null ? 'Open' : formatClock(out)}  ·  ${formatDurationHms(session.elapsed)}',
              style: PatternPage.body(size: 12),
            ),
            Text(
              session.siteName ?? 'Location not recorded',
              style: PatternPage.body(size: 11, color: PatternPage.muted),
            ),
            if (session.clockInLat != null)
              _coord('In', session.clockInLat!, session.clockInLng),
            if (session.clockOutLat != null)
              _coord('Out', session.clockOutLat!, session.clockOutLng),
          ],
        ),
      ),
    );
  }

  Widget _coord(String label, double lat, double? lng) {
    return TextButton(
      onPressed: lng == null
          ? null
          : () {
              launchUrl(
                Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                ),
                mode: LaunchMode.externalApplication,
              );
            },
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        '$label $lat, ${lng ?? ''}',
        style: PatternPage.body(size: 11, color: PatternPage.blue),
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
