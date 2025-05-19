import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';

import 'package:smarthiking_app/screens/home.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _ble = FlutterReactiveBle();

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connectSub;
  StreamSubscription<List<int>>? _notifySub;

  var _connected = false;
  var _scanning = false;
  List<int> decoded = List.empty(growable: true); 

  @override
  initState() {
    super.initState();
  }

  @override
  void dispose() {
    if (!_connected) {
      _notifySub?.cancel();
      _connectSub?.cancel();
      _scanSub?.cancel();
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

  void _onScanUpdate(DiscoveredDevice d) {
    if (d.name == 'SH_v1' && !_connected) {
      setState(() {
        _connected = true;
        _scanning = false;
      });
      debugPrint("Found device");
      _scanSub?.cancel();
      _connectSub = _ble.connectToDevice(id: d.id).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected) {
          _onConnected(d.id);
        }
      });
    }
  }

  void _onConnected(String deviceId) {
    _ble.requestMtu(deviceId: deviceId, mtu: 512);

    final characteristic = QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: Uuid.parse('185B'),
        characteristicId: Uuid.parse('2C0A'));

    _notifySub = _ble.subscribeToCharacteristic(characteristic).listen((bytes) {
        decoded.clear();
        ByteData byteData = ByteData.sublistView(Uint8List.fromList(bytes));
        for (var i= 0; i < bytes.length;i += 2) {
          int decodedInt = byteData.getUint16(i, Endian.little);
          decoded.add(decodedInt);
        }
        debugPrint('Data: $bytes');
        debugPrint('Decoded: $decoded');
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('Connection Manager'),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: _scanning ? 
          <Widget>[
            const CircularProgressIndicator(),
            const Text("Scanning for device"),
          ]:
          <Widget>[
            TextButton(
              onPressed: _connected ? () {
                _notifySub?.cancel();
                _connectSub?.cancel();
                _scanSub?.cancel();
                setState(() {
                  _connected = false;
                });
              }:
              () {
                checkPermissions();
                setState(() {
                  _scanning = true;
                });
                _scanSub = _ble.scanForDevices(withServices: []).listen(
                  _onScanUpdate,
                  onError: (e) {
                    debugPrint('${e.name}');
                  }
                );
              },
              child: _connected ? const Text('Disconnect from device') : const Text ('Connect to device'),
            ),
          ],
        ),
      ),
    );
  }
} 