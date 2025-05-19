import 'package:flutter/material.dart';

NavigationBar bottomNavbar = NavigationBar(
  onDestinationSelected: (int index) {
    //TODO: set current page here
  },
  indicatorColor: Colors.amber,
  selectedIndex: 0,
  destinations: const <Widget>[
    NavigationDestination(
      selectedIcon: Icon(Icons.home),
      icon: Icon(Icons.home_outlined),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Badge(child: Icon(Icons.notifications_sharp)),
      label: 'Notifications',
    ),
    NavigationDestination(
      icon: Badge(label: Text('2'), child: Icon(Icons.bluetooth)),
      label: 'Manage Devices'
      ,
    ),
  ],
);