import 'dart:convert';
import '../../../diagnosis/data/models/diagnosis_model.dart';
import '../../../diagnosis/domain/entities/diagnosis.dart';
import 'sync_database.dart';

/// Contrato para el acceso local a la cola de sincronización.
///
/// Historicamente SharedPreferences + JSON; migrado a sqflite
/// para escalar con múltiples diagnósticos offline.
abstract class SyncLocalDataSource {
  Future<int> getPendingCount();
  Future<DateTime?> getLastSyncTime();
  Future<void> setLastSyncTime(DateTime time);
  Future<void> markSynced(List<String> ids);
  Future<List<Diagnosis>> getPendingDiagnoses();
  Future<void> savePendingDiagnosis(Diagnosis diagnosis);
}

/// Implementación con sqflite. La cola de sincronización vive en la tabla
/// `sync_queue`; la metadata (última sync) en `sync_metadata`.
class SyncLocalDataSourceImpl implements SyncLocalDataSource {
  final SyncDatabase _db;

  SyncLocalDataSourceImpl({required this._db});

  @override
  Future<int> getPendingCount() => _db.getPendingCount();

  @override
  Future<DateTime?> getLastSyncTime() async {
    final millis = await _db.getMetadata('last_sync_timestamp');
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(int.parse(millis));
  }

  @override
  Future<void> setLastSyncTime(DateTime time) =>
      _db.setMetadata('last_sync_timestamp', time.millisecondsSinceEpoch.toString());

  @override
  Future<void> markSynced(List<String> ids) => _db.markSynced(ids);

  @override
  Future<List<Diagnosis>> getPendingDiagnoses() async {
    final rows = await _db.getPendingDiagnoses();
    return rows.map((row) {
      final json = jsonDecode(row['diagnosis_json'] as String) as Map<String, dynamic>;
      return DiagnosisModel.fromJson(json);
    }).toList();
  }

  @override
  Future<void> savePendingDiagnosis(Diagnosis diagnosis) async {
    final model = DiagnosisModel.fromEntity(diagnosis);
    final json = jsonEncode(model.toJson());
    await _db.insertDiagnosis(diagnosis.id, json);
  }
}
