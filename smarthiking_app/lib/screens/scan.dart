import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:smarthiking_app/models/conn_manager.dart';
import 'package:smarthiking_app/widgets/bottom_navbar.dart';

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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Connection Manager'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: connManager.isScanning ? 
          <Widget>[
            const CircularProgressIndicator(),
            const Text("Scanning for device"),
            TextButton(
              onPressed: () {
                setState(() {
                  connManager.disconnect(); //Get out of jail card, in case dispose doesn't work for whatever reason
                });
              }, 
              child: Text('Cancel'))
          ]:
          <Widget>[
            TextButton(
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
              child: connManager.isConnected ? const Text('Disconnect from device') : const Text ('Connect to device'),
            ),
          ],
        ),
      ),
    );
  }
} 