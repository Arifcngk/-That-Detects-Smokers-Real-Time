// ignore_for_file: unused_local_variable

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

class HomeScreenPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HomeScreenPage({super.key, required this.cameras});

  @override
  State<HomeScreenPage> createState() => _HomeScreenPageState();
}

class _HomeScreenPageState extends State<HomeScreenPage> {
  late CameraController controller;
  bool _isCameraInitialized = false;
  bool isBusy = false;
  late ImageLabeler imageLabeler;
  String result = "Sonuç bekleniyor...";

  // Cihaz yönelimi eşleşmeleri
  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeImageLabeler();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Kamera başlatma işlemi
  Future<void> _initializeCamera() async {
    try {
      controller = CameraController(
        widget.cameras[1],
        ResolutionPreset.max,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();

      if (!mounted) return;

      controller.startImageStream((image) {
        if (!isBusy) {
          isBusy = true;
          _doImageLabeling(image);
        }
      });

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print("Kamera başlatma hatası: $e");
    }
  }

  /// ImageLabeler başlatma işlemi
  void _initializeImageLabeler() {
    var options = ImageLabelerOptions(confidenceThreshold: 0.5);
    imageLabeler = ImageLabeler(options: options);
  }

  /// Gerçek zamanlı görüntü işleme işlemi
  Future<void> _doImageLabeling(CameraImage image) async {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      setState(() => isBusy = false);
      return;
    }

    final labels = await imageLabeler.processImage(inputImage);
    print("Etiket sayısı: ${labels.length}");

    if (labels.isEmpty) {
      print("Hiçbir etiket tespit edilmedi.");
    }

    // Sonuçları biriktirmek için StringBuffer kullanımı
    final buffer = StringBuffer();
    for (final label in labels) {
      buffer.writeln("${label.label}: ${label.confidence.toStringAsFixed(2)}");
    }

    setState(() {
      result = buffer.toString();
      isBusy = false;
    });
  }

  /// Kamera görüntüsünü InputImage'e dönüştürme işlemi
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = widget.cameras[1];
    final sensorOrientation = camera.sensorOrientation;

    // Platforma göre döndürme hesaplaması
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[controller.value.deviceOrientation];
      if (rotationCompensation == null) return null;

      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }

      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    // Format kontrolü
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Gerçek Zamanlı Görüntü İşleme"),
      ),
      body: Center(
        child: _isCameraInitialized
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height / 1.5,
                        width: MediaQuery.of(context).size.width / 1.1,
                        child: AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: CameraPreview(controller),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(result),
                  ],
                ),
              )
            : const CircularProgressIndicator(), // Kamera başlatılana kadar yükleme göstergesi
      ),
    );
  }
}
