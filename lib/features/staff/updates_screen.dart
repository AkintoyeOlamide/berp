import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/auth/staff_access.dart';
import '../../core/data/staff_store.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/pattern_page.dart';
import '../admin/notifications_screen.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  List<StaffUpdate> _items = [];
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _composing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await StaffStore.instance.updates();
    if (!mounted) return;
    setState(() => _items = items);
  }

  bool get _canPost => StaffAccess.role.value.isOrgAdmin;

  int get _navIndex {
    final role = StaffAccess.role.value;
    if (role == BerpRole.manager || role.isOrgAdmin) return 4;
    return AppNavIndex.notices;
  }

  Future<void> _post() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a title and a short update.')),
      );
      return;
    }
    HapticFeedback.selectionClick();
    try {
      await StaffStore.instance.postUpdate(title: title, body: body);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
      return;
    }
    _title.clear();
    _body.clear();
    setState(() => _composing = false);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Home > Updates',
      title: 'Staff updates',
      subtitle: 'TEAM BOARD',
      bottom: AppBottomNav(currentIndex: _navIndex),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              child: Text(
                'Notifications',
                style: PatternPage.body(size: 13, color: PatternPage.blue),
              ),
            ),
          ),
          if (_canPost)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _composing = !_composing),
              icon: Icon(
                _composing ? Icons.close_rounded : Icons.edit_outlined,
                color: PatternPage.blue,
              ),
              label: Text(
                _composing ? 'Cancel' : 'Share an update',
                style: PatternPage.body(
                  size: 13,
                  weight: FontWeight.w500,
                  color: PatternPage.blue,
                ),
              ),
            ),
          ),
          if (_composing) ...[
            TextField(
              controller: _title,
              style: PatternPage.body(size: 13),
              cursorColor: PatternPage.blue,
              decoration: _field('Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _body,
              maxLines: 4,
              style: PatternPage.body(size: 13),
              cursorColor: PatternPage.blue,
              decoration: _field('What should the team know?'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: _post,
                style: FilledButton.styleFrom(
                  backgroundColor: PatternPage.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Post to the team',
                  style: PatternPage.panchang(size: 11, weight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],
          const PatternSectionLabel('From other staff'),
          const SizedBox(height: 10),
          if (_items.isEmpty)
            Text(
              'No notices yet.',
              style: PatternPage.body(size: 13, color: PatternPage.muted),
            ),
          for (final item in _items) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: PatternPage.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.author}  ·  ${item.role}',
                    style: PatternPage.body(
                      size: 11,
                      color: PatternPage.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDay(item.at),
                    style: PatternPage.body(
                      size: 10.5,
                      color: PatternPage.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: PatternPage.panchang(size: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: PatternPage.body(
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _field(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: PatternPage.body(size: 13, color: PatternPage.muted),
      filled: true,
      fillColor: const Color(0xFF121212),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PatternPage.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PatternPage.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: PatternPage.blue),
      ),
    );
  }
}
