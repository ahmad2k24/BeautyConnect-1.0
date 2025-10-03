import 'package:beauty_connect/views/views.dart';
import 'package:flutter/material.dart';
import 'package:beauty_connect/core/core.dart';

class VendorLayout extends StatefulWidget {
  const VendorLayout({super.key});

  @override
  State<VendorLayout> createState() => _VendorLayoutState();
}

class _VendorLayoutState extends State<VendorLayout> {
  final String currentUserId = SupabaseConfig.client.auth.currentUser!.id;
  int _currentIndex = 0;
  late final List<Widget> _vendorPages;

  void setTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _vendorPages = [
      VendorServices(),
      ChatScreen(currentUserId: currentUserId),
      const VendorAppointments(),
      const ProfileSwitcherScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _vendorPages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppTheme.primaryPink,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.design_services_outlined),
            activeIcon: Icon(Icons.design_services),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }
}
