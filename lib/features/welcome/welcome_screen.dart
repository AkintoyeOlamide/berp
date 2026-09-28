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
  static const _blue = AppColors.secondary;
  static final _termsUri = Uri.parse('https://bhr-iota-mu.vercel.app/terms/berp');
  static final _privacyUri =
      Uri.parse('https://bhr-iota-mu.vercel.app/privacy/berp');

  late final AnimationController _enter;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
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
        backgroundColor: const Color(0xFF050814),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF050814),
                Color(0xFF101A4A),
                Color(0xFF070910),
              ],
              stops: [0.0, 0.42, 1.0],
            ),
          ),
          child: FadeTransition(
            opacity: _fade,
            child: SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  landscape
                      ? _LandscapeBody(
                          logoAsset: _logoAsset,
                          blue: _blue,
                          onCreate: () => _openAuth(AuthMode.create),
                          onSignIn: () => _openAuth(AuthMode.signIn),
                          onTerms: () => _openLegal(_termsUri),
                          onPrivacy: () => _openLegal(_privacyUri),
                        )
                      : _PortraitBody(
                          logoAsset: _logoAsset,
                          blue: _blue,
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
    package: null,
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
    required this.blue,
    required this.onCreate,
    required this.onSignIn,
    required this.onTerms,
    required this.onPrivacy,
  });

  final String logoAsset;
  final Color blue;
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
        padding: EdgeInsets.fromLTRB(side, 12, side, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: _LandingLockup(logoAsset: logoAsset),
            ),
            const SizedBox(height: 14),
            const _BrandStripes(),
            const Spacer(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                  Text(
                    'Staff sign in',
                    textAlign: TextAlign.center,
                    style: _panchang(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _LegalLine(
                    onTerms: onTerms,
                    onPrivacy: onPrivacy,
                    blue: blue,
                  ),
                  const SizedBox(height: 16),
                  _PrimaryButton(
                    label: 'Create account',
                    blue: blue,
                    onTap: onCreate,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: onSignIn,
                    child: Text(
                      'Sign in',
                      textAlign: TextAlign.center,
                      style: _panchang(
                        color: AppColors.secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _LandscapeBody extends StatelessWidget {
  const _LandscapeBody({
    required this.logoAsset,
    required this.blue,
    required this.onCreate,
    required this.onSignIn,
    required this.onTerms,
    required this.onPrivacy,
  });

  final String logoAsset;
  final Color blue;
  final VoidCallback onCreate;
  final VoidCallback onSignIn;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Row(
          children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LandingLockup(logoAsset: logoAsset, compact: true),
                      const SizedBox(height: 8),
                      const _BrandStripes(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Staff sign in',
                        style: _panchang(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LegalLine(
                        onTerms: onTerms,
                        onPrivacy: onPrivacy,
                        blue: blue,
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: _PrimaryButton(
                          label: 'Create account',
                          blue: blue,
                          onTap: onCreate,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: onSignIn,
                        child: Text(
                          'Sign in',
                          style: _panchang(
                            color: AppColors.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }
}

class _LegalLine extends StatelessWidget {
  const _LegalLine({
    required this.onTerms,
    required this.onPrivacy,
    required this.blue,
  });

  final VoidCallback onTerms;
  final VoidCallback onPrivacy;
  final Color blue;

  @override
  Widget build(BuildContext context) {
    final base = _panchang(
      color: AppColors.secondary,
      fontSize: 9.5,
      height: 1.35,
    );
    final terms = base.copyWith(
      color: AppColors.secondary,
      fontWeight: FontWeight.w600,
    );
    final privacy = base.copyWith(
      color: AppColors.secondary,
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
              child: Text('Terms', style: terms),
            ),
          ),
          const TextSpan(text: ' and '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: onPrivacy,
              child: Text('Privacy Policy', style: privacy),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _LandingLockup extends StatelessWidget {
  const _LandingLockup({
    required this.logoAsset,
    this.compact = false,
  });

  final String logoAsset;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final markH = compact ? 32.0 : 44.0;
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
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              BerpBrand.wordmark,
              style: _panchang(
                color: Colors.white,
                fontSize: compact ? 13 : 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              BerpBrand.line,
              style: _panchang(
                color: AppColors.secondary,
                fontSize: compact ? 8 : 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 2.4,
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
    const colors = [AppColors.cyan, AppColors.orange, AppColors.green];
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
  const _PrimaryButton({
    required this.label,
    required this.blue,
    required this.onTap,
  });

  final String label;
  final Color blue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondary,
          overlayColor: Colors.white.withValues(alpha: 0.12),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        child: Text(
          label,
          style: _panchang(
            fontWeight: FontWeight.w600,
            fontSize: 9.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
