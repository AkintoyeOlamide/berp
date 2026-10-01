import 'package:flutter/material.dart';

import '../../core/auth/staff_access.dart';
import '../../core/data/berp_org.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/pattern_page.dart';
import 'attendance_history_screen.dart';

class StaffDirectoryScreen extends StatefulWidget {
  const StaffDirectoryScreen({
    super.key,
    this.title = 'Staff',
    this.roleFilter,
    this.suspendedOnly = false,
    this.excludeUserIds = const {},
    this.hideBottomNav = false,
  });

  final String title;

  /// `manager`, `admin` (admin/hr_manager/super_admin), or `staff`.
  final String? roleFilter;
  final bool suspendedOnly;
  final Set<String> excludeUserIds;
  final bool hideBottomNav;

  @override
  State<StaffDirectoryScreen> createState() => _StaffDirectoryScreenState();
}

class _StaffDirectoryScreenState extends State<StaffDirectoryScreen> {
  List<OrgPerson> _people = [];
  bool _loading = true;
  bool _searching = false;
  String _query = '';
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<OrgPerson> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _people;
    return [
      for (final person in _people)
        if (person.name.toLowerCase().contains(q) ||
            person.email.toLowerCase().contains(q) ||
            person.department.toLowerCase().contains(q) ||
            person.company.toLowerCase().contains(q) ||
            person.jobTitle.toLowerCase().contains(q) ||
            BerpRoleAccess.parse(person.role).label.toLowerCase().contains(q))
          person,
    ];
  }

  bool _matchesRole(OrgPerson person) {
    final filter = widget.roleFilter;
    if (filter == null || filter.isEmpty) return true;
    final role = BerpRoleAccess.parse(person.role);
    return switch (filter) {
      'manager' || 'operations' => role == BerpRole.manager,
      'admin' => role == BerpRole.admin,
      'super_admin' => role == BerpRole.superAdmin,
      'staff' => role == BerpRole.staff,
      'others' =>
        role != BerpRole.staff &&
            role != BerpRole.manager &&
            role != BerpRole.admin &&
            role != BerpRole.superAdmin,
      _ => person.role == filter,
    };
  }

  Future<void> _load() async {
    final people = await BerpOrg.people();
    final filtered = [
      for (final person in people)
        if (!widget.excludeUserIds.contains(person.id) &&
            (!widget.suspendedOnly || person.suspended) &&
            _matchesRole(person))
          person,
    ];
    if (!mounted) return;
    setState(() {
      _people = filtered;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filtered;
    return PatternPage(
      breadcrumb: 'Dashboard > Staff',
      title: widget.title,
      subtitle: _loading
          ? 'LOADING'
          : _searching && _query.trim().isNotEmpty
              ? '${visible.length} OF ${_people.length} PEOPLE'
              : '${_people.length} PEOPLE',
      bottom: widget.hideBottomNav
          ? null
          : const AppBottomNav(currentIndex: 1),
      actions: [
        Material(
          color: const Color(0xFF1A1A1A),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _query = '';
                  _search.clear();
                }
              });
            },
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                _searching ? Icons.close_rounded : Icons.search_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_searching) ...[
                  Container(
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
                            autofocus: true,
                            onChanged: (value) =>
                                setState(() => _query = value),
                            style: PatternPage.body(size: 13),
                            cursorColor: PatternPage.blue,
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: 'Search name, role, department…',
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
                  const SizedBox(height: 16),
                ],
                if (visible.isEmpty)
                  Text(
                    _people.isEmpty
                        ? 'No staff match this view.'
                        : 'No people match your search.',
                    style: PatternPage.body(
                      size: 13,
                      color: PatternPage.muted,
                    ),
                  )
                else
                  PatternGroup(
                    children: [
                      for (final person in visible)
                        PatternListRow(
                          title: person.name.isEmpty
                              ? person.email
                              : person.name,
                          subtitle: [
                            if (person.jobTitle.isNotEmpty) person.jobTitle,
                            if (person.department.isNotEmpty)
                              person.department,
                            BerpRoleAccess.parse(person.role).label,
                            if (person.suspended) 'Suspended',
                          ].join('  ·  '),
                          leading: person.suspended
                              ? const Icon(
                                  Icons.block_rounded,
                                  color: Color(0xFFE25555),
                                )
                              : null,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    _StaffDetailScreen(person: person),
                              ),
                            );
                            await _load();
                          },
                        ),
                    ],
                  ),
              ],
            ),
    );
  }
}

class _StaffDetailScreen extends StatefulWidget {
  const _StaffDetailScreen({required this.person});

  final OrgPerson person;

  @override
  State<_StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<_StaffDetailScreen> {
  late OrgPerson _person;
  List<OrgPerson> _managers = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _person = widget.person;
    _loadManagers();
  }

  Future<void> _loadManagers() async {
    final people = await BerpOrg.people();
    if (!mounted) return;
    setState(() {
      _managers = people.where((person) {
        final role = BerpRoleAccess.parse(person.role);
        if (!StaffAccess.role.value.isSuperAdmin &&
            role == BerpRole.superAdmin) {
          return false;
        }
        return role == BerpRole.manager ||
            role == BerpRole.admin ||
            role == BerpRole.superAdmin;
      }).toList();
      final fresh = people.where((person) => person.id == _person.id);
      if (fresh.isNotEmpty) _person = fresh.first;
    });
  }

  bool get _lockedSuper {
    return BerpRoleAccess.parse(_person.role).isSuperAdmin &&
        !StaffAccess.role.value.isSuperAdmin;
  }

