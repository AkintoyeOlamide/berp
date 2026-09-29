import 'package:flutter/material.dart';

import '../../core/auth/staff_access.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/pattern_page.dart';
import '../settings/settings_screen.dart';
import '../staff/appraisals_screen.dart';
import '../staff/leave_screen.dart';
import '../staff/profile_screen.dart';
import '../staff/updates_screen.dart';
import 'locations_screen.dart';
import 'notifications_screen.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final superAdmin = StaffAccess.role.value.isSuperAdmin;
    return PatternPage(
      breadcrumb: 'Dashboard',
      title: 'More',
      subtitle: superAdmin ? 'SUPER ADMIN' : 'ADMIN',
      bottom: const AppBottomNav(currentIndex: 4),
      child: PatternGroup(
        children: [
          _link(context, 'Leave', const LeaveScreen()),
          _link(context, 'Appraisals', const AppraisalsScreen()),
          _link(context, 'Locations', const LocationsScreen()),
          _link(context, 'Updates', const UpdatesScreen()),
          _link(context, 'Notifications', const NotificationsScreen()),
          _link(context, 'Profile', const ProfileScreen()),
          if (superAdmin) _link(context, 'Settings', const SettingsScreen()),
        ],
      ),
    );
  }

  PatternListRow _link(BuildContext context, String title, Widget page) {
    return PatternListRow(
      title: title,
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
      },
    );
  }
}
