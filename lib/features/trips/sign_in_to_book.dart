import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/pattern_page.dart';
import '../welcome/welcome_screen.dart';

class SignInToBookView extends StatelessWidget {
  const SignInToBookView({super.key});

  void _signIn(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const WelcomeScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 54,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 18),
            Text(
              'Sign in to book\na trip',
              textAlign: TextAlign.center,
              style: PatternPage.panchang(size: 22, weight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Quotes, upcoming flights, and trip details are available after you sign in.',
              textAlign: TextAlign.center,
              style: PatternPage.body(
                size: 13,
                color: PatternPage.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _signIn(context),
                style: FilledButton.styleFrom(
                  backgroundColor: PatternPage.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Sign In',
                  style: PatternPage.panchang(size: 11, weight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
