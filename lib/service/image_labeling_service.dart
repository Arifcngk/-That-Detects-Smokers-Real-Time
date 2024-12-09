import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:camera/camera.dart';

class ImageLabelingService {
  late ImageLabeler imageLabeler;

  ImageLabelingService() {
    final options = ImageLabelerOptions(confidenceThreshold: 0.5);
    imageLabeler = ImageLabeler(options: options);
  }

  Future<String> processImage(CameraImage image, InputImage? inputImage) async {
    if (inputImage == null) return "Görüntü hatası";

    final labels = await imageLabeler.processImage(inputImage);
    String result = "";

    for (var label in labels) {
      result += "${label.label}: ${label.confidence.toStringAsFixed(2)}\n";
    }

    return result;
  }

  void dispose() {
    imageLabeler.close();
  }
}
