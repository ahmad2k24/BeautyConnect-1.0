import 'package:beauty_connect/data/models/client.dart';
import 'package:beauty_connect/data/repositories/auth_repository.dart';
import 'package:beauty_connect/views/views.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:beauty_connect/core/core.dart';

class ClientProfile extends StatefulWidget {
  const ClientProfile({super.key});

  @override
  State<ClientProfile> createState() => _ClientProfileState();
}

class _ClientProfileState extends State<ClientProfile> {
  bool isDarkMode = false; // toggle state for theme mode switch
  final AuthRepository _authRepository = AuthRepository();
  final String clientId = SupabaseConfig.client.auth.currentUser?.id ?? '';
  @override
  Widget build(BuildContext context) {
    // ---------- DUMMY DATA ----------
    const String avatarUrl = 'https://i.pravatar.cc/150?img=5';
    final theme = Theme.of(context);
    final textColor = theme.brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;
    final subTextColor = theme.brightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;

    return Scaffold(
      body: FutureBuilder<Client?>(
        future: _authRepository.fetchClientData(clientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Failed to load profile.'));
          }
          final client = snapshot.data!;
          return CustomScrollView(
            slivers: [
              // ---------- COLLAPSING APPBAR / HEADER ----------
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
                            client.clientUrl ?? avatarUrl,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          client.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Joined on ${client.joinedDateFormatted}",
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
                      // ---------- USER DETAILS ----------
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
                          children: [
                            _buildUserInfo(
                              "Full Name",
                              client.name,
                              textColor,
                              subTextColor,
                            ),
                            _thinDivider(),
                            _buildUserInfo(
                              "Email",
                              client.email,
                              textColor,
                              subTextColor,
                            ),
                            _thinDivider(),
                            _buildUserInfo(
                              "Phone",
                              client.phone,
                              textColor,
                              subTextColor,
                            ),
                            _thinDivider(),
                            _buildUserInfo(
                              "Address",
                              client.address!,
                              textColor,
                              subTextColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ---------- SETTINGS TILES ----------
                      Column(
                        children: [
                          _buildSimpleTile(
                            icon: CupertinoIcons.pencil,
                            label: "Edit Profile",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditClientProfile(client: client),
                                ),
                              );
                            },
                            textColor: textColor,
                          ),
                          // ---------- THEME MODE CUIPERNO SWITCH ----------
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
                            icon: CupertinoIcons.doc_text,
                            label: "Terms & Conditions",
                            onTap: () {},
                            textColor: textColor,
                          ),
                          _buildSimpleTile(
                            icon: CupertinoIcons.lock,
                            label: "Change Password",
                            onTap: () {},
                            textColor: textColor,
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
                            isDestructive: true,
                            textColor: textColor,
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
                                      return const LoginScreen();
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------- USER INFO CARD ROW ----------
  Widget _buildUserInfo(
    String label,
    String value,
    Color textColor,
    Color subTextColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      spacing: 7,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: subTextColor,
          ),
        ),

        Text(value, style: TextStyle(fontSize: 14, color: textColor)),
      ],
    );
  }

  // ---------- THIN DIVIDER ----------
  Widget _thinDivider() {
    return Divider(
      thickness: 0.5,
      color: AppTheme.primaryPink.withOpacity(0.3),
      height: 20,
    );
  }

  // ---------- SIMPLE THEMED TILE ----------
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
