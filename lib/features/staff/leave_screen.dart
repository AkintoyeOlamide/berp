import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/staff_access.dart';
import '../../core/data/berp_cloud.dart';
import '../../core/data/berp_org.dart';
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
  List<TeamLeave> _team = [];
  int _remaining = StaffStore.annualAllowance;

  bool get _canDecide => StaffAccess.role.value.isManager;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final requests = await StaffStore.instance.leaveRequests();
    final remaining = await StaffStore.instance.remainingAnnualDays();
    final team = _canDecide ? await BerpOrg.leaveQueue() : <TeamLeave>[];
    if (!mounted) return;
    setState(() {
      _requests = requests;
      _remaining = remaining;
      _team = team;
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

  Future<void> _decide(TeamLeave item, LeaveStatus status) async {
    await BerpOrg.decideLeave(item.request.id, status);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Home > Leave',
      title: 'Leave',
      subtitle: '$_remaining ANNUAL DAYS LEFT',
      bottom: AppBottomNav(
        currentIndex: StaffAccess.role.value.isOrgAdmin ? 4 : AppNavIndex.leave,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_canDecide && _team.isNotEmpty) ...[
            const PatternSectionLabel('Team requests'),
            const SizedBox(height: 10),
            PatternGroup(
              children: [
                for (final item in _team)
                  PatternListRow(
                    title: item.person?.name.isNotEmpty == true
                        ? item.person!.name
                        : item.request.kind.label,
                    subtitle:
                        '${item.request.kind.label}  ·  ${formatDay(item.request.start)} – ${formatDay(item.request.end)}  ·  ${item.request.status.label}${item.request.handoverEmail.isEmpty ? '' : '  ·  handover ${item.request.handoverEmail}'}',
                    trailing: item.request.status == LeaveStatus.pending
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () =>
                                    _decide(item, LeaveStatus.approved),
                                icon: const Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFF75BD42),
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    _decide(item, LeaveStatus.declined),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Color(0xFFF69306),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                    onTap: () {},
                  ),
              ],
            ),
            const SizedBox(height: 22),
          ],
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
  final _handoverEmail = TextEditingController();
  final _handoverNote = TextEditingController();
  Uint8List? _file;
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    _handoverEmail.dispose();
    _handoverNote.dispose();
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

  Future<void> _pickFile() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _file = bytes);
  }

  Future<void> _submit() async {
    final email = _handoverEmail.text.trim();
    final handoverNote = _handoverNote.text.trim();
    if (!email.contains('@') || (handoverNote.isEmpty && _file == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add the handover person’s email and a handover note or file.',
          ),
        ),
      );
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _saving = true);
    var fileUrl = '';
    if (_file != null) {
      fileUrl = await BerpCloud.uploadHandover(_file!);
    }
    if (!mounted) return;
    Navigator.of(context).pop(
      LeaveRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        kind: _kind,
        start: _start,
        end: _end,
        note: _note.text.trim(),
        handoverEmail: email,
        handoverNote: handoverNote,
        handoverFileUrl: fileUrl,
        status: LeaveStatus.pending,
      ),
    );
  }

  InputDecoration _field(String hint) {
    return InputDecoration(
      hintText: hint,
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
            controller: _handoverEmail,
            keyboardType: TextInputType.emailAddress,
            style: PatternPage.body(size: 13),
            cursorColor: PatternPage.blue,
            decoration: _field('Handover person’s email'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _handoverNote,
            maxLines: 3,
            style: PatternPage.body(size: 13),
            cursorColor: PatternPage.blue,
            decoration: _field('Handover note'),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file_rounded, color: PatternPage.blue),
              label: Text(
                _file == null ? 'Attach handover file' : 'Handover file attached',
                style: PatternPage.body(size: 13, color: PatternPage.blue),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
              onPressed: _saving ? null : _submit,
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
