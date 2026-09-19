import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';

/// Shared startup futures so splash can wait without blocking [runApp].
abstract final class AppBoot {
  static Future<void> supabase = Future.value();

  static Future<void> startSupabase() {
    supabase = Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
    return supabase;
  }
}
