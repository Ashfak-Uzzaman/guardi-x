import 'package:flutter/material.dart';
import 'package:guardix/constants/colors.dart';
import 'package:guardix/views/home_view.dart';
import 'package:guardix/views/report/report_view.dart';
import 'package:guardix/views/sos_view.dart';
import 'package:guardix/views/track_view.dart';

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({super.key});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = [
    HomeView(),
    ReportView(),
    TrackView(),
    SosView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        height: 80,
        elevation: 0,
        indicatorColor: softBlueColor,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        surfaceTintColor: blackColor,
        backgroundColor: whiteColor,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _onItemTapped(index);
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.report_gmailerrorred), label: 'Report'),
          NavigationDestination(
              icon: Icon(Icons.manage_search), label: 'Track'),
          NavigationDestination(icon: Icon(Icons.sos), label: 'SOS'),
        ],
      ),
      body: _widgetOptions[_selectedIndex],
    );
  }
}
