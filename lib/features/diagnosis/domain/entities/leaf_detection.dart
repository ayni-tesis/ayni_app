import 'pest_type.dart';

class LeafDetection {
  final String id;
  final double boxX;
  final double boxY;
  final double boxWidth;
  final double boxHeight;
  final String croppedImagePath;
  final PestType? diagnosedPest;
  final double? confidence;
  final double? severity;

  const LeafDetection({
    required this.id,
    required this.boxX,
    required this.boxY,
    required this.boxWidth,
    required this.boxHeight,
    required this.croppedImagePath,
    this.diagnosedPest,
    this.confidence,
    this.severity,
  });

  LeafDetection copyWith({
    String? id,
    double? boxX,
    double? boxY,
    double? boxWidth,
    double? boxHeight,
    String? croppedImagePath,
    PestType? diagnosedPest,
    double? confidence,
    double? severity,
  }) {
    return LeafDetection(
      id: id ?? this.id,
      boxX: boxX ?? this.boxX,
      boxY: boxY ?? this.boxY,
      boxWidth: boxWidth ?? this.boxWidth,
      boxHeight: boxHeight ?? this.boxHeight,
      croppedImagePath: croppedImagePath ?? this.croppedImagePath,
      diagnosedPest: diagnosedPest ?? this.diagnosedPest,
      confidence: confidence ?? this.confidence,
      severity: severity ?? this.severity,
    );
  }

  @override
  String toString() {
    return 'LeafDetection(id: $id, box: [$boxX, $boxY, $boxWidth, $boxHeight], crop: $croppedImagePath, pest: $diagnosedPest, conf: $confidence, severity: $severity)';
  }
}
