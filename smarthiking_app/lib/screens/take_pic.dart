import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class TakePicturePage extends StatefulWidget {
  const TakePicturePage({super.key, required this.camera});

  final CameraDescription camera;

  @override
  TakePicturePageState createState() => TakePicturePageState();
}

class TakePicturePageState extends State<TakePicturePage> {
  //Controller to display current camera output
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    
    //Initialize contoller
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose controller on widget disposed
     _controller.dispose();
     super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      appBar: AppBar(title: const Text("Take a picture"),),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder:(context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            //If future complete, display preview
            return CameraPreview(_controller);
          } else {
            //Else display load indicatir
            return const Center (child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();
            debugPrint("PICTURE SAVED AT ${image.path}");
            if (!context.mounted) return;
          } catch (e) {
            debugPrint("$e");
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
