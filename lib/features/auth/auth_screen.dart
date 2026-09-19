import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../core/auth/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../staff/staff_home_screen.dart';
import 'forgot_password_screen.dart';

enum AuthMode { create, signIn }

/// Create Account / Sign In — matches the dark auth mockup.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.mode = AuthMode.create});

  final AuthMode mode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const _bg = Color(0xFF0B0B0B);
  static const _field = Color(0xFF1C1C1E);
  static const _label = Color(0xFFB0B0B0);
  static const _muted = Color(0xFF8A8A8A);
  static const _blue = Color(0xFF1E90FF);
  static const _backCircle = Color(0xFF1A1A1A);
  static final _termsUri = Uri.parse('https://bhr-iota-mu.vercel.app/terms/berp');
  static final _privacyUri =
      Uri.parse('https://bhr-iota-mu.vercel.app/privacy/berp');

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  String? _info;
  StreamSubscription<AuthState>? _authSub;

  late AuthMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _authSub = AuthService.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (AuthService.suppressAuthNavigation) return;
      // Password recovery is handled globally in VmoStaffApp.
      if (data.event == AuthChangeEvent.passwordRecovery) return;
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        _goHome();
      }
    });
    if (AuthService.isSignedIn && !AuthService.suppressAuthNavigation) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goHome());
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _isCreate => _mode == AuthMode.create;

  String get _primaryLabel => _isCreate ? 'Create Account' : 'Sign In';

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const StaffHomeScreen(),
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
      (_) => false,
    );
  }

  Future<void> _submit() async {
    if (_loading) return;

    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    setState(() {
      _error = null;
      _info = null;
    });

    if (_isCreate && name.isEmpty) {
      setState(() => _error = 'Enter your name.');
      return;
    }
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() => _loading = true);
    try {
      if (_isCreate) {
        final res = await AuthService.signUp(
          email: email,
          password: password,
          name: name,
        ).timeout(const Duration(seconds: 12));
        if (!mounted) return;

        // Email confirmation may be required in Supabase project settings.
        if (res.session == null) {
          setState(() {
            _loading = false;
            _info =
                'Account created. Check your email to confirm, then sign in.';
            _mode = AuthMode.signIn;
          });
          return;
        }
      } else {
        await AuthService.signIn(email: email, password: password)
            .timeout(const Duration(seconds: 12));
      }

      if (!mounted) return;
      setState(() => _loading = false);
      _goHome();
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error =
            'Request timed out. Check your connection and try again.';
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AuthService.messageFor(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AuthService.messageFor(e);
      });
    }
  }

  void _forgotPassword() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, _, _) => ForgotPasswordScreen(
          initialEmail: _email.text.trim(),
        ),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _socialDummy(String provider) {
    HapticFeedback.selectionClick();
    setState(() {
      _error = null;
      _info = '$provider sign-in coming soon.';
    });
  }

  Future<void> _openLegal(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Titles only — Panchang Medium.
  TextStyle _title({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'Panchang',
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w500,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Body / UI copy — Poppins.
  TextStyle _body({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return GoogleFonts.poppins(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    const logoH = 42.0;
    final cacheH = (logoH * dpr).round();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 2, 20, bottom > 0 ? 6 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _BackButton(
                    color: _backCircle,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  behavior: HitTestBehavior.opaque,
                  child: Image.asset(
                    BerpBrand.logo,
                    height: logoH,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    cacheHeight: cacheH,
                    errorBuilder: (_, error, stackTrace) => Text(
                      'BERP',
                      style: _title(
                        color: Colors.white,
                        fontSize: 13,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isCreate ? 'Create account' : 'Sign in',
                  style: _title(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.08,
                    letterSpacing: 0.15,
                  ),
                ),
                const SizedBox(height: 22),
                if (_isCreate) ...[
                  Text(
                    'Name',
                    style: _body(
                      color: _label,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _AuthField(
                    controller: _name,
                    keyboardType: TextInputType.name,
                    fill: _field,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  'Email',
                  style: _body(
                    color: _label,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 5),
                _AuthField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  fill: _field,
                ),
                const SizedBox(height: 10),
                Text(
                  'Password',
                  style: _body(
                    color: _label,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 5),
                _AuthField(
                  controller: _password,
                  obscureText: _obscurePassword,
                  fill: _field,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: _muted,
                      size: 18,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _loading ? null : _forgotPassword,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Forgot password?',
                      style: _title(
                        color: _blue,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _error!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _body(
                      color: const Color(0xFFFF6B6B),
                      fontSize: 10.5,
                      height: 1.3,
                    ),
                  ),
                ],
                if (_info != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _info!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: _body(
                      color: const Color(0xFF7DDEA5),
                      fontSize: 10.5,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Center(
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            setState(() {
                              _mode = _isCreate
                                  ? AuthMode.signIn
                                  : AuthMode.create;
                              _error = null;
                              _info = null;
                            });
                          },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: _body(
                          color: _muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          TextSpan(
                            text: _isCreate
                                ? 'Already have an account? '
                                : 'Don’t have an account? ',
                          ),
                          TextSpan(
                            text: _isCreate ? 'Sign in' : 'Create account',
                            style: _title(
                              color: _blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _blue.withValues(alpha: 0.55),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _primaryLabel,
                            style: _title(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: Color(0xFF3A3A3C), height: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'OR',
                        style: _body(
                          color: _muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: Color(0xFF3A3A3C), height: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _SocialAuthButton(
                        label: 'Google',
                        onTap: _loading ? null : () => _socialDummy('Google'),
                        leading: const _GoogleMark(),
                        title: _title,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SocialAuthButton(
                        label: 'Apple',
                        onTap: _loading ? null : () => _socialDummy('Apple'),
                        leading: const Icon(
                          Icons.apple,
                          color: Colors.white,
                          size: 16,
                        ),
                        title: _title,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text.rich(
                  TextSpan(
                    style: _body(
                      color: _blue,
                      fontSize: 9.5,
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'By clicking proceeding, you agree that Bitachon Enterprise may retain the information you provide, and you agree to our ',
                      ),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => _openLegal(_termsUri),
                          child: Text(
                            'Terms of Service',
                            style: _body(
                              color: _blue,
                              fontSize: 9.5,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.underline,
                              decorationColor: _blue,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' and '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => _openLegal(_privacyUri),
                          child: Text(
                            'Privacy Policy',
                            style: _body(
                              color: _blue,
                              fontSize: 9.5,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.underline,
                              decorationColor: _blue,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialAuthButton extends StatelessWidget {
  const _SocialAuthButton({
    required this.label,
    required this.leading,
    required this.title,
    this.onTap,
  });

  final String label;
  final Widget leading;
  final VoidCallback? onTap;
  final TextStyle Function({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Material(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 16, height: 16, child: Center(child: leading)),
              const SizedBox(width: 7),
              Text(
                label,
                style: title(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    // Compact multi-color "G" mark to match the social row mockup.
    return SizedBox(
      width: 16,
      height: 16,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final stroke = size.width * 0.22;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r - stroke / 2);

    void arc(Color color, double start, double sweep) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, start, sweep, false, paint);
    }

    arc(const Color(0xFFEA4335), -2.2, 1.4);
    arc(const Color(0xFFFBBC05), -0.8, 1.2);
    arc(const Color(0xFF34A853), 0.4, 1.2);
    arc(const Color(0xFF4285F4), 1.6, 1.6);

    final bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(cx - stroke * 0.15, cy - stroke / 2, r * 0.95, stroke),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 30,
          height: 30,
          child: Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFFD0D0D0),
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.fill,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.suffix,
  });

  final TextEditingController controller;
  final Color fill;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      cursorColor: Colors.white,
      style: GoogleFonts.poppins(
        color: const Color(0xFFE8E8E8),
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: Color(0xFF3A3A3A), width: 1),
        ),
      ),
    );
  }
}
