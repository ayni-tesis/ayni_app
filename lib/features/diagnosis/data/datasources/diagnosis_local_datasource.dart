import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img_lib;
import '../../../../core/utils/image_processing_utils.dart';
import '../../domain/entities/pest_type.dart';
import '../models/diagnosis_model.dart';
import '../models/leaf_detection_model.dart';

abstract class DiagnosisLocalDataSource {
  Future<List<LeafDetectionModel>> detectLeaves(String originalImagePath);
  Future<List<LeafDetectionModel>> classifyPests(List<LeafDetectionModel> leaves);
  Future<void> saveDiagnosis(DiagnosisModel diagnosis);
  Future<List<DiagnosisModel>> getDiagnosisHistory();
  Future<void> closeInterpreters();
}

class DiagnosisLocalDataSourceImpl implements DiagnosisLocalDataSource {
  final SharedPreferences sharedPreferences;
  static const _historyKey = 'diagnosis_history_key';

  Interpreter? _leafDetector;
  Interpreter? _pestClassifier;

  DiagnosisLocalDataSourceImpl({required this.sharedPreferences});

  Future<void> _initModels() async {
    try {
      _leafDetector ??= await Interpreter.fromAsset('assets/models/leaf_detection.tflite');
      _pestClassifier ??= await Interpreter.fromAsset('assets/models/pest_classification.tflite');
    } catch (e) {
      throw Exception('Error al inicializar los modelos TFLite: ${e.toString()}');
    }
  }

  @override
  Future<void> closeInterpreters() async {
    _leafDetector?.close();
    _pestClassifier?.close();
    _leafDetector = null;
    _pestClassifier = null;
  }

  @override
  Future<List<LeafDetectionModel>> detectLeaves(String originalImagePath) async {
    await _initModels();

    final imageFile = File(originalImagePath);
    if (!await imageFile.exists()) {
      throw Exception('El archivo de imagen no existe: $originalImagePath');
    }

    final bytes = await imageFile.readAsBytes();
    final originalImage = img_lib.decodeImage(bytes);
    if (originalImage == null) {
      throw Exception('No se pudo decodificar la imagen.');
    }

    // YOLOv8 preprocessing: resize to 640x640, normalize to [0,1]
    final resized = img_lib.copyResize(
      originalImage,
      width: 640,
      height: 640,
      interpolation: img_lib.Interpolation.nearest,
    );

    // Run YOLOv8 inference: output shape [1, 5, 8400]
    final inputBuffer = _preprocessYoloInput(resized);
    final outputBuffer = Float32List(1 * 5 * 8400);
    _leafDetector!.run(inputBuffer.buffer, outputBuffer.buffer);

    // YOLOv8 postprocessing: [1, 5, 8400] → row-major [5, 8400]
    // Row 0: cx, Row 1: cy, Row 2: w, Row 3: h, Row 4: objectness score
    final candidates = <_YoloCandidate>[];
    // Minimum confidence to consider a detection valid — raised to reduce false positives
    const confThresh = 0.50;

    for (int col = 0; col < 8400; col++) {
      final confidence = outputBuffer[4 * 8400 + col];
      if (confidence > confThresh) {
        final cx = outputBuffer[0 * 8400 + col];
        final cy = outputBuffer[1 * 8400 + col];
        final w = outputBuffer[2 * 8400 + col];
        final h = outputBuffer[3 * 8400 + col];

        // Filter out detections that are too small (likely noise)
        // A valid leaf should occupy at least 2% of the 640x640 input
        if (w * 640 * h * 640 < 0.02 * 640 * 640) continue;

        candidates.add(_YoloCandidate(
          cx: cx, cy: cy, w: w, h: h, confidence: confidence,
        ));
      }
    }

    // Non-Maximum Suppression to remove overlapping boxes
    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    final selected = <_YoloCandidate>[];
    const iouThresh = 0.45;

    for (final cand in candidates) {
      bool keep = true;
      for (final sel in selected) {
        if (_calculateIoU(cand.toCropRect(), sel.toCropRect()) > iouThresh) {
          keep = false;
          break;
        }
      }
      if (keep) selected.add(cand);
    }

    // If no confident, non-overlapping detections remain → no leaf found
    if (selected.isEmpty) {
      throw Exception('No se detectaron hojas de café en la imagen. '
          'Asegúrate de fotografiar una hoja de cafeto.');
    }

    // Crop leaf regions from original image
    final rects = selected
        .take(5)
        .map((d) => d.toCropRect())
        .toList();

    final croppedPaths = await ImageProcessingUtils.cropLeaves(originalImagePath, rects);

    // Guard: ensure we have the same number of crops as detections
    if (croppedPaths.isEmpty) {
      throw Exception('No se pudieron recortar las hojas detectadas. '
          'Intenta con otra foto más clara.');
    }

    final result = <LeafDetectionModel>[];
    for (int i = 0; i < croppedPaths.length && i < rects.length; i++) {
      result.add(LeafDetectionModel(
        id: 'leaf_${DateTime.now().microsecondsSinceEpoch}_$i',
        boxX: rects[i].x,
        boxY: rects[i].y,
        boxWidth: rects[i].width,
        boxHeight: rects[i].height,
        croppedImagePath: croppedPaths[i],
      ));
    }

    return result;
  }

