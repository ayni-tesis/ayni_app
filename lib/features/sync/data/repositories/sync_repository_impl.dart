import 'dart:convert';
import 'dart:io';
import '../../../diagnosis/domain/entities/diagnosis.dart';
import '../../../diagnosis/domain/entities/pest_type.dart';
import '../../../diagnosis/data/models/diagnosis_api_models.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/sync_local_datasource.dart';
import '../datasources/sync_remote_datasource.dart';

class SyncRepositoryImpl implements SyncRepository {
  final SyncLocalDataSource localDataSource;
  final SyncRemoteDataSource remoteDataSource;

  SyncRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<List<Diagnosis>> getPendingDiagnoses() =>
      localDataSource.getPendingDiagnoses();

  @override
  Future<int> getPendingCount() => localDataSource.getPendingCount();

  @override
  Future<void> markAsSynced(String diagnosisId) =>
      localDataSource.markSynced([diagnosisId]);

  @override
  Future<void> markAllAsSynced(List<String> ids) =>
      localDataSource.markSynced(ids);

  @override
  Future<DateTime?> getLastSyncTime() => localDataSource.getLastSyncTime();

  @override
  Future<void> setLastSyncTime(DateTime time) =>
      localDataSource.setLastSyncTime(time);

  @override
  Future<void> savePendingDiagnosis(Diagnosis diagnosis) =>
      localDataSource.savePendingDiagnosis(diagnosis);

  @override
  Future<SyncBatchResponse> syncBatch(List<Diagnosis> diagnoses) async {
    final items = <SyncItemRequest>[];

    for (final diagnosis in diagnoses) {
      // Determinar la plaga dominante: la de mayor severity entre las infectadas.
      final infectedLeaves = diagnosis.detectedLeaves
          .where((l) => l.diagnosedPest != null && l.diagnosedPest != PestType.healthy)
          .toList();

      String dominantPest;
      double? dominantSeverity;
      double? avgConfidence;

      if (infectedLeaves.isNotEmpty) {
        // Pest con mayor severity
        final worst = infectedLeaves.reduce(
            (a, b) => (a.severity ?? 0) >= (b.severity ?? 0) ? a : b);
        dominantPest = _pestTypeToApiString(worst.diagnosedPest);
        dominantSeverity = worst.severity;
        avgConfidence = infectedLeaves
                .map((l) => l.confidence ?? 0.0)
                .reduce((a, b) => a + b) /
            infectedLeaves.length;
      } else {
        dominantPest = 'HEALTHY';
        dominantSeverity = null;
        avgConfidence = diagnosis.detectedLeaves.isNotEmpty
            ? diagnosis.detectedLeaves
                    .map((l) => l.confidence ?? 0.0)
                    .reduce((a, b) => a + b) /
                diagnosis.detectedLeaves.length
            : null;
      }

      // Leer imagen original en base64
      String? imageBase64;
      if (diagnosis.originalImagePath.isNotEmpty) {
        final file = File(diagnosis.originalImagePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          imageBase64 = base64Encode(bytes);
        }
      }

      items.add(SyncItemRequest(
        localDiagnosisId: diagnosis.id,
        pestType: dominantPest,
        confidence: avgConfidence,
        severity: dominantSeverity,
        latitude: diagnosis.latitude?.toString(),
        longitude: diagnosis.longitude?.toString(),
        capturedAt: diagnosis.dateTime,
        imageBase64: imageBase64,
      ));
    }

    final request = SyncBatchRequest(items: items);
    return remoteDataSource.syncBatch(request);
  }

  String _pestTypeToApiString(dynamic pestType) {
    if (pestType == null) return 'HEALTHY';
    final name = pestType.toString().split('.').last.toUpperCase();
    switch (name) {
      case 'ROYA':
        return 'RUST';
      case 'MINADOR':
        return 'MINER';
      case 'PHOMA':
        return 'PHOMA';
      case 'HEALTHY':
        return 'HEALTHY';
      case 'REDSPIDER':
        return 'REDSPIDER';
      default:
        return name;
    }
  }
}
