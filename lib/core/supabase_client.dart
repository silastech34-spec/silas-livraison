import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Injectées au build via --dart-define (voir .github/workflows/build.yml)
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static Future<void> init() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }
}

final supabase = Supabase.instance.client;
