import 'package:flutter/material.dart';
import 'package:smarthiking_app/models/current_page.dart';
import 'package:smarthiking_app/models/conn_manager.dart';
import 'package:provider/provider.dart';
import 'package:smarthiking_app/screens/scan.dart';
import 'package:smarthiking_app/screens/home.dart';

class BottomNavbar extends StatelessWidget{
  const BottomNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    CurrentPage currentPage = Provider.of<CurrentPage>(context, listen:false);
    ConnManager connManager = Provider.of<ConnManager>(context, listen:false);

    return NavigationBar(
      onDestinationSelected: (int index) {
        currentPage.setPage(index);
        switch (index){
          case 0:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomePage())
            );
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScanPage())
            );
        }
      },
      indicatorColor: Colors.amber,
      selectedIndex: currentPage.getIndex,
      destinations: <Widget>[
        NavigationDestination(
          selectedIcon: Icon(Icons.home),
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        NavigationDestination(
          icon: !connManager.isConnected ? Icon(Icons.bluetooth) : Badge(backgroundColor:Colors.green, child: Icon(Icons.bluetooth)),
          label: 'Manage Devices'
          ,
        ),
      ],
    );
  }
}