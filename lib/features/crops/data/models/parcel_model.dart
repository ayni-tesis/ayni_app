import '../../domain/entities/parcel.dart';

class ParcelModel extends Parcel {
  const ParcelModel({
    required super.id,
    required super.name,
    required super.farmName,
    required super.sizeHectares,
    super.variety,
    super.plantCount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ParcelModel.fromJson(Map<String, dynamic> json) {
    return ParcelModel(
      id: json['id'] as String,
      name: json['name'] as String,
      farmName: json['farmName'] as String,
      sizeHectares: (json['sizeHectares'] as num).toDouble(),
      variety: json['variety'] as String?,
      plantCount: json['plantCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'farmName': farmName,
      'sizeHectares': sizeHectares,
      'variety': variety,
      'plantCount': plantCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ParcelModel.fromEntity(Parcel parcel) {
    return ParcelModel(
      id: parcel.id,
      name: parcel.name,
      farmName: parcel.farmName,
      sizeHectares: parcel.sizeHectares,
      variety: parcel.variety,
      plantCount: parcel.plantCount,
      createdAt: parcel.createdAt,
      updatedAt: parcel.updatedAt,
    );
  }
}
