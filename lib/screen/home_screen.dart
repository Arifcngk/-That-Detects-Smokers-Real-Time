// ignore_for_file: unused_local_variable, avoid_print

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

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
    loadModel();
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
        widget.cameras[0],
        ResolutionPreset.max,
        imageFormatGroup: ImageFormatGroup.nv21, // nv21 formatı kullanıldı
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

  loadModel() async {
    final modelPath = await getModelPath('assets/ml/fruits.tflite');
    final options = LocalLabelerOptions(
      confidenceThreshold: 0.8,
      modelPath: modelPath,
    );
    imageLabeler = ImageLabeler(options: options);
  }

  /// ImageLabeler başlatma işlemi
  void _initializeImageLabeler() {
    // var options = ImageLabelerOptions(confidenceThreshold: 0.5);
    // imageLabeler = ImageLabeler(options: options);
  }

  /// Gerçek zamanlı görüntü işleme işlemi
  Future<void> _doImageLabeling(CameraImage image) async {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      setState(() => isBusy = false);
      print("Input image dönüşümü başarısız.");
      return;
    }

    try {
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
    } catch (e) {
      print("Etiketleme hatası: $e");
      setState(() => isBusy = false);
    }
  }

  /// Kamera görüntüsünü InputImage'e dönüştürme işlemi
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = widget.cameras[0];
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[controller.value.deviceOrientation];
      if (rotationCompensation == null) return null;

      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }

      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || (format != InputImageFormat.nv21 && format != InputImageFormat.yuv420)) {
      print("Geçersiz format: ${image.format.raw}");
      return null;
    }

    if (image.planes.isEmpty) return null;
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

  Future<String> getModelPath(String asset) async {
    final path = '${(await getApplicationSupportDirectory()).path}/$asset';
    await Directory(dirname(path)).create(recursive: true);
    final file = File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(asset);
      await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
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
