import 'package:flutter/material.dart';

import '../../core/notifications/clock_reminders.dart';
import '../../core/widgets/pattern_page.dart';
import '../../core/widgets/premium_ui.dart';
import 'resource_detail_screen.dart';

class AppIconOption {
  const AppIconOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<Color> colors;
}

const kAppIconOptions = <AppIconOption>[
  AppIconOption(
    id: 'aero_deluxe',
    title: 'AERO Deluxe',
    subtitle: 'Deluxe icon to strike balance',
    colors: [Color(0xFF1F2D90), Color(0xFF1E90FF)],
  ),
  AppIconOption(
    id: 'maito',
    title: 'Maito',
    subtitle: 'Blink Blink',
    colors: [Color(0xFF0D1B3A), Color(0xFF16305C)],
  ),
  AppIconOption(
    id: 'super_glass',
    title: 'Super Glass',
    subtitle: 'Pure liquid glass',
    colors: [Color(0xFF2A2A2C), Color(0xFF3A3A3E)],
  ),
];

class AppIconScreen extends StatefulWidget {
  const AppIconScreen({super.key, this.initialId = 'aero_deluxe'});

  final String initialId;

  @override
  State<AppIconScreen> createState() => _AppIconScreenState();
}

class _AppIconScreenState extends State<AppIconScreen> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialId;
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Settings > App Icon',
      title: 'App Icon',
      subtitle: 'CHOOSE YOUR APP ICON',
      child: PatternGroup(
        children: [
          for (final option in kAppIconOptions)
            PatternListRow(
              title: option.title,
              subtitle: option.subtitle,
              selected: _selected == option.id,
              leading: _IconPreview(colors: option.colors),
              onTap: () => setState(() => _selected = option.id),
            ),
        ],
      ),
    );
  }
}

class _IconPreview extends StatelessWidget {
  const _IconPreview({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: const Icon(Icons.flight_rounded, color: Colors.white, size: 22),
    );
  }
}

class FaqHubScreen extends StatelessWidget {
  const FaqHubScreen({super.key});

  static const _booking = <(String, String)>[
    (
      'Book a charter',
      'Contact our Ground Desk with your route, dates, and passenger details. '
          'We match aircraft, coordinate handling, and confirm your mission.',
    ),
    (
      'Charter pricing',
      'Charter pricing depends on aircraft type, routing, positioning, and '
          'ground requirements. Speak with our team for a mission-specific quotation.',
    ),
    (
      'Passenger details',
      'Share passenger count, cabin preferences, and any special requests early '
          'so we can confirm the right aircraft and ground setup.',
    ),
    (
      'Trip changes',
      'Schedule changes are coordinated through the Ground Desk. Availability '
          'depends on aircraft positioning and crew duty limits.',
    ),
  ];

  static const _top = <(String, String)>[
    (
      'What services we provide',
      'We oversee every detail of private jet ownership and charter — from '
          'flight and ground operations to maintenance oversight, crew '
          'coordination, and regulatory compliance.',
    ),
    (
      'Can\'t find a flight',
      'If a preferred aircraft or route is unavailable, our team sources '
          'alternatives across broker networks and owner-direct options.',
    ),
    (
      'Management fit',
      'If you want a single accountable partner for operations, maintenance, '
          'compliance, and reporting — instead of a patchwork of vendors — '
          'management is designed for you.',
    ),
  ];

  void _open(BuildContext context, String title, String body) {
    Navigator.of(context).push(
      premiumRoute(
        ResourceDetailScreen(
          breadcrumb: 'Settings > FAQ',
          title: title,
          sections: [ResourceSection(heading: title, body: body)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Settings > FAQ',
      title: 'FAQ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PatternSectionLabel('Booking a flight'),
          const SizedBox(height: 8),
          PatternGroup(
            children: [
              for (final item in _booking)
                PatternListRow(
                  title: item.$1,
                  onTap: () => _open(context, item.$1, item.$2),
                ),
            ],
          ),
          const SizedBox(height: 28),
          const PatternSectionLabel('Top questions'),
          const SizedBox(height: 8),
          PatternGroup(
            children: [
              for (final item in _top)
                PatternListRow(
                  title: item.$1,
                  onTap: () => _open(context, item.$1, item.$2),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _clockReminders = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await ClockReminderNotifications.isEnabled();
    if (!mounted) return;
    setState(() {
      _clockReminders = enabled;
      _loading = false;
    });
  }

  Future<void> _setClockReminders(bool value) async {
    setState(() => _clockReminders = value);
    await ClockReminderNotifications.setEnabled(value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Clock reminders on (8:30, 8:45, 8:55, 9:00 Lagos, Mon–Fri)'
              : 'Clock reminders turned off',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Settings > Notification Preferences',
      title: 'Notifications',
      subtitle: 'ALERT PREFERENCES',
      child: _loading
          ? const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: CircularProgressIndicator(color: PatternPage.blue),
              ),
            )
          : PatternGroup(
              children: [
                _ToggleRow(
                  title: 'Clock-in reminders',
                  subtitle:
                      '8:30 · 8:45 · 8:55 · 9:00am Lagos (Mon–Fri). Arrive on time and clock in before HR calls.',
                  value: _clockReminders,
                  onChanged: _setClockReminders,
                ),
              ],
            ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PatternPage.body(size: 14, weight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: PatternPage.body(size: 11.5, color: PatternPage.muted),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: PatternPage.blue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class AccountDataScreen extends StatelessWidget {
  const AccountDataScreen({super.key, required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Settings > Account Data',
      title: 'Account Data',
      subtitle: 'SIGNED-IN PROFILE',
      child: PatternGroup(
        children: [
          PatternListRow(
            title: 'Name',
            subtitle: name,
            trailing: const SizedBox.shrink(),
            onTap: () {},
          ),
          PatternListRow(
            title: 'Email',
            subtitle: email,
            trailing: const SizedBox.shrink(),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
