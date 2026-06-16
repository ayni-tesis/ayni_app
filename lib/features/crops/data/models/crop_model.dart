import '../../domain/entities/crop.dart';

class CropModel extends Crop {
  const CropModel({
    required super.id,
    required super.parcelId,
    required super.name,
    required super.variety,
    super.plantingDate,
    super.status,
    super.lastDiagnosisDaysAgo,
    super.lastDiagnosisPest,
    super.latitude,
    super.longitude,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CropModel.fromJson(Map<String, dynamic> json) {
    return CropModel(
      id: json['id'] as String,
      parcelId: json['parcelId'] as String,
      name: json['name'] as String,
      variety: CoffeeVariety.values.firstWhere(
        (v) => v.name == json['variety'],
        orElse: () => CoffeeVariety.other,
      ),
      plantingDate: json['plantingDate'] != null
          ? DateTime.parse(json['plantingDate'] as String)
          : null,
      status: PlantStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PlantStatus.healthy,
      ),
      lastDiagnosisDaysAgo: json['lastDiagnosisDaysAgo'] as int?,
      lastDiagnosisPest: json['lastDiagnosisPest'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parcelId': parcelId,
      'name': name,
      'variety': variety.name,
      'plantingDate': plantingDate?.toIso8601String(),
      'status': status.name,
      'lastDiagnosisDaysAgo': lastDiagnosisDaysAgo,
      'lastDiagnosisPest': lastDiagnosisPest,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CropModel.fromEntity(Crop crop) {
    return CropModel(
      id: crop.id,
      parcelId: crop.parcelId,
      name: crop.name,
      variety: crop.variety,
      plantingDate: crop.plantingDate,
      status: crop.status,
      lastDiagnosisDaysAgo: crop.lastDiagnosisDaysAgo,
      lastDiagnosisPest: crop.lastDiagnosisPest,
      latitude: crop.latitude,
      longitude: crop.longitude,
      createdAt: crop.createdAt,
      updatedAt: crop.updatedAt,
    );
  }
}
