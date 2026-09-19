import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/pattern_page.dart';

void showActivityInstructions(
  BuildContext context, {
  required String title,
  required String body,
}) {
  HapticFeedback.selectionClick();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF121212),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      final bottomInset = MediaQuery.paddingOf(context).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(22, 12, 22, 20 + bottomInset + 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'How to play',
              style: PatternPage.body(
                size: 11,
                weight: FontWeight.w500,
                color: PatternPage.muted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: PatternPage.panchang(size: 18, weight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: PatternPage.body(
                size: 13.5,
                color: Colors.white.withValues(alpha: 0.86),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: PatternPage.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Got it',
                  style: PatternPage.panchang(size: 11),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class InstructionsButton extends StatelessWidget {
  const InstructionsButton({
    super.key,
    required this.title,
    required this.body,
    this.compact = false,
    this.color,
  });

  final String title;
  final String body;
  final bool compact;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Colors.white70;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showActivityInstructions(
          context,
          title: title,
          body: body,
        ),
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(compact ? 4 : 8),
          child: Icon(
            Icons.info_outline_rounded,
            size: compact ? 16 : 20,
            color: tint,
          ),
        ),
      ),
    );
  }
}

const kGameInstructions = <String, String>{
  'sky_strike':
      'Tap to launch. Drag left or right to steer your jet. It fires automatically. Dodge hostile aircraft, keep your three lives, and survive as many waves as you can. Pause from the top bar when you need a break.',
  'jet_dodge':
      'Tap to start, then drag left or right to weave between falling obstacles. Stay on screen and avoid collisions. Your score rises the longer you fly, and speed increases as you go.',
  'cloud_hop':
      'Tap to flap upward and keep tapping to stay airborne. Thread the gaps in the clouds — hitting a cloud bank or leaving the screen ends the hop. Time your taps so you pass each gap cleanly.',
  'runway_memory':
      'Flip two cards at a time and match aviation pairs. A mismatch turns them back over. Clear the whole board in as few moves as possible — your best clear is saved on this device.',
  'tower_call':
      'Watch the tower light a colour sequence, then tap Alpha–Delta in the same order. Each round adds one extra call. Wait until it is your turn. One wrong pad ends the transmission.',
};

const kCabinInstructions = <String, String>{
  'activities':
      'Cabin time has three things to do: unscramble aviation words, vote on short polls, and read flying tips. Open this page, pick a card, and follow the prompt on each activity.',
  'scramble':
      'Use the letter tiles to rebuild the aviation word. A hint sits above the blanks. Tap letters in order; a wrong word shuffles them back. A correct word unlocks the Wordsmith badge. Use New word for another puzzle.',
  'polls':
      'Read the cabin question and tap the option that fits you. Your vote is stored on this device and unlocks the Cabin Voice badge. Use Next poll to see another question.',
  'tips':
      'These are short in-flight tips — no scoring, just useful cabin guidance. Scroll the list and read whatever helps on this flight.',
  'trivia':
      'Each card is a short aviation insight. Tap a card to read it. Reading trivia is tracked on this device and can count toward badges.',
  'quiz':
      'Pick a quiz pack, then tap an answer for each question. After you choose, continue with Next (or Finish on the last question). Your best score is saved offline and can unlock badges.',
  'badges':
      'Badges unlock from quizzes, polls, scrambles, and games. A filled trophy means you earned it on this device. Locked items show what is still waiting.',
  'catering':
      'Browse cabin catering by category, add dishes to your cart, then review and place the order. Use filters to find meals, snacks, and drinks for your flight.',
  'news':
      'Live aviation headlines from Google News, Simple Flying, AvWeb, the FAA, and NASA Aeronautics. Pull down to refresh. Tap a story to open it in the browser.',
  'safety':
      'Onboard safety covers belts, exits, masks, and cabin habits before taxi. Follow crew briefings first — these cards are a reminder, not a replacement.',
  'emergency':
      'Emergency cards cover evacuation, smoke, ditching, slides, fire, and medical events. Leave bags, follow floor lights, and wait for the crew call before you move.',
  'leaderboard':
      'Ranks for cabin games and quizzes. Your best scores post under your account name. Switch games with the chips at the top.',
};
