import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/app_content.dart';
import '../../core/data/local_store.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/premium_ui.dart';
import 'instructions.dart';

class ActivitiesPanel extends StatelessWidget {
  const ActivitiesPanel({super.key, required this.onActivityDone});

  final Future<void> Function() onActivityDone;

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ScrambleCard(),
        SizedBox(height: r.scale(18)),
        _PollsCard(onVoted: onActivityDone),
        SizedBox(height: r.scale(18)),
        const _CabinTipsCard(),
      ],
    );
  }
}

class _ScrambleCard extends StatefulWidget {
  const _ScrambleCard();

  @override
  State<_ScrambleCard> createState() => _ScrambleCardState();
}

class _ScrambleCardState extends State<_ScrambleCard> {
  late CabinScramble _item;
  late List<String> _letters;
  final List<String> _guess = [];
  String? _message;

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _deal() {
    final list = AppContent.scrambles;
    _item = list[math.Random().nextInt(list.length)];
    _letters = _item.word.split('')..shuffle(math.Random());
    _guess.clear();
    _message = null;
  }

  void _tapLetter(int i) {
    if (_message == 'Cleared') return;
    setState(() {
      _guess.add(_letters.removeAt(i));
      if (_guess.length == _item.word.length) {
        final attempt = _guess.join();
        if (attempt == _item.word) {
          _message = 'Cleared';
          LocalStore.instance.unlockBadge('wordsmith');
        } else {
          _message = 'Try again';
          _letters.addAll(_guess);
          _letters.shuffle(math.Random());
          _guess.clear();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    final p = AppPalette.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(r.scale(18)),
      decoration: premiumCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'CABIN SCRAMBLE',
                  style: GoogleFonts.sora(
                    color: p.eyebrow,
                    fontSize: 11,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              InstructionsButton(
                title: 'Cabin Scramble',
                body: kCabinInstructions['scramble']!,
                compact: true,
                color: AppColors.brandBlueSoft,
              ),
            ],
          ),
          SizedBox(height: r.scale(6)),
          Text(
            _item.hint,
            style: GoogleFonts.sora(color: p.body, fontSize: 13),
          ),
          SizedBox(height: r.scale(14)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _item.word.length; i++)
                Container(
                  width: 34,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: p.hairline),
                    color: p.chipFill,
                  ),
                  child: Text(
                    i < _guess.length ? _guess[i] : '',
                    style: GoogleFonts.sora(
                      color: p.title,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: r.scale(14)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _letters.length; i++)
                GestureDetector(
                  onTap: () => _tapLetter(i),
                  child: Container(
                    width: 40,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.brandBlue.withValues(alpha: 0.35),
                      border: Border.all(
                        color: AppColors.brandBlueSoft.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      _letters[i],
                      style: GoogleFonts.sora(
                        color: p.title,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: r.scale(12)),
          Row(
            children: [
              if (_message != null)
                Text(
                  _message!,
                  style: GoogleFonts.sora(
                    color: _message == 'Cleared'
                        ? const Color(0xFF6BCB8A)
                        : p.body,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(_deal),
                child: Text(
                  'New word',
                  style: GoogleFonts.sora(color: AppColors.brandBlueSoft),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PollsCard extends StatefulWidget {
  const _PollsCard({required this.onVoted});
  final Future<void> Function() onVoted;

  @override
  State<_PollsCard> createState() => _PollsCardState();
}

class _PollsCardState extends State<_PollsCard> {
  int _index = 0;
  int? _picked;

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    final p = AppPalette.of(context);
    final poll = AppContent.cabinPolls[_index % AppContent.cabinPolls.length];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(r.scale(18)),
      decoration: premiumCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'CABIN POLL',
                  style: GoogleFonts.sora(
                    color: p.eyebrow,
                    fontSize: 11,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              InstructionsButton(
                title: 'Cabin Poll',
                body: kCabinInstructions['polls']!,
                compact: true,
                color: AppColors.brandBlueSoft,
              ),
            ],
          ),
          SizedBox(height: r.scale(8)),
          Text(
            poll.question,
            style: GoogleFonts.fraunces(
              color: p.title,
              fontSize: r.font(22),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: r.scale(14)),
          ...List.generate(poll.options.length, (i) {
            final on = _picked == i;
            return Padding(
              padding: EdgeInsets.only(bottom: r.scale(8)),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    setState(() => _picked = i);
                    await LocalStore.instance.unlockBadge('cabin_voice');
                    await widget.onVoted();
                  },
                  child: Ink(
                    width: double.infinity,
                    padding: EdgeInsets.all(r.scale(12)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: on
                            ? AppColors.brandBlueSoft.withValues(alpha: 0.55)
                            : p.hairline,
                      ),
                      color: on
                          ? AppColors.brandBlue.withValues(alpha: 0.28)
                          : p.chipFill,
                    ),
                    child: Text(
                      poll.options[i],
                      style: GoogleFonts.sora(color: p.title, fontSize: 14),
                    ),
                  ),
                ),
              ),
            );
          }),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _index++;
                  _picked = null;
                });
              },
              child: Text(
                'Next poll',
                style: GoogleFonts.sora(color: AppColors.brandBlueSoft),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CabinTipsCard extends StatelessWidget {
  const _CabinTipsCard();

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    final p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Cabin tips',
                style: GoogleFonts.sora(color: p.body, fontSize: 13),
              ),
            ),
            InstructionsButton(
              title: 'Cabin Tips',
              body: kCabinInstructions['tips']!,
              compact: true,
              color: AppColors.brandBlueSoft,
            ),
          ],
        ),
        SizedBox(height: r.scale(10)),
        ...AppContent.cabinTips.map(
          (tip) => Padding(
            padding: EdgeInsets.only(bottom: r.scale(12)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(r.scale(16)),
              decoration: premiumCardDecoration(context),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates_outlined,
                      color: AppColors.brandBlueSoft, size: 20),
                  SizedBox(width: r.scale(10)),
                  Expanded(
                    child: Text(
                      tip,
                      style: GoogleFonts.sora(
                        color: p.title,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
