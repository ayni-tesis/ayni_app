import '../../../../core/errors/failures.dart';
import '../entities/leaf_detection.dart';
import '../repositories/diagnosis_repository.dart';

class DetectLeavesUseCase {
  final DiagnosisRepository repository;

  const DetectLeavesUseCase(this.repository);

  Future<Either<Failure, List<LeafDetection>>> call(
    String originalImagePath, {
    required bool isOffline,
  }) {
    return repository.detectLeaves(originalImagePath, isOffline: isOffline);
  }
}
