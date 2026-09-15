import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'pending_courses_screen.dart';
import 'manager_courses_screen.dart';
import 'manager_dashboard.dart';
import 'form_screen.dart';
import '../services/session_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  bool get _isManager => SessionService.instance.isManager;

  List<Widget> get _pages {
    if(_isManager){
      return const [ManagerDashboardScreen(), ManagerCoursesScreen()];
    }
    return const [DashboardScreen(), PendingCoursesScreen(), HistoryScreen()];
  }
  List<BottomNavigationBarItem> get _items {
    if (_isManager) {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Team'),
        BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Corsi'),
      ];
    }
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
      BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Corsi'),
      BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Storico'),
    ];
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _items,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: _isManager
          ? null
          : FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const FormScreen()));
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
