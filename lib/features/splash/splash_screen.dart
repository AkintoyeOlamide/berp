import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/auth_service.dart';
import '../../core/boot.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../staff/staff_home_screen.dart';
import '../welcome/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _exit;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _enterpriseFade;
  late final Animation<Offset> _enterpriseSlide;
  late final Animation<double> _copyFade;
  late final Animation<double> _exitFade;

  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _logoFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.0, 0.38, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.0, 0.42, curve: Curves.easeOutCubic),
      ),
    );
    _enterpriseFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.42, 0.78, curve: Curves.easeOut),
    );
    _enterpriseSlide = Tween<Offset>(
      begin: const Offset(0, 0.55),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.42, 0.82, curve: Curves.easeOutCubic),
      ),
    );
    _copyFade = CurvedAnimation(
      parent: _enter,
      curve: const Interval(0.62, 1, curve: Curves.easeOut),
    );
    _exitFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exit, curve: Curves.easeInCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      unawaited(_run());
    });
    unawaited(AppBoot.supabase);
  }

  Future<void> _run() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted || _leaving) return;
    await _enter.forward();
    if (!mounted || _leaving) return;
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    await _goNext();
  }

  Future<void> _goNext() async {
    if (!mounted || _leaving) return;
    _leaving = true;
    _enter.stop();
    if (!mounted) return;
    await _exit.forward();
    if (!mounted) return;
    try {
      await AppBoot.supabase;
    } catch (_) {}
    if (!mounted) return;
    final next = AuthService.isSignedIn
        ? const StaffHomeScreen()
        : const WelcomeScreen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _enter.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = R.of(context);
    final markH = (r.height * 0.072).clamp(42.0, 58.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _goNext,
          child: FadeTransition(
            opacity: _exitFade,
            child: SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: _logoFade,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.asset(
                                  BerpBrand.logo,
                                  height: markH,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                                SizedBox(width: r.scale(10)),
                                Text(
                                  BerpBrand.wordmark,
                                  style: TextStyle(
                                    fontFamily: 'Panchang',
                                    color: AppColors.brandBlue,
                                    fontSize: r.font(20, tablet: 24),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ClipRect(
                          child: SlideTransition(
                            position: _enterpriseSlide,
                            child: FadeTransition(
                              opacity: _enterpriseFade,
                              child: Text(
                                BerpBrand.line,
                                style: GoogleFonts.poppins(
                                  color: AppColors.brandBlue,
                                  fontSize: r.font(11, tablet: 12),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 3.6,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: r.scale(r.isLandscape ? 14 : 22),
                    child: FadeTransition(
                      opacity: _copyFade,
                      child: Text(
                        '© 2026 Bitachon Enterprise. All rights reserved.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1A1A1A),
                          fontSize: r.font(9, tablet: 10),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.15,
                          height: 1.3,
                        ),
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
