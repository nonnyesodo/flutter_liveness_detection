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
  flutter_liveness_detection: ^0.0.2

```
---
## 🛠️ Quick Usage

To trigger liveness detection, just call the widget inside a button press:

```dart
ElevatedButton(
  onPressed: () async {
    // Step 1: Get available cameras
    final cameras = await availableCameras();

    if (cameras.isNotEmpty) {
      // Step 2: Navigate to the liveness detection screen
      final XFile? result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FlutterLivenessDetection()),
      );

      // Step 3: Handle the result
      if (result != null) {
        // You get a captured selfie
        print('Selfie path: ${result.path}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification Successful!')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not active!')),
      );
    }
  },
  child: const Text('Start Liveness Detection'),
)

