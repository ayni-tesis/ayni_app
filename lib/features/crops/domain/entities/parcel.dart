import 'package:flutter/foundation.dart';

@immutable
class Parcel {
  final String id;
  final String name;
  final String farmName;
  final double sizeHectares;
  final String? variety;
  final int plantCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Parcel({
    required this.id,
    required this.name,
    required this.farmName,
    required this.sizeHectares,
    this.variety,
    this.plantCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Parcel copyWith({
    String? id,
    String? name,
    String? farmName,
    double? sizeHectares,
    String? variety,
    int? plantCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Parcel(
      id: id ?? this.id,
      name: name ?? this.name,
      farmName: farmName ?? this.farmName,
      sizeHectares: sizeHectares ?? this.sizeHectares,
      variety: variety ?? this.variety,
      plantCount: plantCount ?? this.plantCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Parcel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
