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
## 🛠️ Quick Usage

To trigger liveness detection, just call the widget inside a button press:

```dart
ElevatedButton(
  onPressed: () async {

    /// 1️⃣ Check if the device has any cameras.
    /// (We need at least one front camera to run liveness detection)
    final List<CameraDescription> cameras = await availableCameras();

    if (cameras.isNotEmpty) {

      /// 2️⃣ Open the liveness detection screen.
      /// Call the **FlutterLivenessDetection** widget — this is required.
      /// It will guide the user to blink, smile, or turn their head,
      /// then take a selfie automatically.
      final XFile? result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FlutterLivenessDetection()),
      );

      /// 3️⃣ If detection was successful, you will get a selfie image.
      if (result != null) {
        /// 4️⃣ Print the selfie image path (you can upload or save this file).
        print('Selfie path: ${result.path}');

        /// 5️⃣ Show a success message to the user.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification Successful!')),
        );
      }
    } else {
      /// ❌ No camera found → Show an error message.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not active!')),
      );
    }
  },

  /// The button users click to start liveness detection.
  child: const Text('Start Liveness Detection'),
)



