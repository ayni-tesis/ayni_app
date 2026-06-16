import 'dart:io';
import 'package:image/image.dart' as img_lib;

class CropRect {
  final double x; // 0.0 to 1.0 (relative)
  final double y; // 0.0 to 1.0 (relative)
  final double width; // 0.0 to 1.0 (relative)
  final double height; // 0.0 to 1.0 (relative)

  const CropRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  @override
  String toString() => 'CropRect(x: $x, y: $y, w: $width, h: $height)';
}

class ImageProcessingUtils {
  ImageProcessingUtils._();

  /// Crops an image into multiple sub-images based on fractional bounding boxes.
  /// Saves the cropped files in the same directory as the original image.
  /// Returns a list of file paths to the cropped images.
  static Future<List<String>> cropLeaves(
    String originalImagePath,
    List<CropRect> boxes,
  ) async {
    final croppedPaths = <String>[];
    final originalFile = File(originalImagePath);

    if (!await originalFile.exists()) {
      return croppedPaths;
    }

    try {
      final bytes = await originalFile.readAsBytes();
      final image = img_lib.decodeImage(bytes);

      if (image == null) {
        return croppedPaths;
      }

      final parentDirectory = originalFile.parent.path;
      final timestamp = DateTime.now().microsecondsSinceEpoch;

      for (int i = 0; i < boxes.length; i++) {
        final box = boxes[i];

        // Convert fractional coordinates to absolute pixels
        int x = (box.x * image.width).toInt();
        int y = (box.y * image.height).toInt();
        int w = (box.width * image.width).toInt();
        int h = (box.height * image.height).toInt();

        // Boundary safety clamps
        if (x < 0) x = 0;
        if (y < 0) y = 0;
        if (x + w > image.width) w = image.width - x;
        if (y + h > image.height) h = image.height - y;

        // Skip invalid bounding boxes
        if (w <= 0 || h <= 0) continue;

        // Crop image using package:image
        final croppedImage = img_lib.copyCrop(
          image,
          x: x,
          y: y,
          width: w,
          height: h,
        );

        // Encode as JPEG
        final croppedBytes = img_lib.encodeJpg(croppedImage, quality: 85);

        // Save file
        final croppedPath = '$parentDirectory/crop_${timestamp}_$i.jpg';
        final croppedFile = File(croppedPath);
        await croppedFile.writeAsBytes(croppedBytes);

        croppedPaths.add(croppedPath);
      }
    } catch (e) {
      // Avoid failing hard, log and return whatever we managed to crop
      // or an empty list.
      // TODO: replace with proper logging framework (dart:developer log)
    }

    return croppedPaths;
  }
}
