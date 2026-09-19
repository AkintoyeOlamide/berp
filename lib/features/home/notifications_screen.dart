import 'package:flutter/material.dart';

import '../../core/data/cabin_notifications.dart';
import '../../core/widgets/pattern_page.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static IconData _icon(String name) {
    return switch (name) {
      'restaurant' => Icons.restaurant_outlined,
      'airline' => Icons.airline_seat_recline_extra_outlined,
      _ => Icons.flight_takeoff_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Home > Alerts',
      title: 'Notifications',
      titleSize: 18,
      subtitle: 'TRIP · CATERING · BOARDING',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip changes, catering, and boarding calls for this mission.',
            style: PatternPage.body(
              size: 13,
              color: PatternPage.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          for (final notice in CabinNotice.items) ...[
            _NoticeCard(notice: notice, icon: _icon(notice.iconName)),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice, required this.icon});

  final CabinNotice notice;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = Color(notice.colorValue);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatternPage.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      notice.kind.toUpperCase(),
                      style: PatternPage.body(
                        size: 10,
                        weight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      notice.timeLabel,
                      style: PatternPage.body(
                        size: 10.5,
                        color: PatternPage.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notice.title,
                  style: PatternPage.panchang(
                    size: 14,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  notice.body,
                  style: PatternPage.body(
                    size: 12.5,
                    color: PatternPage.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
