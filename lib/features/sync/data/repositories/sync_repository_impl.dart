import '../../../diagnosis/domain/entities/diagnosis.dart';
import '../../../diagnosis/domain/repositories/diagnosis_repository.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/sync_local_datasource.dart';

class SyncRepositoryImpl implements SyncRepository {
  final DiagnosisRepository diagnosisRepository;
  final SyncLocalDataSource localDataSource;

  SyncRepositoryImpl({
    required this.diagnosisRepository,
    required this.localDataSource,
  });

  @override
  Future<List<Diagnosis>> getPendingDiagnoses() async {
    final result = await diagnosisRepository.getDiagnosisHistory();
    return result.fold(
      (_) => <Diagnosis>[],
      (diagnoses) => diagnoses.where((d) => !d.isSynced).toList(),
    );
  }

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
}
