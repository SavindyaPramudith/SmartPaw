import 'package:flutter/material.dart';
import 'homepage.dart';
import 'geofence.dart';
import 'temperature.dart';
import 'medicationreminder.dart';
import 'history.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  final List<Widget> _screens = [
    HomeScreen(),
    GeofenceScreen(),
    TemperaturePage(),
    MedicationReminderPage(),
    HistoryPage(),
  ];

  @override
  void initState() {
    _selectedIndex = widget.initialIndex;
    super.initState();
  }

  void _onTabTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color.fromARGB(255, 223, 242, 255),
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: const Color.fromARGB(255, 38, 38, 38),
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Geofence'),
          BottomNavigationBarItem(icon: Icon(Icons.thermostat), label: 'Temp'),
          BottomNavigationBarItem(icon: Icon(Icons.medication), label: 'Meds'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}
