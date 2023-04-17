import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:tflite/tflite.dart';

import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = '';
  int cam = 1;

  // @override
  // void initState() {
  //   // TODO: implement initState
  //   super.initState();
  //   loadModel();
  //   loadCamera();
  // }

  loadCamera() async {
    cameraController = CameraController(cameras![cam], ResolutionPreset.medium);
    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      } else {
        setState(() {
          cameraController!.startImageStream((imageStream) {
            cameraImage = imageStream;
            runModel();
          });
        });
      }
    });
  }

  runModel() async {
    if (cameraImage != null) {
      // var preditions = await Tflite.runModelOnImage(path: path)
      var predictions = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        // model: "SSDMobileNet",
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 127.5, // defaults to 127.5
        imageStd: 127.5, // defaults to 127.5
        rotation: 90, // defaults to 90, Android only
        numResults: 2, // defaults to 5
        threshold: 0.1, // defaults to 0.1
        asynch: true,
      );

      for (var element in predictions!) {
        setState(() {
          output = element['label'];
          // print(
          //     "_____________________________ $output _________________________");
        });
        // print("******test:$element*******");
      }
    }
    // sleep(Duration(seconds: 1));
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
    loadCamera();
  }

  Future<void> secureScreen() async {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }

  @override
  void initState() {
    // TODO: implement initState
    secureScreen();
    super.initState();
    loadModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Live Emotion"),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              width: MediaQuery.of(context).size.width,
              child: !cameraController!.value.isInitialized
                  ? Container()
                  : Container(
                      // aspectRatio: cameraController!.value.aspectRatio,
                      child: CameraPreview(cameraController!),
                    ),
            ),
          ),
          Container(
            child: Text(
              output == "" ? "Check" : output,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                cam = 1 - cam;
                loadCamera();
              });
            },
            icon: Icon(
              Icons.cameraswitch_sharp,
            ),
          ),
        ],
      ),
    );
  }
}
