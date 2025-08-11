import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'moment/moment.dart';

class FlutterLivenessDetection extends StatefulWidget {
  final List<Moment> moments;
  const FlutterLivenessDetection({super.key, required this.moments});

  @override
  State<FlutterLivenessDetection> createState() => _FlutterLivenessDetectionState();
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

  @override
  void initState() {
    super.initState();
    initializeCamera();
    widget.moments.shuffle();
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front);
    cameraController = CameraController(frontCamera, ResolutionPreset.high,fps: 10, enableAudio: false);
    await cameraController.initialize();
    if (mounted) {
      setState(() {
        isCameraInitialized = true;
      });
      startFaceDetection();
    }
  }

  // void startFaceDetection() {
  //   if (isCameraInitialized) {
  //     cameraController.startImageStream((CameraImage image) {
  //       if (!isDetecting) {
  //         isDetecting = true;
  //         detectFaces(image).then((_) {
  //           isDetecting = false;
  //         });
  //       }
  //     });
  //   }
  // }

  DateTime? lastDetectionTime;

  void startFaceDetection() {
    if (isCameraInitialized) {
      cameraController.startImageStream((CameraImage image) {
        final now = DateTime.now();
        if (lastDetectionTime == null || now.difference(lastDetectionTime!) > Duration(milliseconds: 300)) {
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
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
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
        actionCompleted = face.smilingProbability != null && face.smilingProbability! > 0.5;
        break;
      case Moment.eyeblink:
        actionCompleted = (face.leftEyeOpenProbability != null && face.leftEyeOpenProbability! < 0.3) ||
            (face.rightEyeOpenProbability != null && face.rightEyeOpenProbability! < 0.3);
        break;
      case Moment.leftPose:
        actionCompleted = face.headEulerAngleY != null && face.headEulerAngleY! > 10;
        break;
      case Moment.rightPose:
        actionCompleted = face.headEulerAngleY != null && face.headEulerAngleY! < -10;
        break;
    }
    if (actionCompleted) {
      currentActionIndex++;
      if (currentActionIndex >= widget.moments.length) {
        currentActionIndex = 0;
        if (mounted) {
          final XFile selfie = await cameraController.takePicture();
          Navigator.pop(context, selfie);
        }
      } else {
        waitingForNeutral = true;
      }
    }
  }

  bool isNeutralPosition(Face face) {
    return (face.smilingProbability == null || face.smilingProbability! < 0.1) &&
        (face.leftEyeOpenProbability == null || face.leftEyeOpenProbability! > 0.7) &&
        (face.rightEyeOpenProbability == null || face.rightEyeOpenProbability! > 0.7) &&
        (face.headEulerAngleY == null || (face.headEulerAngleY! > -10 && face.headEulerAngleY! < 10));
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
      body: isCameraInitialized
              ? Stack(
                children: [
                  Positioned.fill(child: CameraPreview(cameraController)),
                  CustomPaint(painter: HeadMaskPainter(), child: Container()),
                  Positioned(
                    top: 30,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black54,
                      child: Column(
                        children: [
                          Text('Please ${getActionDescription(widget.moments[currentActionIndex])}',
                            style: const TextStyle(color: Color(0xFF39FF14), fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text('Step ${currentActionIndex + 1} of ${widget.moments.length}',
                            style: const TextStyle(color: Color(0xFF39FF14), fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF39FF14),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF39FF14).withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smile: ${smilingProbability != null ? (smilingProbability! * 100).toStringAsFixed(2) : 'N/A'}%',
                            style: const TextStyle(color: Color(0xFF39FF14)),
                          ),
                          Text(
                            'Blink: ${leftEyeOpenProbability != null && rightEyeOpenProbability != null ? (((leftEyeOpenProbability! + rightEyeOpenProbability!) / 2) * 100).toStringAsFixed(2) : 'N/A'}%',
                            style: const TextStyle(color: Color(0xFF39FF14)),
                          ),
                          Text(
                            'Look: ${headEulerAngleY != null ? headEulerAngleY!.toStringAsFixed(2) : 'N/A'}°',
                            style: const TextStyle(color: Color(0xFF39FF14)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
              : const Center(child: CircularProgressIndicator()),
    );
  }
  String getActionDescription(Moment action) {
    switch (action) {
      case Moment.smile:
        return 'smile';
      case Moment.eyeblink:
        return 'blink';
      case Moment.leftPose:
        return 'look left';
      case Moment.rightPose:
        return 'look right';
      }
  }
}

class HeadMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    final path = Path()
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
