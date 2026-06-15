import '../../domain/entities/diagnosis.dart';
import 'leaf_detection_model.dart';

class DiagnosisModel extends Diagnosis {
  const DiagnosisModel({
    required super.id,
    required super.dateTime,
    required super.originalImagePath,
    required List<LeafDetectionModel> super.detectedLeaves,
    required super.isOffline,
    required super.isSynced,
    super.latitude,
    super.longitude,
  });

  factory DiagnosisModel.fromEntity(Diagnosis entity) {
    return DiagnosisModel(
      id: entity.id,
      dateTime: entity.dateTime,
      originalImagePath: entity.originalImagePath,
      detectedLeaves: entity.detectedLeaves
          .map((e) => LeafDetectionModel.fromEntity(e))
          .toList(),
      isOffline: entity.isOffline,
      isSynced: entity.isSynced,
      latitude: entity.latitude,
      longitude: entity.longitude,
    );
  }

  factory DiagnosisModel.fromJson(Map<String, dynamic> json) {
    final list = json['detectedLeaves'] as List<dynamic>;
    return DiagnosisModel(
      id: json['id'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      originalImagePath: json['originalImagePath'] as String,
      detectedLeaves: list.map((e) => LeafDetectionModel.fromJson(e as Map<String, dynamic>)).toList(),
      isOffline: json['isOffline'] as bool,
      isSynced: json['isSynced'] as bool,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'originalImagePath': originalImagePath,
      'detectedLeaves': detectedLeaves
          .map((e) => LeafDetectionModel.fromEntity(e).toJson())
          .toList(),
      'isOffline': isOffline,
      'isSynced': isSynced,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
