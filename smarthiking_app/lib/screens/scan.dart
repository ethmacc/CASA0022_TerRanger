import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:smarthiking_app/models/conn_manager.dart';
import 'package:smarthiking_app/widgets/bottom_navbar.dart';
import 'package:smarthiking_app/screens/enter_hike.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late ConnManager connManager;

  @override
  void initState() {
    super.initState();
    connManager = Provider.of<ConnManager>(context, listen:false);
  }

  @override
  void dispose() {
    if (!connManager.isConnected) { 
      setState(() {
        connManager.disconnect(); //If device not connected, abort and cancel all subscriptions
      });
    }
    super.dispose();
  }

  void checkPermissions() async {
    PermissionStatus locationPermission = await Permission.location.request();
    PermissionStatus bleScan = await Permission.bluetoothScan.request();
    PermissionStatus bleConnect = await Permission.bluetoothConnect.request();
    debugPrint('$locationPermission');
    debugPrint('$bleScan');
    debugPrint('$bleConnect');
  }

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
        title: Text('Connection Manager'),
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
          children: connManager.isScanning ? 
          <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(50, 20, 50, 20),
              child: const CircularProgressIndicator(), // Wait indicator while devices are connecting
            ),
            const Text("Scanning for device"),
            Padding(
              padding: EdgeInsets.fromLTRB(50, 20, 50, 20),
              child:
                TextButton( // Abort button
                  onPressed: () {
                    setState(() {
                      connManager.disconnect(); //Get out of jail card, in case dispose doesn't work for whatever reason
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll<Color>(Colors.grey),
                    foregroundColor: WidgetStatePropertyAll<Color>(Colors.white)
                    ), 
                  child: Text('Cancel')
                )
            )
          ]:
          <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(50, 20, 50, 20),
              child:
                connManager.isConnected ? Icon(Icons.link, color: Colors.greenAccent,) :
                Icon(Icons.link_off, color: Colors.redAccent,)
            ),
            connManager.isConnected ? Text('Smart Walking Stick Connected') : Text('Smart Walking Stick Not Connected'), //Connection status
            Padding(
              padding: EdgeInsets.fromLTRB(50, 20, 50, 20),
              child:
              TextButton( // Button for establishing connection / disconnecting
                onPressed: connManager.isConnected ? () {
                  setState(() {
                    connManager.disconnect();
                  });
                }:
                () {
                  checkPermissions();
                  setState(() {
                    connManager.connect();
                  });
                  Future.delayed(const Duration(seconds: 3), () {//boilerplate solution - wait for 3s to allow the connection manager to connect before calling setState() again
                      setState(() {
                        connManager.isScanning;
                      });
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll<Color>(Colors.grey),
                  foregroundColor: WidgetStatePropertyAll<Color>(Colors.white)
                  ),
                child: connManager.isConnected ? const Text('Disconnect from device') : const Text ('Connect to device'),
              )
            )
          ],
        ),
      ),
    );
  }
} 