import '../../../diagnosis/domain/entities/diagnosis.dart';
import '../../../diagnosis/data/models/diagnosis_api_models.dart';

abstract class SyncRepository {
  /// Returns all diagnoses that have not been synced yet (isSynced == false)
  Future<List<Diagnosis>> getPendingDiagnoses();

  /// Returns the total count of unsynced diagnoses
  Future<int> getPendingCount();

  /// Marks a diagnosis as synced
  Future<void> markAsSynced(String diagnosisId);

  /// Marks all given diagnosis IDs as synced
  Future<void> markAllAsSynced(List<String> ids);

  /// Gets the last successful sync timestamp
  Future<DateTime?> getLastSyncTime();

  /// Saves the last successful sync timestamp
  Future<void> setLastSyncTime(DateTime time);

  /// Persists a new offline diagnosis to the local sync queue (sqflite).
  Future<void> savePendingDiagnosis(Diagnosis diagnosis);

  /// Sends a batch of offline diagnoses to the history-sync-service via POST /sync/batch.
  /// Returns the batch response with counts, or throws on network failure.
  Future<SyncBatchResponse> syncBatch(List<Diagnosis> diagnoses);
}
