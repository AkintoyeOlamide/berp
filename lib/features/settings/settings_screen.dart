import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/premium_ui.dart';
import '../about/about_screen.dart';
import '../contact/contact_screen.dart';
import '../staff/profile_screen.dart';
import '../welcome/welcome_screen.dart';
import 'settings_pages.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _bg = Color(0xFF0A0A0A);
  static const _sheet = Color(0xFF0B0B0B);
  static const _muted = Color(0xFF8E8E93);
  static const _row = Color(0xFF121212);

  TextStyle _panchang({
    required double size,
    FontWeight weight = FontWeight.w600,
    Color color = Colors.white,
    double height = 1.1,
  }) {
    return TextStyle(
      fontFamily: 'Panchang',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  TextStyle _body({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = Colors.white,
    double height = 1.3,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  void _open(BuildContext context, Widget page) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(premiumRoute(page));
  }

  Future<void> _pickTheme(BuildContext context) async {
    final settings = context.read<AppSettings>();
    final result = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: _row,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('App Theme', style: _panchang(size: 14)),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text('Dark', style: _body(size: 14)),
                  trailing: settings.isDark
                      ? const Icon(Icons.check, color: Color(0xFF1F2D90))
                      : null,
                  onTap: () => Navigator.pop(context, ThemeMode.dark),
                ),
                ListTile(
                  title: Text('Light', style: _body(size: 14)),
                  trailing: !settings.isDark
                      ? const Icon(Icons.check, color: Color(0xFF1F2D90))
                      : null,
                  onTap: () => Navigator.pop(context, ThemeMode.light),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (result != null) {
      await settings.setThemeMode(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final email = user?.email ?? 'Guest';
    final name = (user?.userMetadata?['full_name'] ??
            user?.userMetadata?['name'] ??
            email)
        .toString();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 210,
                width: double.infinity,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.45, 0, 0, 0, 0,
                    0, 0.45, 0, 0, 0,
                    0, 0, 0.52, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
                  child: Image.asset(
                    'assets/images/home/why.jpg',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.35),
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: Color(0xFF121212),
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 210,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000000),
                      Color(0xDD0A0A0A),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              top: 108,
              child: Container(
                decoration: const BoxDecoration(
                  color: _sheet,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Settings',
                                    style: _panchang(
                                      size: 28,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                _CloseChip(
                                  onTap: () =>
                                      Navigator.of(context).maybePop(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            _SectionLabel(label: 'ALERTS', body: _body),
                            const SizedBox(height: 10),
                            _SettingsGroup(
                              children: [
                                _SettingsRow(
                                  icon: Icons.notifications_none_rounded,
                                  label: 'Notification Preferences',
                                  onTap: () => _open(
                                    context,
                                    const NotificationPreferencesScreen(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 26),
                            _SectionLabel(label: 'MANAGE', body: _body),
                            const SizedBox(height: 10),
                            _SettingsGroup(
                              children: [
                                _SettingsRow(
                                  icon: Icons.badge_outlined,
                                  label: 'Profile',
                                  onTap: () =>
                                      _open(context, const ProfileScreen()),
                                ),
                                _SettingsRow(
                                  icon: Icons.account_circle_outlined,
                                  label: 'Account Data',
                                  onTap: () => _open(
                                    context,
                                    AccountDataScreen(
                                      name: name,
                                      email: email,
                                    ),
                                  ),
                                ),
                                _SettingsRow(
                                  icon: Icons.crop_square_rounded,
                                  label: 'App Icons',
                                  onTap: () => _open(
                                    context,
                                    const AppIconScreen(),
                                  ),
                                ),
                                _SettingsRow(
                                  icon: Icons.format_paint_outlined,
                                  label: 'App Theme',
                                  trailing: Icons.unfold_more_rounded,
                                  onTap: () => _pickTheme(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 26),
                            _SectionLabel(label: 'HELP CENTER', body: _body),
                            const SizedBox(height: 10),
                            _SettingsGroup(
                              children: [
                                _SettingsRow(
                                  icon: Icons.help_outline_rounded,
                                  label: 'FAQ',
                                  onTap: () =>
                                      _open(context, const FaqHubScreen()),
                                ),
                                _SettingsRow(
                                  icon: Icons.campaign_outlined,
                                  label: 'Contact Support',
                                  onTap: () =>
                                      _open(context, const ContactScreen()),
                                ),
                              ],
                            ),
                            const SizedBox(height: 26),
                            _SectionLabel(label: 'MORE', body: _body),
                            const SizedBox(height: 10),
                            _SettingsGroup(
                              children: [
                                _SettingsRow(
                                  icon: Icons.flight_rounded,
                                  label: 'About',
                                  onTap: () =>
                                      _open(context, const AboutScreen()),
                                ),
                                _SettingsRow(
                                  icon: Icons.logout_rounded,
                                  label: 'Sign out',
                                  onTap: () async {
                                    HapticFeedback.selectionClick();
                                    await AuthService.signOut();
                                    if (!context.mounted) return;
                                    Navigator.of(context).pushAndRemoveUntil(
                                      premiumRoute(const WelcomeScreen()),
                                      (_) => false,
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 36),
                            Center(
                              child: Text(
                                '© 2026 Bitachon Enterprise. All rights reserved.',
                                style: _body(size: 10.5, color: _muted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const AppBottomNavSpacer(),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AppBottomNav(currentIndex: AppNavIndex.settings),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.body});

  final String label;
  final TextStyle Function({
    required double size,
    FontWeight weight,
    Color color,
    double height,
  }) body;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: body(
        size: 10.5,
        weight: FontWeight.w500,
        color: const Color(0xFF8E8E93),
        height: 1.2,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 52,
                color: Color(0xFF2C2C2E),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing = Icons.chevron_right_rounded,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final IconData trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF8E8E93), size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
              Icon(trailing, color: const Color(0xFF8E8E93), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloseChip extends StatelessWidget {
  const _CloseChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2A2A2A),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Icon(Icons.close, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
