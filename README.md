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
  onPressed: () async {  // Called when the button is pressed (async because we use await inside)
    
    /// 1️⃣ Get the list of available cameras on the device.
    ///    availableCameras() comes from the camera package.
    ///    It returns a List<CameraDescription>.
    final List<CameraDescription> cameras = await availableCameras();

    /// 2️⃣ Check if there is at least one camera available (we need front camera for detection)
    if (cameras.isNotEmpty) {

      /// 3️⃣ Navigate to the FlutterLivenessDetection widget.
      ///    Navigator.push() opens a new screen.
      ///    MaterialPageRoute builds the liveness detection page.
      ///    const FlutterLivenessDetection() is our custom widget that handles
      ///    - opening the front camera
      ///    - guiding the user through blink/smile/head movement challenges
      ///    - capturing a selfie when successful
      ///
      ///    WHAT YOU GET: This returns an XFile? (nullable).
      ///    If the user completes detection successfully, it will contain the selfie image file.
      final XFile? result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FlutterLivenessDetection()),
      );

      /// 4️⃣ Handle the result
      if (result != null) { // If detection was successful (user completed liveness)
        
        /// 5️⃣ Print the selfie image path in the console.
        ///     result.path gives the local file path of the captured selfie.
        print('Selfie path: ${result.path}');

        /// 6️⃣ Show a success message to the user using a Snackbar.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification Successful!')),
        );
      }
    } else {
      /// 7️⃣ If no cameras are available, show an error message.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera not active!')),
      );
    }
  },
  child: const Text('Start Liveness Detection'), // Button label
)


