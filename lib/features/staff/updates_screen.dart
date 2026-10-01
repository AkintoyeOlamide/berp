import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/auth/auth_service.dart';
import '../../core/auth/staff_access.dart';
import '../../core/data/staff_store.dart';
import '../../core/notifications/push_inbox.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/pattern_page.dart';
import '../admin/notifications_screen.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key, this.asTab = false});

  /// When true, uses the Super Admin / Admin feed tab index.
  final bool asTab;

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  List<StaffUpdate> _items = [];
  FeedStats _stats = const FeedStats(
    posts: 0,
    reactions: 0,
    comments: 0,
    thisWeek: 0,
  );
  final _title = TextEditingController();
  final _body = TextEditingController();
  final Map<String, TextEditingController> _commentCtrls = {};
  bool _composing = false;
  bool _sendPush = true;
  bool _loading = true;
  String? _expandedId;
  bool _posting = false;

  static const _reactionMeta = <String, (String, IconData)>{
    'like': ('Like', Icons.thumb_up_alt_outlined),
    'love': ('Love', Icons.favorite_border_rounded),
    'clap': ('Clap', Icons.front_hand_outlined),
    'insight': ('Insight', Icons.lightbulb_outline_rounded),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    for (final ctrl in _commentCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  bool get _isAdmin => StaffAccess.role.value.isOrgAdmin;

  int get _navIndex {
    final role = StaffAccess.role.value;
    if (widget.asTab && role.isSuperAdmin) return 3;
    if (role == BerpRole.manager || role.isOrgAdmin) return 4;
    return AppNavIndex.notices;
  }

  TextEditingController _commentCtrl(String id) {
    return _commentCtrls.putIfAbsent(id, TextEditingController.new);
  }

  Future<void> _load() async {
    final items = await StaffStore.instance.updates();
    FeedStats stats = _stats;
    if (_isAdmin) {
      try {
        stats = await StaffStore.instance.feedStats();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _items = items;
      _stats = stats;
      _loading = false;
    });
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
    setState(() => _posting = true);
    HapticFeedback.selectionClick();
    try {
      await StaffStore.instance.postUpdate(
        title: title,
        body: body,
        sendPush: _sendPush,
      );
      if (_sendPush) {
        await PushInbox.sync();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
      setState(() => _posting = false);
      return;
    }
    _title.clear();
    _body.clear();
    if (!mounted) return;
    setState(() {
      _composing = false;
      _posting = false;
    });
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _sendPush
              ? 'Update posted and push scheduled.'
              : 'Update posted to the feed.',
        ),
      ),
    );
  }

  Future<void> _react(StaffUpdate item, String reaction) async {
    HapticFeedback.selectionClick();
    final next = item.myReaction == reaction ? null : reaction;
    await StaffStore.instance.reactToUpdate(item.id, next);
    await _load();
  }

  Future<void> _comment(StaffUpdate item) async {
    final ctrl = _commentCtrl(item.id);
    final text = ctrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();
    final saved = await StaffStore.instance.commentOnUpdate(
      updateId: item.id,
      body: text,
    );
    if (saved == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not post comment. Try again.')),
      );
      return;
    }
    ctrl.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser?.id;
    final engaged = [
      for (final item in _items)
        if (item.myReaction != null ||
            (uid != null &&
                item.comments.any((comment) => comment.userId == uid)))
          item,
    ];

    return PatternPage(
      breadcrumb: _isAdmin ? 'Dashboard > Feed' : 'Home > Feed',
      title: 'Feed',
      subtitle: _isAdmin ? 'UPDATES · STATS · PUSH' : 'TEAM UPDATES',
      bottom: AppBottomNav(currentIndex: _navIndex),
      actions: [
        Material(
          color: const Color(0xFF1A1A1A),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isAdmin) ...[
            Row(
              children: [
                Expanded(
                  child: _StatPill(
                    value: '${_stats.posts}',
                    label: 'Posts',
                    accent: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    value: '${_stats.thisWeek}',
                    label: 'This week',
                    accent: const Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    value: '${_stats.reactions}',
                    label: 'Reactions',
                    accent: const Color(0xFFF97316),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    value: '${_stats.comments}',
                    label: 'Comments',
                    accent: const Color(0xFFA855F7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: () => setState(() => _composing = !_composing),
                icon: Icon(
                  _composing ? Icons.close_rounded : Icons.campaign_outlined,
                  size: 18,
                ),
                label: Text(
                  _composing ? 'Close composer' : 'Post update',
                  style: PatternPage.body(size: 13, weight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: PatternPage.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            if (_composing) ...[
              const SizedBox(height: 14),
              _Composer(
                title: _title,
                body: _body,
                sendPush: _sendPush,
                posting: _posting,
                onTogglePush: (value) => setState(() => _sendPush = value),
                onPost: _post,
              ),
            ],
            const SizedBox(height: 22),
          ],
          if (!_isAdmin && engaged.isNotEmpty) ...[
            Text(
              'Your activity',
              style: PatternPage.body(size: 13, weight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              '${engaged.length} update${engaged.length == 1 ? '' : 's'} you reacted to or commented on',
              style: PatternPage.body(size: 12, color: PatternPage.muted),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  'Latest',
                  style: PatternPage.body(size: 13, weight: FontWeight.w600),
                ),
              ),
              Text(
                _loading
                    ? 'Loading…'
                    : '${_items.length} update${_items.length == 1 ? '' : 's'}',
                style: PatternPage.body(size: 12, color: PatternPage.muted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: PatternPage.row,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: PatternPage.divider),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.forum_outlined,
                    color: PatternPage.muted,
                    size: 28,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isAdmin
                        ? 'No updates yet. Share the first one with the team.'
                        : 'No updates yet. Admins will post here.',
                    textAlign: TextAlign.center,
                    style: PatternPage.body(
                      size: 13,
                      color: PatternPage.muted,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final item in _items) ...[
              _FeedCard(
                item: item,
                expanded: _expandedId == item.id,
                reactionMeta: _reactionMeta,
                commentCtrl: _commentCtrl(item.id),
                onToggle: () => setState(() {
                  _expandedId = _expandedId == item.id ? null : item.id;
                }),
                onReact: (reaction) => _react(item, reaction),
                onComment: () => _comment(item),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: PatternPage.row,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PatternPage.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: PatternPage.body(
              size: 18,
              weight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PatternPage.body(size: 10, color: PatternPage.muted),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.title,
    required this.body,
    required this.sendPush,
    required this.posting,
    required this.onTogglePush,
    required this.onPost,
  });

  final TextEditingController title;
  final TextEditingController body;
  final bool sendPush;
  final bool posting;
  final ValueChanged<bool> onTogglePush;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PatternPage.row,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PatternPage.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New update',
            style: PatternPage.body(size: 13, weight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: title,
            style: PatternPage.body(size: 13),
            cursorColor: PatternPage.blue,
            decoration: _field('Title'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: body,
            maxLines: 4,
            style: PatternPage.body(size: 13),
            cursorColor: PatternPage.blue,
            decoration: _field('What should the team know?'),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: sendPush,
            activeThumbColor: PatternPage.blue,
            onChanged: posting ? null : onTogglePush,
            title: Text(
              'Send push notification',
              style: PatternPage.body(size: 13, weight: FontWeight.w500),
            ),
            subtitle: Text(
              'Staff devices will receive this update.',
              style: PatternPage.body(size: 11, color: PatternPage.muted),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: posting ? null : onPost,
              style: FilledButton.styleFrom(
                backgroundColor: PatternPage.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                posting ? 'Posting…' : 'Publish to feed',
                style: PatternPage.panchang(size: 11, weight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _field(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: PatternPage.body(size: 13, color: PatternPage.muted),
      filled: true,
      fillColor: const Color(0xFF0E0E0E),
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

class _FeedCard extends StatelessWidget {
  const _FeedCard({
    required this.item,
    required this.expanded,
    required this.reactionMeta,
    required this.commentCtrl,
    required this.onToggle,
    required this.onReact,
    required this.onComment,
  });

  final StaffUpdate item;
  final bool expanded;
  final Map<String, (String, IconData)> reactionMeta;
  final TextEditingController commentCtrl;
  final VoidCallback onToggle;
  final ValueChanged<String> onReact;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(item.author);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: PatternPage.row,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PatternPage.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: PatternPage.blue,
                child: Text(
                  initials,
                  style: PatternPage.body(size: 12, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.author.isEmpty ? 'Admin' : item.author,
                      style: PatternPage.body(
                        size: 13,
                        weight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      [
                        if (item.role.isNotEmpty) item.role,
                        formatTimeAgo(item.at),
                      ].join('  ·  '),
                      style: PatternPage.body(
                        size: 11,
                        color: PatternPage.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.title,
            style: PatternPage.panchang(size: 16, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            item.body,
            style: PatternPage.body(
              size: 13,
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final entry in reactionMeta.entries)
                _ReactionChip(
                  icon: entry.value.$2,
                  count: item.reactions[entry.key] ?? 0,
                  selected: item.myReaction == entry.key,
                  onTap: () => onReact(entry.key),
                ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.chat_bubble_outline_rounded,
                    size: 16,
                    color: PatternPage.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.commentCount == 0
                        ? 'Add a comment'
                        : '${item.commentCount} comment${item.commentCount == 1 ? '' : 's'}',
                    style: PatternPage.body(
                      size: 12,
                      weight: FontWeight.w500,
                      color: PatternPage.muted,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: PatternPage.muted,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 10),
            if (item.comments.isEmpty)
              Text(
                'Be the first to comment.',
                style: PatternPage.body(size: 12, color: PatternPage.muted),
              )
            else
              for (final comment in item.comments) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E0E0E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${comment.author.isEmpty ? 'Staff' : comment.author}  ·  ${formatTimeAgo(comment.at)}',
                        style: PatternPage.body(
                          size: 11,
                          color: PatternPage.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.body,
                        style: PatternPage.body(size: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentCtrl,
                    style: PatternPage.body(size: 13),
                    cursorColor: PatternPage.blue,
                    decoration: InputDecoration(
                      hintText: 'Write a comment…',
                      hintStyle: PatternPage.body(
                        size: 12,
                        color: PatternPage.muted,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0E0E0E),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
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
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: PatternPage.blue,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onComment,
                    borderRadius: BorderRadius.circular(12),
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? PatternPage.blue.withValues(alpha: 0.18)
          : const Color(0xFF0E0E0E),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? PatternPage.blue : PatternPage.muted,
              ),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: PatternPage.body(
                    size: 11,
                    weight: FontWeight.w600,
                    color: selected ? PatternPage.blue : PatternPage.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
