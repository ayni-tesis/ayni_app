import 'leaf_detection.dart';
import 'pest_type.dart';

class Diagnosis {
  final String id;
  final DateTime dateTime;
  final String originalImagePath;
  final List<LeafDetection> detectedLeaves;
  final bool isOffline;
  final bool isSynced;
  final double? latitude;
  final double? longitude;

  const Diagnosis({
    required this.id,
    required this.dateTime,
    required this.originalImagePath,
    required this.detectedLeaves,
    required this.isOffline,
    required this.isSynced,
    this.latitude,
    this.longitude,
  });

  Diagnosis copyWith({
    String? id,
    DateTime? dateTime,
    String? originalImagePath,
    List<LeafDetection>? detectedLeaves,
    bool? isOffline,
    bool? isSynced,
    double? latitude,
    double? longitude,
  }) {
    return Diagnosis(
      id: id ?? this.id,
      dateTime: dateTime ?? this.dateTime,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      detectedLeaves: detectedLeaves ?? this.detectedLeaves,
      isOffline: isOffline ?? this.isOffline,
      isSynced: isSynced ?? this.isSynced,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  /// Helper to calculate the most dominant pest in the diagnosis
  String get overallStatusSummary {
    if (detectedLeaves.isEmpty) return 'No se detectaron hojas';
    final infectedCount = detectedLeaves.where((l) => l.diagnosedPest != null && l.diagnosedPest != PestType.healthy).length;
    if (infectedCount == 0) return 'Todas las hojas están sanas';
    return '$infectedCount de ${detectedLeaves.length} hojas con problemas';
  }

  bool get hasInfection {
    return detectedLeaves.any((l) => l.diagnosedPest != null && l.diagnosedPest != PestType.healthy);
  }

  @override
  String toString() {
    return 'Diagnosis(id: $id, date: $dateTime, original: $originalImagePath, leavesCount: ${detectedLeaves.length}, status: $overallStatusSummary, isOffline: $isOffline, synced: $isSynced)';
  }
}
