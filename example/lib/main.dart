import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liveness_detection/flutter_liveness_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestCameraPermission();
  runApp(const MyApp());
}

Future<void> requestCameraPermission() async {
  final status = await Permission.camera.request();
  if (!status.isGranted) {
    runApp(const PermissionDeniedApp());
  }
}

class PermissionDeniedApp extends StatelessWidget {
  const PermissionDeniedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text("Permission Denied")),
        body: Center(
          child: AlertDialog(
            title: const Text("Permission Denied"),
            content: const Text("Camera access is required for verification."),
            actions: [
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material App',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? imageFile;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        toolbarHeight: 70,
        centerTitle: true,
        title: const Text('Identify'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Please click the button below to start verification',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 30),
            (imageFile != null)
                ? SizedBox(
                  height: 200,
                  width: 150,
                  child: Image.file(imageFile!),
                )
                : SizedBox(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                foregroundColor: Colors.black,
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: () async {
                // Step 1: Get the list of available cameras on the device
                final List<CameraDescription> cameras =
                    await availableCameras();

                // Step 2: Proceed only if there's at least one camera (front camera)
                if (cameras.isNotEmpty) {
                  // 🧠 You can set any 2 or more actions from below to verify the user is real.
                  // The user will be asked to perform these actions for verification.
                  List<Moment> challengeActions = [
                    Moment.smile, // 😀 Ask user to smile
                    Moment.eyeblink, // 👁️ Ask user to blink
                    Moment.leftPose, // 👈 Turn head left
                    Moment.rightPose, // 👉 Turn head right
                  ];

                  // Step 3: Start the liveness detection screen with defined actions, Call this widget 'FlutterLivenessDetection'
                  final XFile? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => FlutterLivenessDetection(
                            moments: challengeActions,
                          ),
                    ),
                  );

                  // Step 4: If selfie is returned, that means verification passed
                  if (result != null) {
                    setState(() {
                      imageFile = File(result.path);
                    });

                    // Step 5: You can save/upload the image. Show success message.
                    print('Selfie path: ${result.path}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification Successful!')),
                    );
                  }
                } else {
                  // ❌ No camera found on device
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Camera not active!')),
                  );
                }
              },
              child: const Text(
                'Verify Now',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
