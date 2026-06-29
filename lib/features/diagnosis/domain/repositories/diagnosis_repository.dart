import '../../../../core/errors/failures.dart';
import '../entities/diagnosis.dart';
import '../entities/leaf_detection.dart';

abstract class DiagnosisRepository {
  /// Obtiene la URL de la última imagen subida y detectada online.
  String? get latestDetectionImageUrl;

  /// Stage 1: Detects coffee leaves in the original image and returns the list of detected leaves (with cropped image paths).
  Future<Either<Failure, List<LeafDetection>>> detectLeaves(
    String originalImagePath, {
    required bool isOffline,
  });

  /// Stage 2: Classifies the disease/pest for each cropped leaf in the list.
  Future<Either<Failure, List<LeafDetection>>> classifyPests(
    List<LeafDetection> detectedLeaves, {
    required bool isOffline,
  });

  /// Saves a complete diagnosis session to local database and/or backend queue.
  Future<Either<Failure, void>> saveDiagnosis(Diagnosis diagnosis);

  /// Retrieves the history of diagnoses.
  Future<Either<Failure, List<Diagnosis>>> getDiagnosisHistory();

  /// Syncs a single offline diagnosis to the backend server.
  /// Returns the synced diagnosis on success, null on failure.
  Future<Diagnosis?> syncDiagnosis(Diagnosis diagnosis);
}
