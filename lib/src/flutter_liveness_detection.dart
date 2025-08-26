import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'moment/moment.dart';

class FlutterLivenessDetection extends StatefulWidget {
  final List<Moment> moments;
  const FlutterLivenessDetection({super.key, required this.moments});

  @override
  State<FlutterLivenessDetection> createState() =>
      _FlutterLivenessDetectionState();
}

class _FlutterLivenessDetectionState extends State<FlutterLivenessDetection> {
  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      minFaceSize: 0.3,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  late CameraController cameraController;
  bool isCameraInitialized = false;
  bool isDetecting = false;
  bool isFrontCamera = true;
  int currentActionIndex = 0;
  bool waitingForNeutral = false;

  double? smilingProbability;
  double? leftEyeOpenProbability;
  double? rightEyeOpenProbability;
  double? headEulerAngleY;
  List<XFile> capturedImages = [];
  @override
  void initState() {
    super.initState();
    initializeCamera();
    widget.moments.shuffle();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await cameraController.initialize();
    if (mounted) {
      setState(() {
        isCameraInitialized = true;
      });
      startFaceDetection();
    }
  }

  DateTime? lastDetectionTime;

  void startFaceDetection() {
    if (isCameraInitialized) {
      cameraController.startImageStream((CameraImage image) {
        final now = DateTime.now();
        if (lastDetectionTime == null ||
            now.difference(lastDetectionTime!) > Duration(milliseconds: 300)) {
          lastDetectionTime = now;
          if (!isDetecting) {
            isDetecting = true;
            detectFaces(image).then((_) {
              isDetecting = false;
            });
          }
        }
      });
    }
  }

