import '../../../diagnosis/domain/entities/diagnosis.dart';

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
}
