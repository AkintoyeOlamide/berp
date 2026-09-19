import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/app_content.dart';
import '../../core/data/leaderboard_service.dart';
import '../../core/data/local_store.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/pattern_page.dart';
import '../../core/widgets/premium_ui.dart';
import '../catering/catering_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../news/aviation_news_screen.dart';
import '../safety/safety_tips_screen.dart';
import 'activities_panel.dart';
import 'games/games_hub.dart';
import 'guest_player.dart';
import 'instructions.dart';

class EntertainmentScreen extends StatefulWidget {
  const EntertainmentScreen({super.key});

  @override
  State<EntertainmentScreen> createState() => _EntertainmentScreenState();
}

class _EntertainmentScreenState extends State<EntertainmentScreen> {
  Set<String> _badges = {};
  int _best = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await LeaderboardService.loadGuestName();
    final badges = await LocalStore.instance.unlockedBadges();
    final best = await LocalStore.instance.bestQuizScore();
    if (!mounted) return;
    setState(() {
      _badges = badges;
      _best = best;
    });
  }

  void _open(Widget page) {
    Navigator.of(context).push(premiumRoute(page));
  }

  Future<void> _openGame(GameOption game) async {
    final ok = await ensurePlayerName(context);
    if (!ok || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: game.builder),
    );
  }

  Future<void> _openQuiz() async {
    final ok = await ensurePlayerName(context);
    if (!ok || !mounted) return;
    _open(
      _EntertainmentSubpage(
        title: 'Quiz',
        titleSize: 18,
        breadcrumb: 'Entertainment > Quiz',
        instructionsTitle: 'Quiz',
        instructionsBody: kCabinInstructions['quiz']!,
        child: _QuizPanel(onFinished: _load),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Home > Entertainment',
      title: 'Entertainment',
      titleSize: 18,
      subtitle: 'IN-FLIGHT',
      bottom: const AppBottomNav(currentIndex: AppNavIndex.activities),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PatternSectionLabel('Flight brief'),
          const SizedBox(height: 10),
          _HubGrid(
            tiles: [
              _HubItem(
                title: 'Aviation News',
                icon: Icons.newspaper_outlined,
                accent: const Color(0xFF4D78FF),
                instructions: kCabinInstructions['news']!,
                onTap: () => _open(const AviationNewsScreen()),
              ),
              _HubItem(
                title: 'Onboard Safety',
                icon: Icons.health_and_safety_outlined,
                accent: const Color(0xFF3DBF9A),
                instructions: kCabinInstructions['safety']!,
                onTap: () => _open(const SafetyTipsScreen()),
              ),
              _HubItem(
                title: 'Emergency Tips',
                icon: Icons.warning_amber_outlined,
                accent: const Color(0xFFFF6B6B),
                instructions: kCabinInstructions['emergency']!,
                onTap: () => _open(const SafetyTipsScreen(emergency: true)),
              ),
              _HubItem(
                title: 'Leaderboard',
                icon: Icons.emoji_events_outlined,
                accent: const Color(0xFFC9A227),
                instructions: kCabinInstructions['leaderboard']!,
                onTap: () => _open(const LeaderboardScreen()),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const PatternSectionLabel('Games'),
          const SizedBox(height: 10),
          _HubGrid(
            tiles: [
              for (final game in kGameOptions)
                _HubItem(
                  title: game.title,
                  icon: game.icon,
                  accent: game.accent,
                  instructions: game.instructions,
                  onTap: () => _openGame(game),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const PatternSectionLabel('Cabin'),
          const SizedBox(height: 10),
          _HubGrid(
            tiles: [
              _HubItem(
                title: 'Activities',
                icon: Icons.extension_outlined,
                accent: const Color(0xFF4D78FF),
                instructions: kCabinInstructions['activities']!,
                onTap: () => _open(
                  _EntertainmentSubpage(
                    title: 'Activities',
                    titleSize: 18,
                    breadcrumb: 'Entertainment > Activities',
                    instructionsTitle: 'Activities',
                    instructionsBody: kCabinInstructions['activities']!,
                    child: ActivitiesPanel(onActivityDone: _load),
                  ),
                ),
              ),
              _HubItem(
                title: 'Trivia',
                icon: Icons.lightbulb_outline,
                accent: const Color(0xFFC9A227),
                instructions: kCabinInstructions['trivia']!,
                onTap: () => _open(
                  _EntertainmentSubpage(
                    title: 'Trivia',
                    titleSize: 18,
                    breadcrumb: 'Entertainment > Trivia',
                    instructionsTitle: 'Trivia',
                    instructionsBody: kCabinInstructions['trivia']!,
                    child: Column(
                      children: [
                        for (final item in AppContent.trivia)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _TriviaCard(
                              item: item,
                              onOpen: () async {
                                await LocalStore.instance.markTriviaRead();
                                await _load();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              _HubItem(
                title: 'Quiz',
                icon: Icons.quiz_outlined,
                accent: const Color(0xFF3DBF9A),
                instructions: kCabinInstructions['quiz']!,
                onTap: _openQuiz,
              ),
              _HubItem(
                title: 'Badges',
                icon: Icons.workspace_premium_outlined,
                accent: const Color(0xFF8B7CF6),
                instructions: kCabinInstructions['badges']!,
                onTap: () => _open(
                  _EntertainmentSubpage(
                    title: 'Badges',
                    titleSize: 18,
                    breadcrumb: 'Entertainment > Badges',
                    instructionsTitle: 'Badges',
                    instructionsBody: kCabinInstructions['badges']!,
                    child: _BadgesPanel(unlocked: _badges, best: _best),
                  ),
                ),
              ),
              _HubItem(
                title: 'Catering',
                icon: Icons.restaurant_outlined,
                accent: const Color(0xFFFF6B6B),
                instructions: kCabinInstructions['catering']!,
                onTap: () => _open(const CateringScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntertainmentSubpage extends StatelessWidget {
  const _EntertainmentSubpage({
    required this.title,
    required this.breadcrumb,
    required this.child,
    this.titleSize = 18,
    this.instructionsTitle,
    this.instructionsBody,
  });

  final String title;
  final String breadcrumb;
  final Widget child;
  final double titleSize;
  final String? instructionsTitle;
  final String? instructionsBody;

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: breadcrumb,
      title: title,
      titleSize: titleSize,
      actions: instructionsTitle == null || instructionsBody == null
          ? null
          : [
              InstructionsButton(
                title: instructionsTitle!,
                body: instructionsBody!,
              ),
            ],
      child: child,
    );
  }
}

class _HubItem {
  const _HubItem({
    required this.title,
    required this.icon,
    required this.accent,
    required this.instructions,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final String instructions;
  final VoidCallback onTap;
}

class _HubGrid extends StatelessWidget {
  const _HubGrid({required this.tiles});

  final List<_HubItem> tiles;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.18,
      ),
      itemBuilder: (context, index) {
        final tile = tiles[index];
        return Material(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: tile.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: tile.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: tile.accent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Icon(tile.icon, color: tile.accent, size: 20),
                      ),
                      const Spacer(),
                      InstructionsButton(
                        title: tile.title,
                        body: tile.instructions,
                        compact: true,
                        color: tile.accent,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    tile.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: PatternPage.panchang(
                      size: 12,
                      weight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TriviaCard extends StatelessWidget {
  const _TriviaCard({required this.item, required this.onOpen});

  final TriviaItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(r.scale(18)),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.label.toUpperCase(),
              style: PatternPage.body(
                size: 10.5,
                weight: FontWeight.w500,
                color: PatternPage.muted,
              ),
            ),
            SizedBox(height: r.scale(8)),
            Text(
              item.body,
              style: PatternPage.body(
                size: 13.5,
                color: p.title,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizPanel extends StatefulWidget {
  const _QuizPanel({required this.onFinished});

  final Future<void> Function() onFinished;

  @override
  State<_QuizPanel> createState() => _QuizPanelState();
}

class _QuizPanelState extends State<_QuizPanel> {
  QuizPack? _pack;
  int _index = 0;
  int _score = 0;
  int? _selected;
  bool _done = false;

  List<QuizQuestion> get _qs => _pack?.questions ?? const [];

  void _answer(int option) {
    if (_selected != null || _pack == null) return;
    final q = _qs[_index];
    setState(() {
      _selected = option;
      if (option == q.correctIndex) _score++;
    });
  }

  Future<void> _next() async {
    if (_pack == null) return;
    if (_index >= _qs.length - 1) {
      await LocalStore.instance.recordQuizScore(_score, total: _qs.length);
      await widget.onFinished();
      if (!mounted) return;
      setState(() => _done = true);
      return;
    }
    setState(() {
      _index++;
      _selected = null;
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _score = 0;
      _selected = null;
      _done = false;
    });
  }

  void _pickPack(QuizPack pack) {
    setState(() {
      _pack = pack;
      _index = 0;
      _score = 0;
      _selected = null;
      _done = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    final p = AppPalette.of(context);

    if (_pack == null) {
      return PatternGroup(
        children: [
          for (final pack in AppContent.quizPacks)
            PatternListRow(
              title: pack.title,
              subtitle: '${pack.subtitle} · ${pack.questions.length} questions',
              onTap: () => _pickPack(pack),
            ),
        ],
      );
    }

    if (_done) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_pack!.title} complete',
            style: PatternPage.panchang(size: 18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            'You scored $_score / ${_qs.length}. Badges unlock offline and stay '
            'on this device.',
            style: PatternPage.body(
              size: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: _restart,
              style: FilledButton.styleFrom(
                backgroundColor: PatternPage.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Try again',
                style: PatternPage.panchang(size: 11),
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _pack = null),
            child: Text(
              'Choose another pack',
              style: PatternPage.body(size: 12.5, color: PatternPage.blue),
            ),
          ),
        ],
      );
    }

    final q = _qs[_index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_pack!.title} · ${_index + 1}/${_qs.length}',
          style: PatternPage.body(size: 11.5, color: PatternPage.muted),
        ),
        SizedBox(height: r.scale(10)),
        Text(
          q.prompt,
          style: PatternPage.panchang(size: 16, weight: FontWeight.w600),
        ),
        SizedBox(height: r.scale(16)),
        ...List.generate(q.options.length, (i) {
          final selected = _selected == i;
          final correct = i == q.correctIndex;
          Color border = PatternPage.divider;
          if (_selected != null) {
            if (correct) border = const Color(0xFF6BCB8A);
            if (selected && !correct) border = const Color(0xFFE8A0A0);
          }
          return Padding(
            padding: EdgeInsets.only(bottom: r.scale(10)),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _answer(i),
                borderRadius: BorderRadius.circular(12),
                child: Ink(
                  width: double.infinity,
                  padding: EdgeInsets.all(r.scale(14)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                    color: const Color(0xFF121212),
                  ),
                  child: Text(
                    q.options[i],
                    style: GoogleFonts.poppins(color: p.title, fontSize: 13.5),
                  ),
                ),
              ),
            ),
          );
        }),
        if (_selected != null) ...[
          SizedBox(height: r.scale(8)),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: _next,
              style: FilledButton.styleFrom(
                backgroundColor: PatternPage.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _index == _qs.length - 1 ? 'Finish' : 'Next',
                style: PatternPage.panchang(size: 11),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BadgesPanel extends StatelessWidget {
  const _BadgesPanel({required this.unlocked, required this.best});

  final Set<String> unlocked;
  final int best;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Best quiz score: $best · Badges unlocked: '
          '${unlocked.length} / ${AppContent.badges.length}',
          style: PatternPage.body(size: 12.5, color: PatternPage.muted),
        ),
        const SizedBox(height: 16),
        PatternGroup(
          children: [
            for (final b in AppContent.badges)
              PatternListRow(
                title: b.title,
                subtitle: b.subtitle,
                leading: Icon(
                  unlocked.contains(b.id)
                      ? Icons.workspace_premium_rounded
                      : Icons.lock_outline,
                  color: unlocked.contains(b.id)
                      ? AppColors.brandBlueSoft
                      : PatternPage.muted,
                ),
                trailing: const SizedBox.shrink(),
                onTap: () {},
              ),
          ],
        ),
      ],
    );
  }
}
