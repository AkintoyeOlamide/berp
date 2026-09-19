import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/auth_service.dart';
import 'core/boot.dart';
import 'core/cart/catering_cart.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/splash/splash_screen.dart';

class VmoStaffApp extends StatefulWidget {
  const VmoStaffApp({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<VmoStaffApp> createState() => _VmoStaffAppState();
}

class _VmoStaffAppState extends State<VmoStaffApp> {
  final _navKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authSub;
  bool _openedReset = false;

  @override
  void initState() {
    super.initState();
    unawaited(_bindAuth());
  }

  Future<void> _bindAuth() async {
    try {
      await AppBoot.supabase;
    } catch (_) {
      return;
    }
    if (!mounted) return;
    // Supabase may never have initialized (offline boot, tests) — the app
    // still runs, it just cannot listen for password-recovery deep links.
    try {
      _authSub = AuthService.onAuthStateChange.listen((data) {
        if (AuthService.suppressAuthNavigation) return;
        if (data.event != AuthChangeEvent.passwordRecovery) return;
        if (_openedReset) return;
        _openedReset = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navKey.currentState
              ?.push(
                MaterialPageRoute<void>(
                  builder: (_) => const ResetPasswordScreen(),
                ),
              )
              .whenComplete(() {
                _openedReset = false;
              });
        });
      });
    } catch (_) {
      return;
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.settings),
        ChangeNotifierProvider(create: (_) => CateringCart()),
      ],
      child: Consumer<AppSettings>(
        builder: (context, settings, _) {
          return MaterialApp(
            navigatorKey: _navKey,
            title: 'BERP',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settings.themeMode,
            builder: (context, child) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: TextScaler.linear(settings.fontScale),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
