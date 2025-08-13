import 'package:flutter/material.dart';
import 'package:smarthiking_app/widgets/bottom_navbar.dart';
import 'package:smarthiking_app/screens/enter_hike.dart';
import 'package:smarthiking_app/models/db_manager.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavbar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EnterHike())
            );
        },
        child: Icon(Icons.add)
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterDocked,
      appBar: AppBar(
        title: Text('Backups'),
        actions: [
          Image(
            image: AssetImage('assets/terraenger_logo.png'),
            width: 100,
            )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              onPressed: () {
                exportBackup();
              }, 
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll<Color>(const Color.fromARGB(255, 236, 236, 236)),
                foregroundColor: WidgetStatePropertyAll<Color>(Colors.green),
              ),
              icon: Icon(Icons.ios_share),
            ),
            Text('Export backup'),
            Padding(padding: EdgeInsets.all(20)),
              IconButton(
              onPressed: () {
                importBackup();
              }, 
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll<Color>(const Color.fromARGB(255, 236, 236, 236)),
                foregroundColor: WidgetStatePropertyAll<Color>(Colors.red),
              ),
              icon: Icon(Icons.download),
            ),
            Text('Import backup'),
          ],
        )
      )
    );
  }
}