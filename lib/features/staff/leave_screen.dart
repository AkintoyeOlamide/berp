import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/data/staff_store.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/pattern_page.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  List<LeaveRequest> _requests = [];
  int _remaining = StaffStore.annualAllowance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final requests = await StaffStore.instance.leaveRequests();
    final remaining = await StaffStore.instance.remainingAnnualDays();
    if (!mounted) return;
    setState(() {
      _requests = requests;
      _remaining = remaining;
    });
  }

  Future<void> _request() async {
    final created = await Navigator.of(context).push<LeaveRequest>(
      MaterialPageRoute(builder: (_) => const _LeaveFormScreen()),
    );
    if (created == null) return;
    await StaffStore.instance.submitLeave(created);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Home > Leave',
      title: 'Leave',
      subtitle: '$_remaining ANNUAL DAYS LEFT',
      bottom: const AppBottomNav(currentIndex: AppNavIndex.leave),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: _request,
              style: FilledButton.styleFrom(
                backgroundColor: PatternPage.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Request leave',
                style: PatternPage.panchang(size: 11, weight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const PatternSectionLabel('Your requests'),
          const SizedBox(height: 10),
          if (_requests.isEmpty)
            Text(
              'No leave requests yet. Plan time off with 10 working days’ notice.',
              style: PatternPage.body(size: 13, color: PatternPage.muted),
            )
          else
            PatternGroup(
              children: [
                for (final request in _requests)
                  PatternListRow(
                    title: request.kind.label,
                    subtitle:
                        '${formatDay(request.start)} – ${formatDay(request.end)}  ·  ${request.days}d  ·  ${request.status.label}',
                    trailing: const SizedBox.shrink(),
                    onTap: () {},
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LeaveFormScreen extends StatefulWidget {
  const _LeaveFormScreen();

  @override
  State<_LeaveFormScreen> createState() => _LeaveFormScreenState();
}

class _LeaveFormScreenState extends State<_LeaveFormScreen> {
  LeaveKind _kind = LeaveKind.annual;
  DateTime _start = DateTime.now().add(const Duration(days: 10));
  DateTime _end = DateTime.now().add(const Duration(days: 12));
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final initial = start ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 400)),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked.isBefore(_start) ? _start : picked;
      }
    });
  }

  void _submit() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(
      LeaveRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        kind: _kind,
        start: _start,
        end: _end,
        note: _note.text.trim(),
        status: LeaveStatus.pending,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Leave > Request',
      title: 'Request leave',
      subtitle: 'PENDING HR REVIEW',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PatternSectionLabel('Type'),
          const SizedBox(height: 8),
          PatternGroup(
            children: [
              for (final kind in LeaveKind.values)
                PatternListRow(
                  title: kind.label,
                  selected: _kind == kind,
                  onTap: () => setState(() => _kind = kind),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const PatternSectionLabel('Dates'),
          const SizedBox(height: 8),
          PatternGroup(
            children: [
              PatternListRow(
                title: 'From',
                subtitle: formatDay(_start),
                onTap: () => _pick(true),
              ),
              PatternListRow(
                title: 'To',
                subtitle: formatDay(_end),
                onTap: () => _pick(false),
              ),
            ],
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _note,
            maxLines: 3,
            style: PatternPage.body(size: 13),
            cursorColor: PatternPage.blue,
            decoration: InputDecoration(
              hintText: 'Note for People (optional)',
              hintStyle: PatternPage.body(size: 13, color: PatternPage.muted),
              filled: true,
              fillColor: const Color(0xFF121212),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: PatternPage.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: PatternPage.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: PatternPage.blue),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: PatternPage.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Submit request',
                style: PatternPage.panchang(size: 11, weight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
