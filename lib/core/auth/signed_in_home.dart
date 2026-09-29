import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../data/berp_cloud.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/staff/staff_home_screen.dart';
import '../../features/welcome/welcome_screen.dart';
import 'staff_access.dart';

/// Loads the signed-in profile, then opens the home for that role.
Future<Widget> signedInHome() async {
  try {
    final profile = await BerpCloud.fetchProfile();
    StaffAccess.apply(profile);
    if (profile?.suspended == true) {
      await AuthService.signOut();
      StaffAccess.clear();
      return const _SuspendedGate();
    }
  } catch (_) {
    StaffAccess.apply(null);
  }
  if (StaffAccess.role.value.isOrgAdmin) {
    return const AdminDashboardScreen();
  }
  return const StaffHomeScreen();
}

class _SuspendedGate extends StatelessWidget {
  const _SuspendedGate();

  @override
  Widget build(BuildContext context) {
    return const WelcomeScreen();
  }
}
