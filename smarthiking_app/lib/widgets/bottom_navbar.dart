import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:smarthiking_app/models/current_page.dart';
import 'package:smarthiking_app/models/conn_manager.dart';
import 'package:provider/provider.dart';
import 'package:smarthiking_app/screens/scan.dart';
import 'package:smarthiking_app/screens/home.dart';
import 'package:smarthiking_app/screens/backup.dart';
import 'package:smarthiking_app/screens/take_pic.dart';

class BottomNavbar extends StatelessWidget{
  const BottomNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    CurrentPage currentPage = Provider.of<CurrentPage>(context, listen:false);
    ConnManager connManager = Provider.of<ConnManager>(context, listen:false);

    void pushTakePicPage () async {
      // Obtain a list of the available cameras on the device.
      final cameras = await availableCameras();

      // Get a specific camera from the list of available cameras.
      final firstCamera = cameras.first;
      Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TakePicturePage(camera: firstCamera))
      );
    }

    return NavigationBar(
      onDestinationSelected: (int index) {
        currentPage.setPage(index);
        switch (index) {
          case 0:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage(title: 'Home: Your Hikes'))
            );
          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ScanPage())
            );
          case 2:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BackupPage())
            );
        }
      },
      indicatorColor: Colors.white,
      selectedIndex: currentPage.getIndex,
      destinations: <Widget>[
        NavigationDestination(
          selectedIcon: Icon(Icons.home),
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        //NavigationDestination(
          //icon: Icon(Icons.camera), 
          //label: 'Camera'
        //),
        NavigationDestination(
          icon: !connManager.isConnected ? Icon(Icons.bluetooth) : Badge(backgroundColor:Colors.green, child: Icon(Icons.bluetooth)),
          label: 'Devices'
          ,
        ),
        NavigationDestination(
          icon: Icon(Icons.file_download), 
          label: 'Backups'
        ),
        Padding(padding: EdgeInsets.all(20))
      ],
    );
  }
}