  Float32List _preprocessYoloInput(img_lib.Image image) {
    final buffer = Float32List(1 * 3 * 640 * 640);
    int idx = 0;
    for (int y = 0; y < 640; y++) {
      for (int x = 0; x < 640; x++) {
        final pixel = image.getPixel(x, y);
        buffer[idx++] = pixel.r / 255.0;  // R channel
        buffer[idx++] = pixel.g / 255.0;  // G channel
        buffer[idx++] = pixel.b / 255.0;  // B channel
      }
    }
    return buffer;
  }

  double _calculateIoU(CropRect a, CropRect b) {
    final xA = a.x > b.x ? a.x : b.x;
    final yA = a.y > b.y ? a.y : b.y;
    final xB = (a.x + a.width) < (b.x + b.width) ? (a.x + a.width) : (b.x + b.width);
    final yB = (a.y + a.height) < (b.y + b.height) ? (a.y + a.height) : (b.y + b.height);

    final interW = xB - xA;
    final interH = yB - yA;
    if (interW <= 0 || interH <= 0) return 0.0;

    final interArea = interW * interH;
    final areaA = a.width * a.height;
    final areaB = b.width * b.height;
    return interArea / (areaA + areaB - interArea);
  }

  @override
  Future<List<LeafDetectionModel>> classifyPests(List<LeafDetectionModel> leaves) async {
    await _initModels();

    // ImageNet normalization
    const mean = [0.485, 0.456, 0.406];
    const std  = [0.229, 0.224, 0.225];
    // Class index mapping: 0=roya, 1=redspider, 2=phoma, 3=healthy, 4=minador
    const classToPest = [
      PestType.roya, PestType.redspider, PestType.phoma,
      PestType.healthy, PestType.minador,
    ];

    final results = <LeafDetectionModel>[];

    for (final leaf in leaves) {
      try {
        final file = File(leaf.croppedImagePath);
        if (!await file.exists()) {
          results.add(_classifyFallback(leaf, 'Archivo de hoja no encontrado'));
          continue;
        }

        final bytes = await file.readAsBytes();
        final img = img_lib.decodeImage(bytes);
        if (img == null) {
          results.add(_classifyFallback(leaf, 'No se pudo decodificar la imagen de la hoja'));
          continue;
        }

        // Resize to 224x224 for EfficientNet
        final resized = img_lib.copyResize(
          img, width: 224, height: 224,
          interpolation: img_lib.Interpolation.nearest,
        );

        // Preprocess: NHWC, normalize with ImageNet mean/std
        final inputBuffer = Float32List(1 * 224 * 224 * 3);
        int idx = 0;
        for (int y = 0; y < 224; y++) {
          for (int x = 0; x < 224; x++) {
            final pixel = resized.getPixel(x, y);
            inputBuffer[idx++] = ((pixel.r / 255.0) - mean[0]) / std[0];
            inputBuffer[idx++] = ((pixel.g / 255.0) - mean[1]) / std[1];
            inputBuffer[idx++] = ((pixel.b / 255.0) - mean[2]) / std[2];
          }
        }

        // Run inference — output shape: [1, 5]
        final outputBuffer = Float32List(1 * 5);
        _pestClassifier!.run(inputBuffer.buffer, outputBuffer.buffer);

        // Find best class
        int bestClass = 0;
        double bestProb = outputBuffer[0];
        for (int i = 1; i < 5; i++) {
          if (outputBuffer[i] > bestProb) {
            bestProb = outputBuffer[i];
            bestClass = i;
          }
        }

        final pest = classToPest[bestClass];
        final updated = leaf.copyWith(
          diagnosedPest: pest,
          confidence: bestProb.toDouble(),
        );
        results.add(LeafDetectionModel.fromEntity(updated));
      } catch (e) {
        results.add(_classifyFallback(leaf, 'Error en inferencia: $e'));
      }
    }

    return results;
  }

  LeafDetectionModel _classifyFallback(LeafDetectionModel leaf, String reason) {
    print('Clasificación fallida para ${leaf.id}: $reason');
    return LeafDetectionModel.fromEntity(
      leaf.copyWith(diagnosedPest: PestType.healthy, confidence: 0.0),
    );
  }

  @override
  Future<void> saveDiagnosis(DiagnosisModel diagnosis) async {
    final history = await getDiagnosisHistory();
    final updated = [diagnosis, ...history];
    final jsonList = updated.map((d) => d.toJson()).toList();
    await sharedPreferences.setString(_historyKey, jsonEncode(jsonList));
  }

  @override
  Future<List<DiagnosisModel>> getDiagnosisHistory() async {
    final jsonString = sharedPreferences.getString(_historyKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((j) => DiagnosisModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error decodificando historial: $e');
      return [];
    }
  }
}

/// YOLOv8 detection candidate before NMS
class _YoloCandidate {
  final double cx, cy, w, h, confidence;
  const _YoloCandidate({
    required this.cx, required this.cy,
    required this.w, required this.h,
    required this.confidence,
  });

  /// Converts normalized [0,1] YOLOv8 coords to fractional CropRect (0-1).
  /// cropLeaves() will multiply by the image dimensions internally.
  CropRect toCropRect() {
    final x1 = (cx - w / 2).clamp(0.0, 1.0);
    final y1 = (cy - h / 2).clamp(0.0, 1.0);
    final x2 = (cx + w / 2).clamp(0.0, 1.0);
    final y2 = (cy + h / 2).clamp(0.0, 1.0);
    return CropRect(
      x: x1, y: y1,
      width: (x2 - x1).clamp(0.0, 1.0),
      height: (y2 - y1).clamp(0.0, 1.0),
    );
  }
}
