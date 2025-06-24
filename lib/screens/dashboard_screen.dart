import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'favorite_screen.dart';
import 'profile_screen.dart';
import 'data_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),      // index 0 - Home tab
    MapScreen(),       // index 1 - Map tab
    FavoriteScreen(),  // index 2 - Favorites tab
    DataScreen(),      // index 3 - Data tab <<<< INI HARUS DATASCREEN
    ProfileScreen(),   // index 4 - Profile tab
  ];

  void _onItemTapped(int index) {
    print('Tab clicked: $index, Screen count: ${_screens.length}');
    if (index >= 0 && index < _screens.length) {
      setState(() {
        _selectedIndex = index;
      });
      print('New selected index: $_selectedIndex');
      print('Screen at index $index: ${_screens[index].runtimeType}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pastikan _selectedIndex tidak melebihi jumlah screens
    if (_selectedIndex >= _screens.length) {
      _selectedIndex = 0;
    }

    print('Building with selected index: $_selectedIndex');
    print('Current screen: ${_screens[_selectedIndex].runtimeType}');

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Color(0xFF0E3854),
        unselectedItemColor: Color(0xFF0E3854),
        iconSize: 35,
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 0 ? Icons.home : Icons.home_outlined,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 1 ? Icons.location_on : Icons.location_on_outlined,
            ),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 2 ? Icons.favorite : Icons.favorite_border,
            ),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 3 ? Icons.data_usage : Icons.data_usage_outlined,
            ),
            label: 'Data',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _selectedIndex == 4 ? Icons.person : Icons.person_outline,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}