  Future<void> detectFaces(CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      // final bytes = allBytes.done().buffer.asUint8List();
      final bytes = yuv420ToNv21(image);
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width,
        ),
      );
      final faces = await faceDetector.processImage(inputImage);
      if (!mounted) return;
      if (faces.isNotEmpty) {
        final face = faces.first;
        setState(() {
          smilingProbability = face.smilingProbability;
          leftEyeOpenProbability = face.leftEyeOpenProbability;
          rightEyeOpenProbability = face.rightEyeOpenProbability;
          headEulerAngleY = face.headEulerAngleY;
        });
        checkChallenge(face);
      }
    } catch (e) {
      debugPrint('Error in face detection: $e');
    }
  }

  Uint8List yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final ySize = width * height;
    final uvSize = width ~/ 2 * height ~/ 2;
    final nv21 = Uint8List(ySize + uvSize * 2);
    // Copy Y plane
    int index = 0;
    for (int row = 0; row < height; row++) {
      final start = row * image.planes[0].bytesPerRow;
      nv21.setRange(
        index,
        index + width,
        image.planes[0].bytes.sublist(start, start + width),
      );
      index += width;
    }

    // Copy interleaved VU (NV21)
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;
    for (int row = 0; row < height ~/ 2; row++) {
      for (int col = 0; col < width ~/ 2; col++) {
        final uIndex = row * image.planes[1].bytesPerRow + col;
        final vIndex = row * image.planes[2].bytesPerRow + col;
        nv21[index++] = vPlane[vIndex];
        nv21[index++] = uPlane[uIndex];
      }
    }
    return nv21;
  }

  // Uint8List convertYUV420toNV21(CameraImage image) {
  //   final yPlane = image.planes[0].bytes;
  //   final uPlane = image.planes[1].bytes;
  //   final vPlane = image.planes[2].bytes;
  //
  //   final nv21 = Uint8List(yPlane.length + uPlane.length + vPlane.length);
  //   int index = 0;
  //
  //   // Copy Y plane
  //   nv21.setRange(0, yPlane.length, yPlane);
  //   index += yPlane.length;
  //
  //   // Interleave V and U
  //   for (int i = 0; i < uPlane.length; i++) {
  //     nv21[index++] = vPlane[i];
  //     nv21[index++] = uPlane[i];
  //   }
  //
  //   return nv21;
  // }

  void checkChallenge(Face face) async {
    if (waitingForNeutral) {
      if (isNeutralPosition(face)) {
        waitingForNeutral = false;
      } else {
        return;
      }
    }

    Moment currentAction = widget.moments[currentActionIndex];
    bool actionCompleted = false;
    switch (currentAction) {
      case Moment.smile:
        actionCompleted =
            face.smilingProbability != null && face.smilingProbability! > 0.5;
        break;
      case Moment.eyeblink:
        actionCompleted =
            (face.leftEyeOpenProbability != null &&
                face.leftEyeOpenProbability! < 0.3) ||
            (face.rightEyeOpenProbability != null &&
                face.rightEyeOpenProbability! < 0.3);
        break;
      case Moment.leftPose:
        actionCompleted =
            face.headEulerAngleY != null && face.headEulerAngleY! > 10;
        break;
      case Moment.rightPose:
        actionCompleted =
            face.headEulerAngleY != null && face.headEulerAngleY! < -10;
        break;
    }
    if (actionCompleted) {
      final XFile image = await cameraController.takePicture();
      setState(() {
        capturedImages.add(image);
        log("message ${capturedImages.length}");
      });
      currentActionIndex++;
      if (currentActionIndex >= widget.moments.length) {
        currentActionIndex = 0;
        if (mounted) {
          final XFile selfie = await cameraController.takePicture();
          // Navigator.pop(context, selfie);
          Navigator.pop(context, capturedImages);
        }
      } else {
        waitingForNeutral = true;
      }
    }
  }

  bool isNeutralPosition(Face face) {
    return (face.smilingProbability == null ||
            face.smilingProbability! < 0.1) &&
        (face.leftEyeOpenProbability == null ||
            face.leftEyeOpenProbability! > 0.7) &&
        (face.rightEyeOpenProbability == null ||
            face.rightEyeOpenProbability! > 0.7) &&
        (face.headEulerAngleY == null ||
            (face.headEulerAngleY! > -10 && face.headEulerAngleY! < 10));
  }

  @override
  void dispose() {
    cameraController.stopImageStream();
    faceDetector.close();
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          isCameraInitialized
              ? Stack(
                children: [
                  Positioned.fill(child: CameraPreview(cameraController)),
                  CustomPaint(painter: HeadMaskPainter(), child: Container()),
                  Positioned(
                    bottom: 200,
                    left: 16,
                    right: 16,
                    child: Text(
                      'Please ${getActionDescription(widget.moments[currentActionIndex])}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.info, color: Color(0xFF8921FF), size: 30),
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width * 0.82,
                            child: Text(
                              (currentActionIndex + 1) == 4
                                  ? "Make sure you’re in good light position and remove hats or sunglasses"
                                  : 'Hold still while we capture your face. Use good lighting, and remove hats or sunglasses.',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 30,
                    left: 20,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: CircleAvatar(
                        backgroundColor: Color(0xFFE9E3FF),
                        child: Icon(CupertinoIcons.back),
                      ),
                    ),
                  ),
                  // Positioned(
                  //   bottom: 16,
                  //   left: 16,
                  //   child: Container(
                  //     decoration: BoxDecoration(
                  //       color: Colors.black54,
                  //       borderRadius: BorderRadius.circular(10),
                  //       border: Border.all(
                  //         color: const Color(0xFF39FF14),
                  //         width: 2.0,
                  //       ),
                  //       boxShadow: [
                  //         BoxShadow(
                  //           color: const Color(
                  //             0xFF39FF14,
                  //           ).withValues(alpha: 0.2),
                  //           blurRadius: 8,
                  //           spreadRadius: 2,
                  //         ),
                  //       ],
                  //     ),
                  //     padding: const EdgeInsets.all(12),
                  //     child: Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Text(
                  //           'Smile: ${smilingProbability != null ? (smilingProbability! * 100).toStringAsFixed(2) : 'N/A'}%',
                  //           style: const TextStyle(color: Color(0xFF39FF14)),
                  //         ),
                  //         Text(
                  //           'Blink: ${leftEyeOpenProbability != null && rightEyeOpenProbability != null ? (((leftEyeOpenProbability! + rightEyeOpenProbability!) / 2) * 100).toStringAsFixed(2) : 'N/A'}%',
                  //           style: const TextStyle(color: Color(0xFF39FF14)),
                  //         ),
                  //         Text(
                  //           'Look: ${headEulerAngleY != null ? headEulerAngleY!.toStringAsFixed(2) : 'N/A'}°',
                  //           style: const TextStyle(color: Color(0xFF39FF14)),
                  //         ),
                  //         Text(
                  //           'Version: 0.0.6',
                  //           style: TextStyle(color: Color(0xFF39FF14)),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                ],
              )
              : const Center(child: CircularProgressIndicator()),
    );
  }

  String getActionDescription(Moment action) {
    switch (action) {
      case Moment.smile:
        return 'Face the camera directly';
      case Moment.eyeblink:
        return 'Face the camera directly';
      case Moment.leftPose:
        return 'Slowly turn your head left';
      case Moment.rightPose:
        return 'Slowly turn your head right';
    }
  }
}

class HeadMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    final path =
        Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
          ..addOval(Rect.fromCircle(center: center, radius: radius))
          ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
