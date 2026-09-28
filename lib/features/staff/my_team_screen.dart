import 'package:flutter/material.dart';

import '../../core/data/berp_org.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/pattern_page.dart';

class MyTeamScreen extends StatefulWidget {
  const MyTeamScreen({super.key});

  @override
  State<MyTeamScreen> createState() => _MyTeamScreenState();
}

class _MyTeamScreenState extends State<MyTeamScreen> {
  List<OrgPerson> _team = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final team = await BerpOrg.team();
    if (!mounted) return;
    setState(() => _team = team);
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Home > Team',
      title: 'My team',
      subtitle: '${_team.length} ASSIGNED',
      bottom: const AppBottomNav(currentIndex: 1),
      child: _team.isEmpty
          ? Text(
              'No one is assigned to you yet. An admin sets this from the staff directory.',
              style: PatternPage.body(size: 13, color: PatternPage.muted, height: 1.4),
            )
          : PatternGroup(
              children: [
                for (final person in _team)
                  PatternListRow(
                    title: person.name.isEmpty ? person.email : person.name,
                    subtitle: [
                      if (person.jobTitle.isNotEmpty) person.jobTitle,
                      if (person.department.isNotEmpty) person.department,
                      if (person.company.isNotEmpty) person.company,
                    ].join('  ·  '),
                    trailing: const SizedBox.shrink(),
                    onTap: () {},
                  ),
              ],
            ),
    );
  }
}
