import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/settings/settings_screen.dart';
import '../../features/staff/leave_screen.dart';
import '../../features/staff/schedule_screen.dart';
import '../../features/staff/updates_screen.dart';
import '../theme/app_colors.dart';
import 'premium_ui.dart';

/// Bottom navigation tab indices.
abstract final class AppNavIndex {
  static const home = 0;
  static const schedule = 1;
  static const leave = 2;
  static const notices = 3;
  static const settings = 4;

  static const updates = notices;
  static const book = leave;
  static const portal = notices;
  static const activities = notices;

  /// Opened from the home card, not a tab.
  static const appraisals = -1;
}

class AppNavDestination {
  const AppNavDestination(this.icon, this.activeIcon, this.label);

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

const appNavDestinations = <AppNavDestination>[
  AppNavDestination(Icons.home_outlined, Icons.home_rounded, 'Home'),
  AppNavDestination(
    Icons.calendar_month_outlined,
    Icons.calendar_month_rounded,
    'Schedule',
  ),
  AppNavDestination(Icons.edit_note_outlined, Icons.edit_note_rounded, 'Leave'),
  AppNavDestination(
    Icons.notifications_none_rounded,
    Icons.notifications_rounded,
    'Notices',
  ),
  AppNavDestination(
    Icons.settings_outlined,
    Icons.settings_rounded,
    'Settings',
  ),
];

/// Shared minimize state so spacers / page padding can react.
final ValueNotifier<bool> appNavMinimized = ValueNotifier(false);

/// Navigates between main app sections. [current] is the tab index of the
/// screen calling this (home = 0).
void navigateAppTab(
  BuildContext context, {
  required int target,
  required int current,
}) {
  if (target == current) return;
  HapticFeedback.selectionClick();

  final navigator = Navigator.of(context);
  if (target == AppNavIndex.home) {
    navigator.popUntil((route) => route.isFirst);
    return;
  }

  final page = switch (target) {
    AppNavIndex.schedule => const ScheduleScreen(),
    AppNavIndex.leave => const LeaveScreen(),
    AppNavIndex.notices => const UpdatesScreen(),
    AppNavIndex.settings => const SettingsScreen(),
    _ => throw ArgumentError('Unknown tab index: $target'),
  };

  if (current == AppNavIndex.home) {
    navigator.push(premiumRoute(page));
  } else {
    navigator.pushReplacement(premiumRoute(page));
  }
}

/// Icon + label bottom nav with frosted glass tray. Can minimize to a handle.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const expandedHeight = 86.0;
  static const collapsedHeight = 36.0;
  static const _outerBottomPad = 8.0;

  static double barHeight({bool? minimized}) {
    final min = minimized ?? appNavMinimized.value;
    return (min ? collapsedHeight : expandedHeight) + _outerBottomPad;
  }

  static double totalHeight(BuildContext context, {bool? minimized}) =>
      barHeight(minimized: minimized) + MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ValueListenableBuilder<bool>(
      valueListenable: appNavMinimized,
      builder: (context, minimized, _) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.fromLTRB(12, 0, 12, _outerBottomPad + bottom),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: minimized
                ? _MinimizedHandle(
                    onExpand: () {
                      HapticFeedback.selectionClick();
                      appNavMinimized.value = false;
                    },
                  )
                : _ExpandedNav(
                    currentIndex: currentIndex,
                    onMinimize: () {
                      HapticFeedback.selectionClick();
                      appNavMinimized.value = true;
                    },
                  ),
          ),
        );
      },
    );
  }
}

/// Spacer that shrinks when the nav is minimized.
class AppBottomNavSpacer extends StatelessWidget {
  const AppBottomNavSpacer({super.key, this.extra = 0});

  final double extra;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appNavMinimized,
      builder: (context, minimized, _) {
        return SizedBox(
          height:
              AppBottomNav.totalHeight(context, minimized: minimized) + extra,
        );
      },
    );
  }
}

class _GlassShell extends StatelessWidget {
  const _GlassShell({
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.fromLTRB(6, 6, 6, 8),
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.blackElevated.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _MinimizedHandle extends StatelessWidget {
  const _MinimizedHandle({required this.onExpand});

  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onExpand,
          borderRadius: BorderRadius.circular(20),
          child: _GlassShell(
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandedNav extends StatelessWidget {
  const _ExpandedNav({required this.currentIndex, required this.onMinimize});

  final int currentIndex;
  final VoidCallback onMinimize;

  @override
  Widget build(BuildContext context) {
    return _GlassShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onMinimize,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < appNavDestinations.length; i++)
                Expanded(
                  child: _NavTab(
                    destination: appNavDestinations[i],
                    selected: currentIndex == i,
                    onTap: () => navigateAppTab(
                      context,
                      target: i,
                      current: currentIndex,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.secondary : AppColors.muted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? destination.activeIcon : destination.icon,
                size: 22,
                color: color,
              ),
              const SizedBox(height: 4),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Panchang',
                  fontSize: 8,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                  height: 1.1,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
