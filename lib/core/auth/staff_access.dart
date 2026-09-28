import 'package:flutter/foundation.dart';

import '../data/staff_profile.dart';

enum BerpRole { staff, manager, admin, superAdmin }

extension BerpRoleAccess on BerpRole {
  bool get isManager =>
      this == BerpRole.manager ||
      this == BerpRole.admin ||
      this == BerpRole.superAdmin;

  bool get isOrgAdmin => this == BerpRole.admin || this == BerpRole.superAdmin;

  bool get isSuperAdmin => this == BerpRole.superAdmin;

  String get label => switch (this) {
    BerpRole.staff => 'Staff',
    BerpRole.manager => 'Manager',
    BerpRole.admin => 'Admin',
    BerpRole.superAdmin => 'Super admin',
  };

  String get storageValue => switch (this) {
    BerpRole.staff => 'staff',
    BerpRole.manager => 'manager',
    BerpRole.admin => 'admin',
    BerpRole.superAdmin => 'super_admin',
  };

  static BerpRole parse(String? raw) {
    return switch ((raw ?? '').trim()) {
      'super_admin' => BerpRole.superAdmin,
      'admin' || 'hr_manager' => BerpRole.admin,
      'manager' => BerpRole.manager,
      _ => BerpRole.staff,
    };
  }
}

/// Signed-in role, loaded from profiles. Screens listen and rebuild.
abstract final class StaffAccess {
  static final role = ValueNotifier<BerpRole>(BerpRole.staff);
  static String? userId;

  static void apply(StaffProfile? profile) {
    userId = profile?.id;
    final next = BerpRoleAccess.parse(profile?.role);
    if (role.value != next) role.value = next;
  }
}
