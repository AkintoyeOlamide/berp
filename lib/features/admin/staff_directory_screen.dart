import 'package:flutter/material.dart';

import '../../core/auth/staff_access.dart';
import '../../core/data/berp_org.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/pattern_page.dart';
import 'attendance_history_screen.dart';

class StaffDirectoryScreen extends StatefulWidget {
  const StaffDirectoryScreen({super.key});

  @override
  State<StaffDirectoryScreen> createState() => _StaffDirectoryScreenState();
}

class _StaffDirectoryScreenState extends State<StaffDirectoryScreen> {
  List<OrgPerson> _people = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final people = await BerpOrg.people();
    if (!mounted) return;
    setState(() => _people = people);
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Dashboard > Staff',
      title: 'Staff',
      subtitle: '${_people.length} PEOPLE',
      bottom: const AppBottomNav(currentIndex: 1),
      child: _people.isEmpty
          ? Text(
              'No staff records are visible for your role yet.',
              style: PatternPage.body(size: 13, color: PatternPage.muted),
            )
          : PatternGroup(
              children: [
                for (final person in _people)
                  PatternListRow(
                    title: person.name.isEmpty ? person.email : person.name,
                    subtitle: [
                      if (person.jobTitle.isNotEmpty) person.jobTitle,
                      if (person.department.isNotEmpty) person.department,
                      BerpRoleAccess.parse(person.role).label,
                    ].join('  ·  '),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _StaffDetailScreen(person: person),
                        ),
                      );
                      await _load();
                    },
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
          if (_lockedSuper)
            Text(
              'Only a super admin can change this role.',
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
        ],
      ),
    );
  }
}

extension on OrgPerson {
  String get labelSafe => BerpRoleAccess.parse(role).label;
}
