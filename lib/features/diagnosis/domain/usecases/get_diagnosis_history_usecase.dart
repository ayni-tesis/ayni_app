import '../../../../core/errors/failures.dart';
import '../entities/diagnosis.dart';
import '../repositories/diagnosis_repository.dart';

class GetDiagnosisHistoryUseCase {
  final DiagnosisRepository repository;

  const GetDiagnosisHistoryUseCase(this.repository);

  Future<Either<Failure, List<Diagnosis>>> call() {
    return repository.getDiagnosisHistory();
  }
}
