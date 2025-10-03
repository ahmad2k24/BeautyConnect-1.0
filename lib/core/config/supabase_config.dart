import 'package:beauty_connect/core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static final SupabaseClient client = Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
}
