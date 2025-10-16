// lib/screens/client_home_screen.dart
import 'package:beauty_connect/views/views.dart';
import 'package:flutter/material.dart';
import 'package:beauty_connect/core/core.dart';

class ClientLayout extends StatefulWidget {
  const ClientLayout({super.key});

  @override
  State<ClientLayout> createState() => _ClientLayoutState();
}

class _ClientLayoutState extends State<ClientLayout> {
  final String currentUserId = SupabaseConfig.client.auth.currentUser!.id;
  int _currentIndex = 0;

  late final List<Widget> _clientPages;

  void setTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _clientPages = [
      ClientHome(),
      ChatScreen(currentUserId: currentUserId),
      ClientBookings(),
      ClientProfile(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _clientPages[_currentIndex],
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
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
