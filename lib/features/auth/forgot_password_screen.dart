import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../staff/staff_home_screen.dart';

enum _ResetStep { email, code, password }

/// Existing users: email a 4-digit code, set a new password, then sign in.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _bg = Color(0xFF0B0B0B);
  static const _field = Color(0xFF1C1C1E);
  static const _label = Color(0xFFB0B0B0);
  static const _muted = Color(0xFF8A8A8A);
  static const _blue = Color(0xFF1E90FF);
  static const _backCircle = Color(0xFF1A1A1A);

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _codeCtrls = List.generate(4, (_) => TextEditingController());
  final _codeFocus = List.generate(4, (_) => FocusNode());

  _ResetStep _step = _ResetStep.email;
  bool _loading = false;
  bool _finished = false;
  bool _obscurePassword = true;
  String? _error;
  String? _info;
  int _resendIn = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _email.text = widget.initialEmail.trim();
    AuthService.suppressAuthNavigation = true;
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    for (final c in _codeCtrls) {
      c.dispose();
    }
    for (final f in _codeFocus) {
      f.dispose();
    }
    if (!_finished) {
      AuthService.suppressAuthNavigation = false;
      if (AuthService.isSignedIn) {
        unawaited(AuthService.signOut());
      }
    }
    super.dispose();
  }

  String get _code => _codeCtrls.map((c) => c.text).join();

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

  TextStyle _body({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
  }) {
    return GoogleFonts.poppins(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
    );
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendIn = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendIn <= 1) {
        timer.cancel();
        setState(() => _resendIn = 0);
        return;
      }
      setState(() => _resendIn -= 1);
    });
  }

  Future<void> _sendCode({bool resend = false}) async {
    if (_loading) return;
    final email = _email.text.trim();
    setState(() => _error = null);

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Enter the email for your BERP account.');
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.requestPasswordResetCode(email);
      if (!mounted) return;
      _startResendCooldown();
      setState(() {
        _loading = false;
        _step = _ResetStep.code;
        _info = resend
            ? 'New code sent to $email.'
            : 'We sent a 4-digit code to $email.';
        if (resend) {
          for (final c in _codeCtrls) {
            c.clear();
          }
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _codeFocus.first.requestFocus();
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

  void _onCodeChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      final chars = digits.split('').take(4).toList();
      for (var i = 0; i < 4; i++) {
        _codeCtrls[i].text = i < chars.length ? chars[i] : '';
      }
      final next = chars.length >= 4 ? 3 : chars.length;
      _codeFocus[next].requestFocus();
      setState(() {});
      return;
    }
    if (digits.length == 1 && index < 3) {
      _codeCtrls[index].text = digits;
      _codeFocus[index + 1].requestFocus();
    } else if (digits.isEmpty && index > 0) {
      _codeFocus[index - 1].requestFocus();
    }
    setState(() => _error = null);
  }

  Future<void> _continueFromCode() async {
    if (_code.length != 4) {
      setState(() => _error = 'Enter the 4-digit code from your email.');
      return;
    }
    setState(() {
      _error = null;
      _info = null;
      _step = _ResetStep.password;
    });
  }

  Future<void> _savePassword() async {
    if (_loading) return;
    final password = _password.text;
    final confirm = _confirm.text;
    setState(() => _error = null);

    if (_code.length != 4) {
      setState(() {
        _step = _ResetStep.code;
        _error = 'Enter the 4-digit code from your email.';
      });
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthService.completePasswordReset(
        email: _email.text.trim(),
        code: _code,
        newPassword: password,
      );
      if (!mounted) return;
      _finished = true;
      AuthService.suppressAuthNavigation = false;
      setState(() => _loading = false);
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
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AuthService.messageFor(e);
        if (_error!.toLowerCase().contains('code')) {
          _step = _ResetStep.code;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AuthService.messageFor(e);
      });
    }
  }

  void _back() {
    if (_loading) return;
    if (_step == _ResetStep.password) {
      setState(() {
        _step = _ResetStep.code;
        _error = null;
      });
      return;
    }
    if (_step == _ResetStep.code) {
      setState(() {
        _step = _ResetStep.email;
        _error = null;
        _info = null;
      });
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    final title = switch (_step) {
      _ResetStep.email => 'Forgot password',
      _ResetStep.code => 'Enter code',
      _ResetStep.password => 'New password',
    };
    final subtitle = switch (_step) {
      _ResetStep.email =>
        'Enter the email on your BERP account. We’ll send a 4-digit code so you can set a new password.',
      _ResetStep.code =>
        'Type the 4-digit code we sent to ${_email.text.trim()}.',
      _ResetStep.password =>
        'Choose a new password, then you’ll be signed in.',
    };
    final action = switch (_step) {
      _ResetStep.email => 'Send code',
      _ResetStep.code => 'Continue',
      _ResetStep.password => 'Reset password',
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 2, 20, bottom > 0 ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: _backCircle,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _back,
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
                  ),
                ),
                const SizedBox(height: 28),
                Image.asset(
                  BerpBrand.logo,
                  height: 42,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, error, stackTrace) => Text(
                    'BERP',
                    style: _title(
                      color: Colors.white,
                      fontSize: 13,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: _title(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.08,
                    letterSpacing: 0.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: _body(
                    color: _label,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                if (_step == _ResetStep.email) ...[
                  Text(
                    'Email',
                    style: _body(color: _label, fontSize: 11),
                  ),
                  const SizedBox(height: 5),
                  _ResetField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    fill: _field,
                  ),
                ],
                if (_step == _ResetStep.code) ...[
                  Row(
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _codeCtrls[i],
                            focusNode: _codeFocus[i],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            textInputAction: i == 3
                                ? TextInputAction.done
                                : TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            style: _title(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: _field,
                              counterText: '',
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3A3A3A),
                                ),
                              ),
                            ),
                            onChanged: (value) => _onCodeChanged(i, value),
                            onSubmitted: (_) {
                              if (i == 3) unawaited(_continueFromCode());
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _loading || _resendIn > 0
                          ? null
                          : () => _sendCode(resend: true),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _resendIn > 0
                            ? 'Resend code in ${_resendIn}s'
                            : 'Resend code',
                        style: _title(
                          color: _resendIn > 0 ? _muted : _blue,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
                if (_step == _ResetStep.password) ...[
                  Text(
                    'New password',
                    style: _body(color: _label, fontSize: 11),
                  ),
                  const SizedBox(height: 5),
                  _ResetField(
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
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Confirm password',
                    style: _body(color: _label, fontSize: 11),
                  ),
                  const SizedBox(height: 5),
                  _ResetField(
                    controller: _confirm,
                    obscureText: _obscurePassword,
                    fill: _field,
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: _body(
                      color: const Color(0xFFFF6B6B),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
                if (_info != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _info!,
                    style: _body(
                      color: const Color(0xFF7DDEA5),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: FilledButton(
                    onPressed: _loading
                        ? null
                        : switch (_step) {
                            _ResetStep.email => _sendCode,
                            _ResetStep.code => _continueFromCode,
                            _ResetStep.password => _savePassword,
                          },
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
                            action,
                            style: _title(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetField extends StatelessWidget {
  const _ResetField({
    required this.controller,
    required this.fill,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
  });

  final TextEditingController controller;
  final Color fill;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
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
