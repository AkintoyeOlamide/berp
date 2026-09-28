import 'package:flutter/widgets.dart';

import '../data/berp_cloud.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/staff/staff_home_screen.dart';
import 'staff_access.dart';

/// Loads the signed-in profile, then opens the home for that role.
Future<Widget> signedInHome() async {
  try {
    final profile = await BerpCloud.fetchProfile();
    StaffAccess.apply(profile);
  } catch (_) {
    StaffAccess.apply(null);
  }
  if (StaffAccess.role.value.isOrgAdmin) {
    return const AdminDashboardScreen();
  }
  return const StaffHomeScreen();
}
