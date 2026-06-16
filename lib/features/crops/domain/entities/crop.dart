import 'package:flutter/foundation.dart';

enum CoffeeVariety {
  bourbon('Bourbon'),
  catimor('Catimor'),
  typica('Typica'),
  geisha('Geisha'),
  caturra('Caturra'),
  pacamara('Pacamara'),
  castillo('Castillo'),
  other('Otra');

  final String displayName;
  const CoffeeVariety(this.displayName);
}

enum PlantStatus {
  healthy('Sana'),
  withPest('Con plaga'),
  needsAttention('Requiere atención');

  final String displayName;
  const PlantStatus(this.displayName);
}

@immutable
class Crop {
  final String id;
  final String parcelId;
  final String name;
  final CoffeeVariety variety;
  final DateTime? plantingDate;
  final PlantStatus status;
  final int? lastDiagnosisDaysAgo;
  final String? lastDiagnosisPest;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Crop({
    required this.id,
    required this.parcelId,
    required this.name,
    required this.variety,
    this.plantingDate,
    this.status = PlantStatus.healthy,
    this.lastDiagnosisDaysAgo,
    this.lastDiagnosisPest,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  Crop copyWith({
    String? id,
    String? parcelId,
    String? name,
    CoffeeVariety? variety,
    DateTime? plantingDate,
    PlantStatus? status,
    int? lastDiagnosisDaysAgo,
    String? lastDiagnosisPest,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Crop(
      id: id ?? this.id,
      parcelId: parcelId ?? this.parcelId,
      name: name ?? this.name,
      variety: variety ?? this.variety,
      plantingDate: plantingDate ?? this.plantingDate,
      status: status ?? this.status,
      lastDiagnosisDaysAgo: lastDiagnosisDaysAgo ?? this.lastDiagnosisDaysAgo,
      lastDiagnosisPest: lastDiagnosisPest ?? this.lastDiagnosisPest,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Crop && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