  List<BerpRole> get _roles {
    final roles = [BerpRole.staff, BerpRole.manager, BerpRole.admin];
    if (StaffAccess.role.value.isSuperAdmin) roles.add(BerpRole.superAdmin);
    return roles;
  }

  Future<void> _setRole(BerpRole role) async {
    if (_saving || _lockedSuper) return;
    if (role == BerpRole.superAdmin && !StaffAccess.role.value.isSuperAdmin) {
      return;
    }
    setState(() => _saving = true);
    try {
      await BerpOrg.assignRole(_person.id, role.storageValue);
      await _loadManagers();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setManager(String? managerId) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await BerpOrg.assignManager(_person.id, managerId);
      await _loadManagers();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _canSuspend {
    if (!StaffAccess.role.value.isOrgAdmin) return false;
    final email = _person.email.trim().toLowerCase();
    if (email == 'olamide@vmoaeros.com' || email == 'akintoyelmd@gmail.com') {
      return false;
    }
    if (BerpRoleAccess.parse(_person.role).isSuperAdmin &&
        !StaffAccess.role.value.isSuperAdmin) {
      return false;
    }
    return true;
  }

  Future<void> _toggleSuspend() async {
    if (!_canSuspend || _saving) return;
    final suspending = !_person.suspended;
    String reason = '';
    if (suspending) {
      final controller = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF121212),
            title: Text(
              'Suspend ${_person.name.isEmpty ? 'staff' : _person.name}?',
              style: PatternPage.body(size: 16, weight: FontWeight.w600),
            ),
            content: TextField(
              controller: controller,
              style: PatternPage.body(size: 13),
              decoration: InputDecoration(
                hintText: 'Reason (optional)',
                hintStyle: PatternPage.body(size: 13, color: PatternPage.muted),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: PatternPage.body(size: 13, color: PatternPage.muted),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Suspend',
                  style: PatternPage.body(
                    size: 13,
                    color: const Color(0xFFE25555),
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
      reason = controller.text.trim();
      controller.dispose();
      if (confirmed != true) return;
    }
    setState(() => _saving = true);
    try {
      await BerpOrg.setSuspended(
        _person.id,
        suspended: suspending,
        reason: reason,
      );
      await _loadManagers();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = BerpRoleAccess.parse(_person.role);
    final manager = _managers.where((person) => person.id == _person.managerId);
    return PatternPage(
      breadcrumb: 'Staff > Profile',
      title: _person.name.isEmpty ? 'Staff' : _person.name,
      subtitle: _person.email.toUpperCase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PatternGroup(
            children: [
              PatternListRow(
                title: 'Department',
                subtitle: _person.department.isEmpty ? '—' : _person.department,
                trailing: const SizedBox.shrink(),
                onTap: () {},
              ),
              PatternListRow(
                title: 'Company',
                subtitle: _person.company.isEmpty ? '—' : _person.company,
                trailing: const SizedBox.shrink(),
                onTap: () {},
              ),
              PatternListRow(
                title: 'Job title',
                subtitle: _person.jobTitle.isEmpty ? '—' : _person.jobTitle,
                trailing: const SizedBox.shrink(),
                onTap: () {},
              ),
              PatternListRow(
                title: 'Status',
                subtitle: _person.suspended ? 'Suspended' : 'Active',
                trailing: const SizedBox.shrink(),
                onTap: () {},
              ),
              PatternListRow(
                title: 'Manager',
                subtitle: manager.isEmpty
                    ? 'Unassigned'
                    : (manager.first.name.isEmpty
                          ? manager.first.email
                          : manager.first.name),
                trailing: const SizedBox.shrink(),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 22),
          const PatternSectionLabel('Role'),
          const SizedBox(height: 8),
          Text(
            StaffAccess.role.value.isSuperAdmin
                ? 'Assign Staff, Manager, Admin, or Super Admin.'
                : 'Assign Staff, Manager, or Admin.',
            style: PatternPage.body(
              size: 12,
              color: PatternPage.muted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          if (_lockedSuper)
            Text(
              'This account cannot be changed here.',
              style: PatternPage.body(size: 13, color: PatternPage.muted),
            )
          else
            PatternGroup(
              children: [
                for (final option in _roles)
                  PatternListRow(
                    title: option.label,
                    selected: role == option,
                    onTap: () => _setRole(option),
                  ),
              ],
            ),
          const SizedBox(height: 22),
          const PatternSectionLabel('Assign manager'),
          const SizedBox(height: 8),
          PatternGroup(
            children: [
              PatternListRow(
                title: 'No manager',
                selected: _person.managerId == null,
                onTap: () => _setManager(null),
              ),
              for (final option in _managers)
                if (option.id != _person.id)
                  PatternListRow(
                    title: option.name.isEmpty ? option.email : option.name,
                    subtitle: option.labelSafe,
                    selected: _person.managerId == option.id,
                    onTap: () => _setManager(option.id),
                  ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AttendanceHistoryScreen(
                      fixedUserId: _person.id,
                      fixedName: _person.name.isEmpty ? _person.email : _person.name,
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: PatternPage.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Attendance history',
                style: PatternPage.panchang(size: 11, weight: FontWeight.w600),
              ),
            ),
          ),
          if (_canSuspend) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: _saving ? null : _toggleSuspend,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _person.suspended
                      ? const Color(0xFF75BD42)
                      : const Color(0xFFE25555),
                  side: BorderSide(
                    color: _person.suspended
                        ? const Color(0xFF75BD42)
                        : const Color(0xFFE25555),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _person.suspended ? 'Restore account' : 'Suspend account',
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

extension on OrgPerson {
  String get labelSafe => BerpRoleAccess.parse(role).label;
}
