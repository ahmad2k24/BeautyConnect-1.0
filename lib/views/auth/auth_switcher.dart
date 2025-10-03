import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:beauty_connect/core/core.dart';
import 'package:beauty_connect/views/auth/login_screen.dart';
import 'package:beauty_connect/views/auth/signup_screen.dart';

class AuthSwitcherScreen extends StatefulWidget {
  const AuthSwitcherScreen({super.key});

  @override
  State<AuthSwitcherScreen> createState() => _AuthSwitcherScreenState();
}

class _AuthSwitcherScreenState extends State<AuthSwitcherScreen> {
  /// 0 = Login, 1 = Sign-Up
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color activeColor = AppTheme.primaryPink;
    final Color inactiveColor = theme.brightness == Brightness.dark
        ? Colors.grey[700]!
        : Colors.grey[300]!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // --- Brand Title ---
            Text(
              'Beauty Connect',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 26,
                color: AppTheme.primaryPink,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            // --- Cupertino Sliding Segmented Control ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: 280, // 🔧 Adjust width here
                height: 50, // 🔧 Adjust height here
                child: CupertinoSlidingSegmentedControl<int>(
                  backgroundColor: inactiveColor,
                  thumbColor: activeColor,
                  groupValue: _selected,
                  children: {
                    0: SizedBox(
                      height:
                          44, // 🔧 Individual segment height (slightly smaller than parent height)
                      child: const Center(
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    1: SizedBox(
                      height: 44,
                      child: const Center(
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  },
                  onValueChanged: (int? value) {
                    if (value != null) {
                      setState(() => _selected = value);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- Sliding Content Area ---
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _selected == 0
                    ? const LoginScreen(key: ValueKey('login'))
                    : const SignUpScreen(key: ValueKey('signup')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
