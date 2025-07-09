import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terranger_lite/models/conn_manager.dart';
import 'package:terranger_lite/models/current_page.dart';
import 'package:terranger_lite/screens/sample_detail.dart';

late CameraDescription firstCam;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ConnManager()),
        ChangeNotifierProvider(create: (context) => CurrentPage()),
      ],
      child: const App()),
    );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TerRanger',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lime),
      ),
      home: SampleDetail(),
    );
  }
}
