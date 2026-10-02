import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/auth_screen.dart';
import '../../core/theme/app_colors.dart';

/// Post-splash welcome — staff sign-in landing for BERP.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const _logoAsset = BerpBrand.logo;
  static final _termsUri = Uri.parse('https://bhr-iota-mu.vercel.app/terms/berp');
  static final _privacyUri =
      Uri.parse('https://bhr-iota-mu.vercel.app/privacy/berp');

  late final AnimationController _enter;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  void _openAuth(AuthMode mode) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => AuthScreen(mode: mode),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _openLegal(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final landscape = size.width > size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF141414),
                Color(0xFF0A0A0A),
                Color(0xFF070707),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: SafeArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    landscape
                        ? _LandscapeBody(
                            logoAsset: _logoAsset,
                            onCreate: () => _openAuth(AuthMode.create),
                            onSignIn: () => _openAuth(AuthMode.signIn),
                            onTerms: () => _openLegal(_termsUri),
                            onPrivacy: () => _openLegal(_privacyUri),
                          )
                        : _PortraitBody(
                            logoAsset: _logoAsset,
                            onCreate: () => _openAuth(AuthMode.create),
                            onSignIn: () => _openAuth(AuthMode.signIn),
                            onTerms: () => _openLegal(_termsUri),
                            onPrivacy: () => _openLegal(_privacyUri),
                          ),
                    if (Navigator.of(context).canPop())
                      Positioned(
                        top: 4,
                        left: 8,
                        child: IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _panchang({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: 'Panchang',
    fontFamilyFallback: const ['Panchang'],
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
  );
}

class _PortraitBody extends StatelessWidget {
  const _PortraitBody({
    required this.logoAsset,
    required this.onCreate,
    required this.onSignIn,
    required this.onTerms,
    required this.onPrivacy,
  });

  final String logoAsset;
  final VoidCallback onCreate;
  final VoidCallback onSignIn;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final side = (w * 0.08).clamp(24.0, 36.0);

    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.fromLTRB(side, 20, side, 24),
        child: Column(
          children: [
            const Spacer(flex: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: _LandingLockup(logoAsset: logoAsset),
            ),
            const SizedBox(height: 16),
            const _BrandStripes(),
            const SizedBox(height: 28),
            Text(
              'Staff portal',
              textAlign: TextAlign.center,
              style: _panchang(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Clock in, leave, tickets, and team updates —\nin one calm place.',
              textAlign: TextAlign.center,
              style: _panchang(
                color: const Color(0xFF9A9A9A),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
            const Spacer(flex: 3),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                children: [
                  _PrimaryButton(label: 'Create account', onTap: onCreate),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: onSignIn,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF333333)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Sign in',
                        style: _panchang(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _LegalLine(onTerms: onTerms, onPrivacy: onPrivacy),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandscapeBody extends StatelessWidget {
  const _LandscapeBody({
    required this.logoAsset,
    required this.onCreate,
    required this.onSignIn,
    required this.onTerms,
    required this.onPrivacy,
  });

  final String logoAsset;
  final VoidCallback onCreate;
  final VoidCallback onSignIn;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LandingLockup(logoAsset: logoAsset, compact: true),
                  const SizedBox(height: 12),
                  const _BrandStripes(),
                  const SizedBox(height: 18),
                  Text(
                    'Staff portal',
                    style: _panchang(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PrimaryButton(label: 'Create account', onTap: onCreate),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: onSignIn,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF333333)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Sign in',
                          style: _panchang(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _LegalLine(onTerms: onTerms, onPrivacy: onPrivacy),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalLine extends StatelessWidget {
  const _LegalLine({required this.onTerms, required this.onPrivacy});

  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final base = _panchang(
      color: const Color(0xFF7A7A7A),
      fontSize: 10,
      height: 1.4,
    );
    final link = base.copyWith(
      color: const Color(0xFFCFCFCF),
      fontWeight: FontWeight.w600,
    );

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'By continuing you agree to our '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: onTerms,
              child: Text('Terms', style: link),
            ),
          ),
          const TextSpan(text: ' and '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: onPrivacy,
              child: Text('Privacy Policy', style: link),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _LandingLockup extends StatelessWidget {
  const _LandingLockup({required this.logoAsset, this.compact = false});

  final String logoAsset;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final markH = compact ? 36.0 : 52.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          logoAsset,
          height: markH,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              BerpBrand.wordmark,
              style: _panchang(
                color: Colors.white,
                fontSize: compact ? 15 : 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              BerpBrand.line,
              style: _panchang(
                color: const Color(0xFF9A9A9A),
                fontSize: compact ? 8.5 : 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.6,
                height: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BrandStripes extends StatelessWidget {
  const _BrandStripes();

  @override
  Widget build(BuildContext context) {
    const colors = [AppColors.orange, AppColors.green, Color(0xFF6B8CFF)];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < colors.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Transform.rotate(
            angle: -0.55,
            child: Container(
              width: 16,
              height: 4,
              decoration: BoxDecoration(
                color: colors[i],
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          overlayColor: Colors.black.withValues(alpha: 0.06),
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: _panchang(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
