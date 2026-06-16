import '../../../../core/errors/failures.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../domain/entities/diagnosis.dart';
import '../../domain/entities/leaf_detection.dart';
import '../../domain/repositories/diagnosis_repository.dart';
import '../datasources/diagnosis_local_datasource.dart';
import '../datasources/diagnosis_remote_datasource.dart';
import '../models/diagnosis_model.dart';
import '../models/leaf_detection_model.dart';

class DiagnosisRepositoryImpl implements DiagnosisRepository {
  final DiagnosisLocalDataSource localDataSource;
  final DiagnosisRemoteDataSource remoteDataSource;
  final ConnectivityService connectivityService;

  const DiagnosisRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivityService,
  });

  @override
  Future<Either<Failure, List<LeafDetection>>> detectLeaves(
    String originalImagePath, {
    required bool isOffline,
  }) async {
    try {
      final isOnline = await connectivityService.isConnected();
      if (!isOffline && isOnline) {
        try {
          final remoteResult = await remoteDataSource.detectLeavesOnline(originalImagePath);
          return Right(remoteResult);
        } catch (_) {
          // If remote fails, fallback to local (offline-first design)
        }
      }

      // Local YOLO leaf detection and physical cropping
      final localResult = await localDataSource.detectLeaves(originalImagePath);
      return Right(localResult);
    } catch (e) {
      return Left(ProcessingFailure('Error al detectar hojas: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<LeafDetection>>> classifyPests(
    List<LeafDetection> detectedLeaves, {
    required bool isOffline,
  }) async {
    try {
      final isOnline = await connectivityService.isConnected();
      final leavesModels = detectedLeaves
          .map((e) => LeafDetectionModel.fromEntity(e))
          .toList();

      if (!isOffline && isOnline) {
        try {
          final remoteResult = await remoteDataSource.classifyPestsOnline(leavesModels);
          return Right(remoteResult);
        } catch (_) {
          // If remote fails, fallback to local (offline-first design)
        }
      }

      // Local TFLite classification
      final localResult = await localDataSource.classifyPests(leavesModels);
      return Right(localResult);
    } catch (e) {
      return Left(ProcessingFailure('Error al clasificar plagas: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveDiagnosis(Diagnosis diagnosis) async {
    try {
      final model = DiagnosisModel.fromEntity(diagnosis);
      await localDataSource.saveDiagnosis(model);

      // Attempt to sync online if connected and not offline mode
      final isOnline = await connectivityService.isConnected();
      if (!diagnosis.isOffline && isOnline) {
        try {
          await remoteDataSource.uploadDiagnosis(model);
        } catch (_) {
          // Fail silently on upload, keep it saved locally to sync later
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('No se pudo guardar el diagnóstico: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Diagnosis>>> getDiagnosisHistory() async {
    try {
      final localHistory = await localDataSource.getDiagnosisHistory();
      return Right(localHistory);
    } catch (e) {
      return Left(CacheFailure('No se pudo recuperar el historial: ${e.toString()}'));
    }
  }

  @override
  Future<Diagnosis?> syncDiagnosis(Diagnosis diagnosis) async {
    try {
      final isOnline = await connectivityService.isConnected();
      if (!isOnline) return null;

      final model = DiagnosisModel.fromEntity(diagnosis);
      await remoteDataSource.uploadDiagnosis(model);

      // Mark as synced locally
      final synced = diagnosis.copyWith(isSynced: true);
      await localDataSource.saveDiagnosis(DiagnosisModel.fromEntity(synced));
      return synced;
    } catch (_) {
      return null;
    }
  }
}
