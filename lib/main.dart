import 'package:beauty_connect/core/core.dart';
import 'package:beauty_connect/views/views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();

  // Configure Stripe
  Stripe.publishableKey = stripePublishableKey;
  Stripe.instance.applySettings();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeController.instance;
    return ValueListenableBuilder(
      valueListenable: themeController.isDark,
      builder: (context, isDarkMode, child) {
        return MaterialApp(
          title: 'Beauty Connect',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          home: FutureBuilder<Session?>(
            future: Future.value(SupabaseConfig.client.auth.currentSession),
            builder: (context, sessionSnap) {
              // Wait for Supabase session
              if (sessionSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // If not logged in → Auth flow
              final session = sessionSnap.data;
              if (session == null) {
                return const LoginScreen();
              }

              return ClientLayout();
            },
          ),
        );
      },
    );
  }
}
