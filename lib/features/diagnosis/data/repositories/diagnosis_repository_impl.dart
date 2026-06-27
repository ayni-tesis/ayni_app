import '../../../../core/errors/failures.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../domain/entities/diagnosis.dart';
import '../../domain/entities/leaf_detection.dart';
import '../../domain/entities/pest_type.dart';
import '../../domain/repositories/diagnosis_repository.dart';
import '../datasources/diagnosis_local_datasource.dart';
import '../datasources/diagnosis_remote_datasource.dart';
import '../models/diagnosis_api_models.dart';
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

  // ─── Online diagnosis path ───────────────────────────────────────────────

  /// Diagnóstico online: sube imagen al API Gateway y recibe resultado completo.
  /// Solo se ejecuta cuando hay conexión.
  Future<Either<Failure, DiagnosisAnalyzeResponse>> analyzeOnline({
    required String imagePath,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final isOnline = await connectivityService.isConnected();
      if (!isOnline) {
        return const Left(ConnectionFailure(
            'Sin conexión. El diagnóstico online no está disponible.'));
      }
      final result = await remoteDataSource.analyzeImageOnline(
        imagePath: imagePath,
        latitude: latitude,
        longitude: longitude,
      );
      return Right(result);
    } catch (e) {
      return Left(ProcessingFailure(
          'Error en el diagnóstico online: ${e.toString()}'));
    }
  }

  // ─── Offline diagnosis path (TFLite local) ───────────────────────────────

  @override
  Future<Either<Failure, List<LeafDetection>>> detectLeaves(
    String originalImagePath, {
    required bool isOffline,
  }) async {
    try {
      final isOnline = await connectivityService.isConnected();
      if (!isOffline && isOnline) {
        // Paso 1: intentar API Gateway — detección + clasificación completa en un paso
        final onlineResult = await remoteDataSource.analyzeImageOnline(
          imagePath: originalImagePath,
        );
        // El API devuelve un resultado agregado (una plaga por imagen completa).
        // Creamos un LeafDetection que cubre la imagen entera para mantener
        // compatibilidad con el resto del flujo (mostrar bounding box en pantalla).
        final pest = _apiStringToPestType(onlineResult.detectedPest);
        final leaf = LeafDetection(
          id: 'api_leaf_${DateTime.now().microsecondsSinceEpoch}',
          boxX: 0.0,
          boxY: 0.0,
          boxWidth: 1.0,
          boxHeight: 1.0,
          croppedImagePath: originalImagePath, // imagen original completa
          diagnosedPest: pest,
          confidence: onlineResult.confidenceScore,
          severity: onlineResult.severityLevel,
        );
        return Right([leaf]);
      }
      // Offline o fallback: YOLO TFLite local
      final localResult = await localDataSource.detectLeaves(originalImagePath);
      return Right(localResult);
    } catch (e) {
      //Fallback: si el API falla (no disponible, timeout, etc.), intentar TFLite local
      try {
        final localResult = await localDataSource.detectLeaves(originalImagePath);
        return Right(localResult);
      } catch (localError) {
        return Left(ProcessingFailure(
            'Error al detectar hojas. API no disponible y TFLite local también falló: ${localError.toString()}'));
      }
    }
  }

  @override
  Future<Either<Failure, List<LeafDetection>>> classifyPests(
    List<LeafDetection> detectedLeaves, {
    required bool isOffline,
  }) async {
    try {
      final isOnline = await connectivityService.isConnected();
      final leafModels = detectedLeaves
          .map((e) => LeafDetectionModel.fromEntity(e))
          .toList();

      if (!isOffline && isOnline) {
        // Online: la clasificación la hizo el servidor en analyzeOnline().
        // detectedLeaves ya viene con diagnosedPest, confidence y severity
        // asignados desde el resultado del API en detectLeaves().
        // No volver a clasificar — solo verificar que todos los leaves tengan plaga asignada.
        final unclassified = detectedLeaves.where((l) => l.diagnosedPest == null).toList();
        if (unclassified.isNotEmpty) {
          return Left(ProcessingFailure(
              'Algunas hojas no pudieron ser clasificadas por el servidor.'));
        }
        return Right(detectedLeaves);
      }

      // Offline: EfficientNet TFLite local
      final localResult = await localDataSource.classifyPests(leafModels);
      return Right(localResult);
    } catch (e) {
      return Left(ProcessingFailure(
          'Error al clasificar plagas: ${e.toString()}'));
    }
  }

  // ─── Persist diagnosis ───────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> saveDiagnosis(Diagnosis diagnosis) async {
    try {
      final model = DiagnosisModel.fromEntity(diagnosis);
      await localDataSource.saveDiagnosis(model);

      // Si el diagnóstico fue hecho online (API Gateway), marcar como synced.
      // El remote ya lo subió; no necesitamos sync posterior.
      if (!diagnosis.isOffline) {
        final synced = diagnosis.copyWith(isSynced: true);
        await localDataSource
            .saveDiagnosis(DiagnosisModel.fromEntity(synced));
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(
          'No se pudo guardar el diagnóstico: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Diagnosis>>> getDiagnosisHistory() async {
    try {
      final localHistory = await localDataSource.getDiagnosisHistory();
      return Right(localHistory);
    } catch (e) {
      return Left(CacheFailure(
          'No se pudo recuperar el historial: ${e.toString()}'));
    }
  }

  // ─── Sync offline → online ───────────────────────────────────────────────

  @override
  Future<Diagnosis?> syncDiagnosis(Diagnosis diagnosis) async {
    try {
      final isOnline = await connectivityService.isConnected();
      if (!isOnline) return null;

      // Construir el request de sync con los leaves del diagnóstico
      final leaves = diagnosis.detectedLeaves.map((leaf) {
        return LeafSyncItem(
          localId: leaf.id,
          boxX: leaf.boxX,
          boxY: leaf.boxY,
          boxWidth: leaf.boxWidth,
          boxHeight: leaf.boxHeight,
          croppedImageBase64: null, // la imagen original se sube por otro medio
          diagnosedPest: _pestTypeToApiString(leaf.diagnosedPest),
          confidence: leaf.confidence ?? 0.0,
          severity: leaf.severity,
        );
      }).toList();

      final request = DiagnosisSyncRequest(
        userId: diagnosis.id, // el userId real se toma del token JWT en el API
        capturedAt: diagnosis.dateTime,
        latitude: diagnosis.latitude,
        longitude: diagnosis.longitude,
        leaves: leaves,
      );

      await remoteDataSource.syncDiagnosis(request);

      // Marcar como sincronizado localmente
      final synced = diagnosis.copyWith(isSynced: true);
      await localDataSource
          .saveDiagnosis(DiagnosisModel.fromEntity(synced));
      return synced;
    } catch (_) {
      return null;
    }
  }

  /// Convierte el string del API a PestType local.
  /// API:   RUST, MINER, PHOMA, HEALTHY, RED_SPIDER
  /// Local: roya, minador, phoma, healthy, redspider
  PestType _apiStringToPestType(String apiString) {
    switch (apiString.toUpperCase()) {
      case 'RUST':
        return PestType.roya;
      case 'MINER':
        return PestType.minador;
      case 'PHOMA':
        return PestType.phoma;
      case 'HEALTHY':
        return PestType.healthy;
      case 'RED_SPIDER':
      case 'REDSPIDER':
        return PestType.redspider;
      default:
        return PestType.healthy;
    }
  }

  /// Convierte el PestType del dominio local a string del API.
  String _pestTypeToApiString(dynamic pestType) {
    if (pestType == null) return 'HEALTHY';
    final name = pestType.toString().split('.').last.toUpperCase();
    switch (name) {
      case 'ROYA':
        return 'RUST';
      case 'MINADOR':
        return 'MINER';
      case 'PHOMA':
        return 'PHOMA';
      case 'HEALTHY':
        return 'HEALTHY';
      case 'REDSPIDER':
        return 'RED_SPIDER';
      default:
        return name;
    }
  }
}
