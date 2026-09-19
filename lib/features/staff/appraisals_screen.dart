import 'package:flutter/material.dart';

import '../../core/data/staff_store.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/pattern_page.dart';

class AppraisalsScreen extends StatefulWidget {
  const AppraisalsScreen({super.key});

  @override
  State<AppraisalsScreen> createState() => _AppraisalsScreenState();
}

class _AppraisalsScreenState extends State<AppraisalsScreen> {
  List<AppraisalRecord> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await StaffStore.instance.appraisals();
    if (!mounted) return;
    setState(() => _items = items);
  }

  void _open(AppraisalRecord item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AppraisalDetailScreen(record: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Home > Appraisals',
      title: 'Appraisals',
      subtitle: 'PERFORMANCE',
      bottom: const AppBottomNav(currentIndex: AppNavIndex.appraisals),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your reviews with People and your line manager.',
            style: PatternPage.body(
              size: 13,
              color: PatternPage.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 22),
          PatternGroup(
            children: [
              for (final item in _items)
                PatternListRow(
                  title: item.title,
                  subtitle: item.completed
                      ? '${item.period}  ·  ${item.rating?.toStringAsFixed(1) ?? '—'} / 5'
                      : '${item.period}  ·  Upcoming',
                  leading: PatternDocIcon(
                    icon: item.completed
                        ? Icons.verified_outlined
                        : Icons.event_outlined,
                  ),
                  onTap: () => _open(item),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppraisalDetailScreen extends StatelessWidget {
  const _AppraisalDetailScreen({required this.record});

  final AppraisalRecord record;

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Appraisals > Detail',
      title: record.title,
      subtitle: record.period.toUpperCase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PatternGroup(
            children: [
              PatternListRow(
                title: 'Reviewer',
                subtitle: record.reviewer,
                trailing: const SizedBox.shrink(),
                onTap: () {},
              ),
              PatternListRow(
                title: 'Status',
                subtitle: record.completed ? 'Completed' : 'Upcoming',
                trailing: const SizedBox.shrink(),
                onTap: () {},
              ),
              if (record.rating != null)
                PatternListRow(
                  title: 'Rating',
                  subtitle: '${record.rating!.toStringAsFixed(1)} / 5',
                  trailing: const SizedBox.shrink(),
                  onTap: () {},
                ),
            ],
          ),
          const SizedBox(height: 22),
          const PatternSectionLabel('Notes'),
          const SizedBox(height: 10),
          Text(
            record.summary,
            style: PatternPage.body(
              size: 13.5,
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
