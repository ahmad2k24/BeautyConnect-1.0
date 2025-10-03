import 'dart:async';

import 'package:beauty_connect/data/data.dart';
import 'package:beauty_connect/views/views.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:beauty_connect/core/core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VendorProfile extends StatefulWidget {
  const VendorProfile({super.key});

  @override
  State<VendorProfile> createState() => _VendorProfileState();
}

class _VendorProfileState extends State<VendorProfile> {
  bool isDarkMode = false;
  final AuthRepository _authRepo = AuthRepository();
  final SupabaseClient _client = SupabaseConfig.client;
  @override
  Widget build(BuildContext context) {
    // ---------- DUMMY DATA ----------
    const String avatarUrl = 'https://i.pravatar.cc/150?img=12';

    final theme = Theme.of(context);
    final textColor = theme.brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final subTextColor = theme.brightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;

    return FutureBuilder<Vendor?>(
      future: Future.value(
        _authRepo.fetchVendorById(_client.auth.currentUser?.id),
      ), // Replace with actual data fetch
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'No vendor profile found.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to Create Vendor Profile screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateVendorProfileScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink, // match your salon theme
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create Your First Vendor Account',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        final vendor = snapshot.data!;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ---------- SLIVER APPBAR HEADER ----------
              SliverAppBar(
                pinned: false, // header hides completely
                floating: false,
                snap: false,
                expandedHeight: 200,
                backgroundColor: AppTheme.primaryPink,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryPink.withOpacity(0.9),
                          AppTheme.primaryPink.withOpacity(0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.lightPink,
                          backgroundImage: NetworkImage(
                            vendor.vendorUrl ?? avatarUrl,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          vendor.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Joined on ${vendor.joinedDateFormatted}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),

              // ---------- BODY CONTENT ----------
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      // ---------- VENDOR INFO ----------
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryPink.withOpacity(0.3),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              "Email",
                              vendor.email,
                              textColor,
                              subTextColor,
                            ),
                            _thinDivider(),
                            _buildInfoRow(
                              "Phone",
                              vendor.phone,
                              textColor,
                              subTextColor,
                            ),
                            _thinDivider(),
                            _buildInfoRow(
                              "Address",
                              vendor.address,
                              textColor,
                              subTextColor,
                            ),
                            _thinDivider(),
                            _buildInfoRow(
                              "Website",
                              vendor.website,
                              textColor,
                              subTextColor,
                            ),
                            _thinDivider(),
                            _buildInfoRow(
                              "Country",
                              vendor.country,
                              textColor,
                              subTextColor,
                            ),
                            _thinDivider(),
                            _buildInfoRow(
                              "Experience",
                              vendor.experience,
                              textColor,
                              subTextColor,
                            ),
                            _thinDivider(),
                            _buildInfoRow(
                              "Opening Time",
                              vendor.openingTime,
                              textColor,
                              subTextColor,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: vendor.services
                                  .map(
                                    (service) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightPink.withOpacity(
                                          0.3,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        service,
                                        style: const TextStyle(
                                          color: AppTheme.primaryPink,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ---------- SETTINGS TILES ----------
                      Column(
                        children: [
                          _buildSimpleTile(
                            icon: CupertinoIcons.add,
                            label: "Create Service",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateServiceScreen(),
                                ),
                              );
                            },
                            textColor: textColor,
                          ),
                          _buildSimpleTile(
                            icon: CupertinoIcons.profile_circled,
                            label: "Edit Vendor Profile",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditVendorProfileScreen(vendor: vendor),
                                ),
                              );
                            },
                            textColor: textColor,
                          ),
                          _buildSimpleTile(
                            icon: CupertinoIcons.star,
                            label: "Reviews & Ratings",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShowReviewScreen(),
                                ),
                              );
                            },
                            textColor: textColor,
                          ),
                          _buildSimpleTile(
                            icon: CupertinoIcons.money_dollar,
                            label: "Payments & Merchant Profile",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MerchantProfile(vendor: vendor),
                                ),
                              );
                            },
                            textColor: textColor,
                          ),
                          _buildSimpleTile(
                            icon: Icons.card_membership,
                            label: "Subscription Plans",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SubscriptionScreen(),
                                ),
                              );
                            },
                            textColor: textColor,
                          ),
                          ListTile(
                            leading: const Icon(
                              CupertinoIcons.moon,
                              color: AppTheme.primaryPink,
                            ),
                            title: Text(
                              "Theme Mode",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                            trailing: ValueListenableBuilder<bool>(
                              valueListenable: ThemeController
                                  .instance
                                  .isDark, // Listen to changes
                              builder: (context, isDark, _) {
                                return CupertinoSwitch(
                                  value: isDark,
                                  activeTrackColor: AppTheme.primaryPink,
                                  onChanged: (val) {
                                    ThemeController.instance
                                        .toggleTheme(); // This flips the notifier
                                  },
                                );
                              },
                            ),
                          ),

                          _buildSimpleTile(
                            icon: CupertinoIcons.delete,
                            label: "Delete Account",
                            onTap: () {},
                            isDestructive: true,
                            textColor: textColor,
                          ),
                          _buildSimpleTile(
                            icon: CupertinoIcons.power,
                            label: "Logout",
                            onTap: () async {
                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              try {
                                await AuthRepository()
                                    .signOut(); // call your signOut method

                                Navigator.pop(
                                  context,
                                ); // remove loading indicator

                                // Navigate to login screen or initial route
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return const AuthSwitcherScreen();
                                    },
                                  ),
                                );
                              } catch (e) {
                                Navigator.pop(
                                  context,
                                ); // remove loading indicator
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to logout: $e'),
                                  ),
                                );
                              }
                            },
                            isDestructive: true,
                            textColor: textColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    Color textColor,
    Color subTextColor,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            "$label:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: subTextColor,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 14, color: textColor)),
        ),
      ],
    );
  }

  Widget _thinDivider() {
    return Divider(
      thickness: 0.5,
      color: AppTheme.primaryPink.withOpacity(0.3),
      height: 20,
    );
  }

  Widget _buildSimpleTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
    required Color textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : AppTheme.primaryPink,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : textColor,
        ),
      ),
      trailing: const Icon(CupertinoIcons.forward, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    );
  }
}
