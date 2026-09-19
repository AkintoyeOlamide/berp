/// Public Supabase client config only.
///
/// Never put the service-role / secret key in the Flutter app.
abstract final class SupabaseConfig {
  static const url = 'https://vfrgawklszvhddrvjjxj.supabase.co';

  /// Publishable / anon key (safe for client apps with RLS).
  static const anonKey =
      'sb_publishable_SmJJ-AMTUR5uYEiPuOZIog_ce5h1Mpf';

  /// Deep-link used after Google / Apple OAuth.
  /// Add under Supabase → Authentication → URL Configuration
  /// → Additional Redirect URLs.
  static const oauthRedirect = 'com.vmostaff.app://login-callback/';

  /// Deep-link used after the user taps the password-reset email link.
  /// Add this under Additional Redirect URLs as well.
  static const passwordResetRedirect = 'com.vmostaff.app://reset-callback/';

  /// BHR hosts BERP recovery email (Nodemailer / Gmail SMTP), same as vops.
  static const bhrBaseUrl = 'https://bhr-iota-mu.vercel.app';
  static const recoveryRequestUrl = '$bhrBaseUrl/api/berp/recovery/request';
  static const recoveryConfirmUrl = '$bhrBaseUrl/api/berp/recovery/confirm';
  static const vopsRecoveryRequestUrl =
      '$bhrBaseUrl/api/vops/recovery/request';
  static const vopsRecoveryConfirmUrl =
      '$bhrBaseUrl/api/vops/recovery/confirm';
}
