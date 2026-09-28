import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/auth/staff_access.dart';
import '../../core/data/berp_cloud.dart';
import '../../core/data/berp_org.dart';
import '../../core/data/staff_store.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/pattern_page.dart';

class AppraisalsScreen extends StatefulWidget {
  const AppraisalsScreen({super.key});

  @override
  State<AppraisalsScreen> createState() => _AppraisalsScreenState();
}

class _AppraisalsScreenState extends State<AppraisalsScreen> {
  List<AppraisalRecord> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final role = StaffAccess.role.value;
    List<AppraisalRecord> items = [];
    try {
      if (role.isOrgAdmin) {
        items = await BerpCloud.organisationAppraisals();
      } else if (role == BerpRole.manager) {
        final assigned = await BerpCloud.reviewerAppraisals();
        final team = await BerpOrg.team();
        final extra = await BerpCloud.appraisalsForEmails([
          for (final person in team) person.email,
        ]);
        final seen = <String>{};
        items = [
          for (final item in [...assigned, ...extra])
            if (seen.add(item.id)) item,
        ];
      } else {
        items = await StaffStore.instance.appraisals();
      }
    } catch (_) {
      items = await StaffStore.instance.appraisals();
    }
    if (!mounted) return;
    setState(() => _items = items);
  }

  Future<void> _open(AppraisalRecord item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AppraisalDetailScreen(record: item),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Home > Appraisals',
      title: 'Appraisals',
      subtitle: 'PERFORMANCE',
      bottom: AppBottomNav(currentIndex: _navIndex),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            StaffAccess.role.value == BerpRole.staff
                ? 'Reviews linked to your work email in Bitachon HR.'
                : 'Bitachon HR reviews for you and, if you are a manager, the forms assigned to you.',
            style: PatternPage.body(
              size: 13,
              color: PatternPage.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          if (_items.isEmpty)
            Text(
              'No appraisals are linked to your work email yet.',
              style: PatternPage.body(size: 13, color: PatternPage.muted),
            )
          else
            PatternGroup(
              children: [
                for (final item in _items)
                  PatternListRow(
                    title: item.employeeName.isEmpty
                        ? item.title
                        : '${item.employeeName} · ${item.title}',
                    subtitle: [
                      if (item.period.isNotEmpty) item.period,
                      item.statusText,
                      if (item.rating != null) item.rating!.toStringAsFixed(1),
                    ].join('  ·  '),
                    leading: PatternDocIcon(
                      icon: item.completed
                          ? Icons.verified_outlined
                          : Icons.event_outlined,
                    ),
                    onTap: () => _open(item),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

int get _navIndex {
  final role = StaffAccess.role.value;
  if (role.isOrgAdmin) return 4;
  if (role == BerpRole.manager) return 3;
  return AppNavIndex.appraisals;
}

bool _canSubmit(AppraisalRecord record) {
  if (record.completed) return false;
  final email = AuthService.currentUser?.email?.trim().toLowerCase() ?? '';
  if (email.isNotEmpty && record.reviewerEmail.toLowerCase() == email) {
    return true;
  }
  return StaffAccess.role.value.isOrgAdmin;
}

class _AppraisalDetailScreen extends StatefulWidget {
  const _AppraisalDetailScreen({required this.record});

  final AppraisalRecord record;

  @override
  State<_AppraisalDetailScreen> createState() => _AppraisalDetailScreenState();
}

class _AppraisalDetailScreenState extends State<_AppraisalDetailScreen> {
  late final TextEditingController _comments;
  late final TextEditingController _score;
  bool _saving = false;

  AppraisalRecord get record => widget.record;

  @override
  void initState() {
    super.initState();
    _comments = TextEditingController(text: record.managerComments);
    _score = TextEditingController(
      text: record.rating == null ? '' : record.rating!.toString(),
    );
  }

  @override
  void dispose() {
    _comments.dispose();
    _score.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final score = double.tryParse(_score.text.trim());
    if (score == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a numeric score.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await BerpCloud.submitAppraisal(
        id: record.id,
        comments: _comments.text.trim(),
        score: score,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Appraisals > Detail',
      title: record.title,
      subtitle: record.period.toUpperCase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PatternGroup(
            children: [
              PatternListRow(
                title: 'Reviewer',
                subtitle: record.reviewer,
                trailing: const SizedBox.shrink(),
                onTap: () {},
              ),
              if (record.department.isNotEmpty)
                PatternListRow(
                  title: 'Department',
                  subtitle: record.department,
                  trailing: const SizedBox.shrink(),
                  onTap: () {},
                ),
              PatternListRow(
                title: 'Status',
                subtitle: record.statusText,
                trailing: const SizedBox.shrink(),
                onTap: () {},
              ),
              if (record.rating != null)
                PatternListRow(
                  title: 'Score',
                  subtitle: record.rating!.toStringAsFixed(1),
                  trailing: const SizedBox.shrink(),
                  onTap: () {},
                ),
            ],
          ),
          const SizedBox(height: 22),
          for (final section in _sections(record)) ...[
            PatternSectionLabel(section.$1),
            const SizedBox(height: 10),
            Text(
              section.$2,
              style: PatternPage.body(
                size: 13.5,
                color: Colors.white.withValues(alpha: 0.86),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (_sections(record).isEmpty)
            Text(
              'No comments on this review yet.',
              style: PatternPage.body(size: 13, color: PatternPage.muted),
            ),
          if (_canSubmit(record)) ...[
            const SizedBox(height: 8),
            const PatternSectionLabel('Your review'),
            const SizedBox(height: 10),
            TextField(
              controller: _comments,
              maxLines: 4,
              style: PatternPage.body(size: 13),
              cursorColor: PatternPage.blue,
              decoration: const InputDecoration(
                hintText: 'Manager comments',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _score,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: PatternPage.body(size: 13),
              cursorColor: PatternPage.blue,
              decoration: const InputDecoration(hintText: 'Overall score'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: PatternPage.blue),
                child: Text(
                  _saving ? 'Saving' : 'Submit appraisal',
                  style: PatternPage.panchang(size: 11, weight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

List<(String, String)> _sections(AppraisalRecord record) {
  return [
    if (record.managerComments.isNotEmpty)
      ('Manager comments', record.managerComments),
    if (record.strengths.isNotEmpty) ('Strengths', record.strengths),
    if (record.achievements.isNotEmpty) ('Achievements', record.achievements),
    if (record.goals.isNotEmpty) ('Goals', record.goals),
    if (record.developmentPlan.isNotEmpty)
      ('Development plan', record.developmentPlan),
  ];
}
