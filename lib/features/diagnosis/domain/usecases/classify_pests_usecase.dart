import '../../../../core/errors/failures.dart';
import '../entities/leaf_detection.dart';
import '../repositories/diagnosis_repository.dart';

class ClassifyPestsUseCase {
  final DiagnosisRepository repository;

  const ClassifyPestsUseCase(this.repository);

  Future<Either<Failure, List<LeafDetection>>> call(
    List<LeafDetection> detectedLeaves, {
    required bool isOffline,
  }) {
    return repository.classifyPests(detectedLeaves, isOffline: isOffline);
  }
}
