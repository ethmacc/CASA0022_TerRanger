import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:smarthiking_app/models/conn_manager.dart';
import 'package:provider/provider.dart';

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
    ConnManager connManager = Provider.of<ConnManager>(context, listen:false);

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
            //Take a photo on button press
            final image = await _controller.takePicture();
            debugPrint("Picture temporarily saved at ${image.path}");
            final imageBytes = await File(image.path).readAsBytes();
            final img.Image? decodedImage = img.decodeImage(imageBytes);

            final dir = await getExternalStorageDirectory();
            if ((dir != null && decodedImage != null)) {
              int activeHike = connManager.getActiveHikeId;
              final imgPath = '${dir.path}/TerRanger_images/';
              final imgDir = await Directory(imgPath).create();

              //Get image file count and save with assigned number
              var listOfFiles = await imgDir.list(recursive: true).toList();
              var count = listOfFiles.length;
              var compressedImage = File('$imgPath/hike_${activeHike}_image_${count+1}.jpg').writeAsBytesSync(img.encodeJpg(decodedImage));
              debugPrint('Image saved as hike_${activeHike}_image_${count+1}.jpg');
            }

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
