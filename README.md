# 🧠 flutter_liveness_detection

**flutter_liveness_detection** is a powerful and easy-to-integrate Flutter plugin that enables **real-time liveness detection** using the device’s front camera.  
This plugin validates the presence of a live human being by detecting natural facial movements such as:

- 👁️ Eye Blinking
- 😄 Smiling
- 🔄 Head movement (left and right)

> Ideal for applications that require face-based identity verification, such as **KYC**, **biometric login**, or **attendance systems**.

---

[![pub package](https://img.shields.io/pub/v/flutter_liveness_detection.svg)](https://pub.dev/packages/flutter_liveness_detection)
![Pub Points](https://img.shields.io/pub/points/flutter_liveness_detection)
![Likes](https://img.shields.io/pub/likes/flutter_liveness_detection)
[![GitHub Repo](https://img.shields.io/badge/github-rahmanprofile%2Fflutter_liveness_detection-blue?logo=github)](https://github.com/rahmanprofile/flutter_liveness_detection)

---

## 🚀 Features

- ✅ Detects facial movements to confirm user presence
- 👁️ Eye blink detection
- 😄 Smile detection
- ↔️ Head movement detection (left & right)
- 🎥 Front camera feed access
- 🧠 Real-time detection using optimized performance
- 📱 Supports both **Android** and **iOS**
- 🛠️ Easy to integrate into any Flutter project
- 🔐 Ideal for security-focused use cases

---

## 🔧 Getting Started

### 📦 Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_liveness_detection: ^0.0.4

```

---

## 📋 Permissions & Requirements

To use `flutter_liveness_detection`, ensure the following:

### ✅ Android Requirements:
- **Minimum SDK version:** `21`
- **Permissions Required:**
  Add these to your `AndroidManifest.xml` file:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

---
## 🛠️ Quick Usage

To trigger liveness detection, just call the widget inside a button press:

```dart
 ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                foregroundColor: Colors.black,
                backgroundColor: Colors.blueAccent,
              ),
              onPressed: () async {
                // Step 1: Get the list of available cameras on the device
                final List<CameraDescription> cameras = await availableCameras();

                // Step 2: Proceed only if there's at least one camera (front camera)
                if (cameras.isNotEmpty) {
                  // 🧠 You can set any 2 or more actions from below to verify the user is real.
                  // The user will be asked to perform these actions for verification.
                  List<Moment> challengeActions = [
                    Moment.smile,       // 😀 Ask user to smile
                    Moment.eyeblink,    // 👁️ Ask user to blink
                    Moment.leftPose,    // 👈 Turn head left
                    Moment.rightPose,   // 👉 Turn head right
                  ];

                  // Step 3: Start the liveness detection screen with defined actions, Call this widget 'FlutterLivenessDetection'
                  final XFile? result = await Navigator.push(context,
                    MaterialPageRoute(
                      builder: (context) => FlutterLivenessDetection(moments: challengeActions),
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
              child: const Text('Verify Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ),



