import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/auth_service.dart';
import '../../core/data/leaderboard_service.dart';
import '../../core/widgets/pattern_page.dart';

/// Signed-in players use their account name. Guests enter a username once
/// so scores can sit on the leaderboard.
Future<bool> ensurePlayerName(BuildContext context) async {
  await LeaderboardService.loadGuestName();
  if (AuthService.isSignedIn || LeaderboardService.hasGuestName) return true;
  if (!context.mounted) return false;
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF121212),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _GuestNameSheet(),
  );
  return saved == true;
}

class _GuestNameSheet extends StatefulWidget {
  const _GuestNameSheet();

  @override
  State<_GuestNameSheet> createState() => _GuestNameSheetState();
}

class _GuestNameSheetState extends State<_GuestNameSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Enter a username of at least 2 characters.');
      return;
    }
    if (name.length > 24) {
      setState(() => _error = 'Keep it under 24 characters.');
      return;
    }
    HapticFeedback.mediumImpact();
    await LeaderboardService.setGuestName(name);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 12, 22, 18 + inset),
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
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Choose a username',
            style: PatternPage.panchang(size: 18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Saved on this device so your high scores appear on the cabin leaderboard.',
            style: PatternPage.body(
              size: 13,
              color: PatternPage.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 24,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
            cursorColor: PatternPage.blue,
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Username',
              hintStyle: GoogleFonts.poppins(
                color: PatternPage.muted,
                fontSize: 14,
              ),
              errorText: _error,
              filled: true,
              fillColor: const Color(0xFF1C1C1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: PatternPage.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save and play',
                style: PatternPage.panchang(size: 11, weight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
