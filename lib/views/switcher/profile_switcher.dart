import 'package:beauty_connect/data/data.dart';
import 'package:beauty_connect/views/views.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:beauty_connect/core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSwitcherScreen extends StatefulWidget {
  final VoidCallback? onRoleChanged;
  const ProfileSwitcherScreen({super.key, this.onRoleChanged});

  @override
  State<ProfileSwitcherScreen> createState() => _ProfileSwitcherScreenState();
}

class _ProfileSwitcherScreenState extends State<ProfileSwitcherScreen> {
  // 0 = Vendor, 1 = Client
  int selectedProfile = 0;
  final AuthRepository _authRepo = AuthRepository();
  final SupabaseClient _client = SupabaseConfig.client;

  /// Fetches current user's role and updates the segmented control
  Future<void> _loadUserRole() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await _client
          .from('clients')
          .select('role')
          .eq('id', userId)
          .single();

      final role = response['role'] as String?;

      setState(() {
        selectedProfile = (role == 'vendor') ? 1 : 0;
      });
    } catch (e) {
      debugPrint('Error loading role: $e');
    }
  }

  @override
  void initState() {
    _loadUserRole();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppTheme.primaryPink,
      body: Column(
        children: [
          // ---------- Segmented Control ----------
          Padding(
            padding: const EdgeInsets.only(top: 60, bottom: 10),
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: selectedProfile,
              thumbColor: isDark ? AppTheme.primaryPink : AppTheme.background,
              backgroundColor: AppTheme.lightPink.withOpacity(0.3),
              children: const {
                0: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "Client Profile",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                1: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "Vendor Profile",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              },
              onValueChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedProfile = value;
                  });
                  // Update role in the database
                  try {
                    _authRepo.updateUserRole(value == 0 ? 'client' : 'vendor');

                    if (value == 0) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => ClientLayout()),
                        (route) => false,
                      );
                    } else {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => VendorLayout()),
                        (route) => false,
                      );
                    }

                    widget.onRoleChanged?.call(); // notify parent
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Switched to ${value == 0 ? 'Client' : 'Vendor'} profile',
                        ),
                        backgroundColor: AppTheme.primaryPink,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to switch role: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ),
          // ---------- Profile Content ----------
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: selectedProfile == 0
                  ? const ClientProfile(key: ValueKey('client'))
                  : const VendorProfile(key: ValueKey('vendor')),
            ),
          ),
        ],
      ),
    );
  }
}
