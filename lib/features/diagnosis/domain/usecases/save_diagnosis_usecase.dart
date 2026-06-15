import '../../../../core/errors/failures.dart';
import '../entities/diagnosis.dart';
import '../repositories/diagnosis_repository.dart';

class SaveDiagnosisUseCase {
  final DiagnosisRepository repository;

  const SaveDiagnosisUseCase(this.repository);

  Future<Either<Failure, void>> call(Diagnosis diagnosis) {
    return repository.saveDiagnosis(diagnosis);
  }
}
