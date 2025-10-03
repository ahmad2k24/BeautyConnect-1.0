import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:beauty_connect/views/auth/reset_password.dart';
import 'package:flutter/material.dart';
import 'package:beauty_connect/core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // for AppTheme.primaryPink, etc.

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription? _sub;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sending = false;

  void _initDeepLinkListener() {
    // Listen for links while the app is running
    _sub = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) _handleResetLink(uri);
      },
      onError: (err) {
        debugPrint('Error listening to app links: $err');
      },
    );

    // Handle initial link if app was opened via link
    _appLinks
        .getInitialLink()
        .then((uri) {
          if (uri != null) _handleResetLink(uri);
        })
        .catchError((err) => debugPrint('Error getting initial link: $err'));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _handleResetLink(Uri uri) {
    // Example link: beautyconnect://reset-password?access_token=xxx
    if (uri.pathSegments.contains('reset-password')) {
      final token = uri.queryParameters['access_token'];
      if (token != null) {
        final route = MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(),
        );
        Navigator.push(context, route);
      }
    }
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);

    try {
      final email = _emailController.text.trim();

      // ⚡ Supabase: Send password reset email
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor, // same as Scaffold
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Forgot Password',
          style: TextStyle(color: isDark ? Colors.white : Colors.pinkAccent),
        ),
        // keep the foreground text/icon color adaptive
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Enter your registered email address and we’ll send you a password reset link.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Send Reset Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _sending ? null : _sendResetEmail,
                    child: _sending
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Send Reset Email',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),

                const Spacer(),

                // Remember password? Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Remember your password? ',
                      style: theme.textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        'Login',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryPink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
