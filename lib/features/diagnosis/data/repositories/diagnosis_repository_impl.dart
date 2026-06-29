import 'dart:convert';
import 'dart:io';
import '../../../../core/utils/image_processing_utils.dart';
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

  String? _latestDetectionImageUrl;
  int? _imageWidth;
  int? _imageHeight;

  DiagnosisRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.connectivityService,
  });

  @override
  String? get latestDetectionImageUrl => _latestDetectionImageUrl;

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
        final onlineResult = await remoteDataSource.detectLeavesOnline(
          imagePath: originalImagePath,
        );
        _latestDetectionImageUrl = onlineResult.imageUrl;
        _imageWidth = onlineResult.imageWidth;
        _imageHeight = onlineResult.imageHeight;

        // Recortamos las hojas en local para visualización y/o clasificación Base64
        final rects = onlineResult.leaves.map((box) => CropRect(
          x: box.boxX,
          y: box.boxY,
          width: box.boxWidth,
          height: box.boxHeight,
        )).toList();
        
        final croppedPaths = await ImageProcessingUtils.cropLeaves(originalImagePath, rects);

        final leaves = <LeafDetectionModel>[];
        for (int i = 0; i < onlineResult.leaves.length; i++) {
          final box = onlineResult.leaves[i];
          final croppedPath = i < croppedPaths.length ? croppedPaths[i] : '';
          leaves.add(LeafDetectionModel(
            id: box.id,
            boxX: box.boxX,
            boxY: box.boxY,
            boxWidth: box.boxWidth,
            boxHeight: box.boxHeight,
            croppedImagePath: croppedPath,
            diagnosedPest: null,
            confidence: box.detectionConfidence,
            severity: null,
          ));
        }

        return Right(leaves);
      }
      // Offline o fallback: YOLO TFLite local
      final localResult = await localDataSource.detectLeaves(originalImagePath);
      return Right(localResult);
    } catch (e) {
      // Fallback: si el API falla, intentar TFLite local
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
        LeavesClassifyResponse classifyResponse;
        if (_latestDetectionImageUrl != null && _imageWidth != null && _imageHeight != null) {
          // Forma A: URL + bboxes
          final apiLeaves = detectedLeaves.map((l) => LeafBoxModel(
            id: l.id,
            boxX: l.boxX,
            boxY: l.boxY,
            boxWidth: l.boxWidth,
            boxHeight: l.boxHeight,
          )).toList();

          classifyResponse = await remoteDataSource.classifyPestsOnline(
            imageUrl: _latestDetectionImageUrl!,
            leaves: apiLeaves,
            imageWidth: _imageWidth!,
            imageHeight: _imageHeight!,
          );
        } else {
          // Forma B: base64 crops
          final crops = <Map<String, String>>[];
          for (final leaf in detectedLeaves) {
            final file = File(leaf.croppedImagePath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              final base64Image = base64Encode(bytes);
              crops.add({
                'id': leaf.id,
                'imageBase64': base64Image,
              });
            }
          }
          if (crops.isEmpty) {
            return const Left(ProcessingFailure('No hay imágenes recortadas disponibles localmente para clasificar en el servidor.'));
          }
          classifyResponse = await remoteDataSource.classifyPestsByCropsOnline(crops: crops);
        }

        final classifiedLeaves = detectedLeaves.map((leaf) {
          final match = classifyResponse.leaves.firstWhere(
            (c) => c.id == leaf.id,
            orElse: () => const LeafClassificationModel(
              id: '',
              diagnosedPest: 'HEALTHY',
              confidence: 0.0,
            ),
          );
          return leaf.copyWith(
            diagnosedPest: _apiStringToPestType(match.diagnosedPest),
            confidence: match.confidence,
            severity: match.severity,
          );
        }).toList();

        return Right(classifiedLeaves);
      }

      // Offline: EfficientNet TFLite local
      final localResult = await localDataSource.classifyPests(leafModels);
      return Right(localResult);
    } catch (e) {
      // Fallback a clasificación local si falla el online
      try {
        final localResult = await localDataSource.classifyPests(
          detectedLeaves.map((e) => LeafDetectionModel.fromEntity(e)).toList()
        );
        return Right(localResult);
      } catch (localError) {
        return Left(ProcessingFailure(
            'Error al clasificar plagas en el servidor y el clasificador local también falló: ${e.toString()}'));
      }
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
