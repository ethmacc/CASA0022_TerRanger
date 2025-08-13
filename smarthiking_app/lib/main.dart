import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:smarthiking_app/screens/home.dart';
import 'package:provider/provider.dart';
import 'package:smarthiking_app/models/conn_manager.dart';
import 'package:smarthiking_app/models/current_page.dart';

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
        fontFamily: 'Bahnschrift',
        colorScheme: ColorScheme.light(
          primary: Colors.deepOrangeAccent,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.lime,
          titleTextStyle: TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 32,
          )
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.lime
        ),
        sliderTheme: SliderThemeData(
          inactiveTrackColor: Color.fromARGB(255, 236, 236, 236)
        )
      ),
      home: HomePage(title:'Home: Your Hikes'),
    );
  }
}
