import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Thin auth helpers around Supabase Auth.
abstract final class AuthService {
  static const _authTimeout = Duration(seconds: 12);
  static SupabaseClient get client => Supabase.instance.client;

  /// When true, auth screens must not jump to home (OTP / password reset).
  static bool suppressAuthNavigation = false;

  static User? get currentUser {
    try {
      return client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  static bool get isSignedIn => currentUser != null;

  static Stream<AuthState> get onAuthStateChange =>
      client.auth.onAuthStateChange;

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) {
    return client.auth
        .signUp(
          email: email,
          password: password,
          data: {
            'full_name': name,
            'name': name,
          },
        )
        .timeout(_authTimeout);
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return client.auth
        .signInWithPassword(email: email, password: password)
        .timeout(_authTimeout);
  }

  /// Sends a password-reset email. User returns via [SupabaseConfig.passwordResetRedirect].
  static Future<void> resetPasswordForEmail(String email) {
    return client.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? null : SupabaseConfig.passwordResetRedirect,
    );
  }

  /// Emails a 4-digit recovery code via BHR (Gmail SMTP), same as vops.
  static Future<void> requestPasswordResetCode(String email) async {
    final normalized = email.trim().toLowerCase();
    final res = await _postRecovery(
      primary: SupabaseConfig.recoveryRequestUrl,
      fallback: SupabaseConfig.vopsRecoveryRequestUrl,
      body: {'email': normalized},
    );
    _throwIfRecoveryFailed(res, fallback: 'Could not send recovery code.');
  }

  /// Verifies the 4-digit code, sets the new password, and signs the user in.
  static Future<void> completePasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final normalized = email.trim().toLowerCase();
    final pin = code.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw const AuthException('Enter the 4-digit code from your email.');
    }

    final res = await _postRecovery(
      primary: SupabaseConfig.recoveryConfirmUrl,
      fallback: SupabaseConfig.vopsRecoveryConfirmUrl,
      body: {
        'email': normalized,
        'code': pin,
        'password': newPassword,
      },
    );
    _throwIfRecoveryFailed(res, fallback: 'Could not reset password.');
    await signIn(email: normalized, password: newPassword);
  }

  /// BERP routes are not on Vercel yet (404). Use the live vops mailer until they are.
  static Future<http.Response> _postRecovery({
    required String primary,
    required String fallback,
    required Map<String, dynamic> body,
  }) async {
    final payload = jsonEncode(body);
    const headers = {'Content-Type': 'application/json'};
    final first = await http
        .post(Uri.parse(primary), headers: headers, body: payload)
        .timeout(const Duration(seconds: 20));
    if (first.statusCode != 404) return first;
    return http
        .post(Uri.parse(fallback), headers: headers, body: payload)
        .timeout(const Duration(seconds: 20));
  }

  static void _throwIfRecoveryFailed(
    http.Response res, {
    required String fallback,
  }) {
    if (res.statusCode < 400) return;
    Object? data;
    try {
      data = jsonDecode(res.body);
    } catch (_) {
      data = null;
    }
    final message = data is Map && data['error'] != null
        ? '${data['error']}'
        : fallback;
    throw AuthException(message, statusCode: '${res.statusCode}');
  }

  static Future<UserResponse> updatePassword(String newPassword) {
    return client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Opens the browser / custom tab for Google OAuth, then returns via deep link.
  static Future<bool> signInWithGoogle() {
    return _oauth(OAuthProvider.google);
  }

  /// Opens the browser / custom tab for Apple OAuth, then returns via deep link.
  static Future<bool> signInWithApple() {
    return _oauth(OAuthProvider.apple);
  }

  static Future<bool> _oauth(OAuthProvider provider) {
    return client.auth.signInWithOAuth(
      provider,
      redirectTo: kIsWeb ? null : SupabaseConfig.oauthRedirect,
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }

  static Future<void> signOut() => client.auth.signOut();

  static String messageFor(Object error) {
    if (error is PostgrestException) {
      final m = error.message.trim();
      if (m.isEmpty) return 'Something went wrong. Please try again.';
      final lower = m.toLowerCase();
      if (lower.contains('does not exist') || lower.contains('schema cache')) {
        return 'Could not send a reset code. Please try again.';
      }
      return m;
    }
    if (error is TimeoutException) {
      return 'Could not send a reset code. Please try again in a moment.';
    }
    if (error is AuthException) {
      final m = error.message.trim();
      if (m.isEmpty) return 'Authentication failed. Please try again.';
      final lower = m.toLowerCase();
      if (lower.contains('invalid login') ||
          lower.contains('invalid credentials')) {
        return 'Incorrect email or password.';
      }
      if (lower.contains('already registered') ||
          lower.contains('already been registered')) {
        return 'An account with this email already exists. Sign in instead.';
      }
      if (lower.contains('provider is not enabled') ||
          lower.contains('unsupported provider')) {
        return 'This sign-in method is not enabled yet. Enable it in Supabase Auth providers.';
      }
      if (lower.contains('rate limit') ||
          lower.contains('security purposes') ||
          lower.contains('wait')) {
        return m.contains('wait')
            ? m
            : 'Please wait a moment before requesting another code.';
      }
      if (lower.contains('failed to send') ||
          lower.contains('relay') ||
          lower.contains('smtp')) {
        return 'Could not send the recovery email. Check BHR SMTP on Vercel.';
      }
      if (lower.contains('incorrect') ||
          lower.contains('expired') ||
          lower.contains('invalid or expired')) {
        return m;
      }
      if (lower.contains('password') || lower.contains('email')) {
        return m;
      }
      return m;
    }
    return 'Something went wrong. Check your connection and try again.';
  }
}
