import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/premium_ui.dart';
import 'cloud_hop/cloud_hop_screen.dart';
import 'jet_dodge/jet_dodge_screen.dart';
import 'runway_memory/runway_memory_screen.dart';
import 'sky_strike/sky_strike_screen.dart';
import 'tower_call/tower_call_screen.dart';
import '../guest_player.dart';
import '../instructions.dart';

class GameOption {
  const GameOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.builder,
    required this.instructions,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final WidgetBuilder builder;
  final String instructions;
}

final List<GameOption> kGameOptions = [
  GameOption(
    id: 'sky_strike',
    title: 'Sky Strike',
    subtitle: 'Pilot your jet, dodge hostiles, and clear the sky.',
    icon: Icons.flight_rounded,
    accent: const Color(0xFF4D78FF),
    builder: (_) => const SkyStrikeScreen(),
    instructions: kGameInstructions['sky_strike']!,
  ),
  GameOption(
    id: 'jet_dodge',
    title: 'Jet Dodge',
    subtitle: 'Weave through clouds and obstacles at altitude.',
    icon: Icons.speed_rounded,
    accent: const Color(0xFF3DBF9A),
    builder: (_) => const JetDodgeScreen(),
    instructions: kGameInstructions['jet_dodge']!,
  ),
  GameOption(
    id: 'cloud_hop',
    title: 'Cloud Hop',
    subtitle: 'Tap to climb and thread the weather gaps.',
    icon: Icons.cloud_rounded,
    accent: const Color(0xFF8B7CF6),
    builder: (_) => const CloudHopScreen(),
    instructions: kGameInstructions['cloud_hop']!,
  ),
  GameOption(
    id: 'runway_memory',
    title: 'Runway Memory',
    subtitle: 'Match aviation cards in the fewest moves.',
    icon: Icons.grid_view_rounded,
    accent: const Color(0xFFC9A227),
    builder: (_) => const RunwayMemoryScreen(),
    instructions: kGameInstructions['runway_memory']!,
  ),
  GameOption(
    id: 'tower_call',
    title: 'Tower Call',
    subtitle: 'Repeat the ATC colour sequence under pressure.',
    icon: Icons.cell_tower_rounded,
    accent: const Color(0xFFFF6B6B),
    builder: (_) => const TowerCallScreen(),
    instructions: kGameInstructions['tower_call']!,
  ),
];

class GamesHubPanel extends StatelessWidget {
  const GamesHubPanel({super.key});

  Future<void> _open(BuildContext context, GameOption game) async {
    final ok = await ensurePlayerName(context);
    if (!ok || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: game.builder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    final p = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pick a cabin game',
          style: GoogleFonts.sora(color: p.body, fontSize: 13),
        ),
        SizedBox(height: r.scale(16)),
        ...kGameOptions.map((game) {
          return Padding(
            padding: EdgeInsets.only(bottom: r.scale(14)),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _open(context, game),
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  width: double.infinity,
                  padding: EdgeInsets.all(r.scale(18)),
                  decoration: premiumCardDecoration(context),
                  child: Row(
                    children: [
                      Container(
                        width: r.scale(52),
                        height: r.scale(52),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: game.accent.withValues(alpha: 0.18),
                          border: Border.all(
                            color: game.accent.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(game.icon, color: game.accent, size: 26),
                      ),
                      SizedBox(width: r.scale(14)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    game.title,
                                    style: GoogleFonts.sora(
                                      color: p.title,
                                      fontSize: r.font(16),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                InstructionsButton(
                                  title: game.title,
                                  body: game.instructions,
                                  compact: true,
                                  color: game.accent,
                                ),
                              ],
                            ),
                            SizedBox(height: r.scale(4)),
                            Text(
                              game.subtitle,
                              style: GoogleFonts.sora(
                                color: p.body,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: r.scale(8)),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.brandBlueSoft,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
