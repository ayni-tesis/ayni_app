import '../../domain/entities/leaf_detection.dart';
import '../../domain/entities/pest_type.dart';

class LeafDetectionModel extends LeafDetection {
  const LeafDetectionModel({
    required super.id,
    required super.boxX,
    required super.boxY,
    required super.boxWidth,
    required super.boxHeight,
    required super.croppedImagePath,
    super.diagnosedPest,
    super.confidence,
  });

  factory LeafDetectionModel.fromEntity(LeafDetection entity) {
    return LeafDetectionModel(
      id: entity.id,
      boxX: entity.boxX,
      boxY: entity.boxY,
      boxWidth: entity.boxWidth,
      boxHeight: entity.boxHeight,
      croppedImagePath: entity.croppedImagePath,
      diagnosedPest: entity.diagnosedPest,
      confidence: entity.confidence,
    );
  }

  factory LeafDetectionModel.fromJson(Map<String, dynamic> json) {
    return LeafDetectionModel(
      id: json['id'] as String,
      boxX: (json['boxX'] as num).toDouble(),
      boxY: (json['boxY'] as num).toDouble(),
      boxWidth: (json['boxWidth'] as num).toDouble(),
      boxHeight: (json['boxHeight'] as num).toDouble(),
      croppedImagePath: json['croppedImagePath'] as String,
      diagnosedPest: json['diagnosedPest'] != null
          ? PestType.values.firstWhere((e) => e.name == json['diagnosedPest'])
          : null,
      confidence: json['confidence'] != null ? (json['confidence'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'boxX': boxX,
      'boxY': boxY,
      'boxWidth': boxWidth,
      'boxHeight': boxHeight,
      'croppedImagePath': croppedImagePath,
      'diagnosedPest': diagnosedPest?.name,
      'confidence': confidence,
    };
  }
}
