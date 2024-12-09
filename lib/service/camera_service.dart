import 'dart:io';
import 'package:camera/camera.dart';

class CameraService {
  late CameraController controller;
  bool isBusy = false;

  Future<void> initializeCamera(List<CameraDescription> cameras,
      Function(CameraImage) onImageAvailable) async {
    try {
      controller = CameraController(
        cameras[1],
        ResolutionPreset.max,
      );
      await controller.initialize();
      controller.startImageStream((image) {
        if (!isBusy) {
          isBusy = true;
          onImageAvailable(image);
        }
      });
    } catch (e) {
      print("Kamera başlatma hatası: $e");
    }
  }

  void dispose() {
    controller.dispose();
  }
}
