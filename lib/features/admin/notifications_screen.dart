import 'package:flutter/material.dart';

import '../../core/data/berp_org.dart';
import '../../core/data/staff_store.dart';
import '../../core/widgets/pattern_page.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotice> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await BerpOrg.notifications();
    if (!mounted) return;
    setState(() => _items = items);
  }

  Future<void> _open(AppNotice item) async {
    if (!item.isRead) await BerpOrg.markNoticeRead(item.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Home > Notifications',
      title: 'Notifications',
      subtitle: 'LEAVE, HANDOVER, APPRAISALS',
      child: _items.isEmpty
          ? Text(
              'No notifications yet.',
              style: PatternPage.body(size: 13, color: PatternPage.muted),
            )
          : PatternGroup(
              children: [
                for (final item in _items)
                  PatternListRow(
                    title: item.title,
                    subtitle:
                        '${item.message}  ·  ${formatTimeAgo(item.createdAt)}',
                    leading: Icon(
                      item.isRead
                          ? Icons.notifications_none_rounded
                          : Icons.notifications_active_outlined,
                      color: item.isRead ? PatternPage.muted : PatternPage.blue,
                    ),
                    onTap: () => _open(item),
                  ),
              ],
            ),
    );
  }
}
