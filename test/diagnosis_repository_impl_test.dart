import 'package:flutter_test/flutter_test.dart';
import 'package:ayni_app/features/diagnosis/data/repositories/diagnosis_repository_impl.dart';
import 'package:ayni_app/features/diagnosis/data/datasources/diagnosis_remote_datasource.dart';
import 'package:ayni_app/features/diagnosis/data/datasources/diagnosis_local_datasource.dart';
import 'package:ayni_app/features/diagnosis/data/models/diagnosis_api_models.dart';
import 'package:ayni_app/features/diagnosis/data/models/leaf_detection_model.dart';
import 'package:ayni_app/features/diagnosis/domain/entities/leaf_detection.dart';
import 'package:ayni_app/features/diagnosis/domain/entities/pest_type.dart';
import 'package:ayni_app/core/network/connectivity_service.dart';
import 'package:ayni_app/core/errors/failures.dart';
import 'package:ayni_app/features/diagnosis/data/models/diagnosis_model.dart';

// ─── Mocks Manuales (Stubs) ──────────────────────────────────────────────────

class MockDiagnosisRemoteDataSource implements DiagnosisRemoteDataSource {
  LeavesDetectionResponse? detectResponse;
  LeavesClassifyResponse? classifyResponse;
  
  bool detectLeavesCalled = false;
  bool classifyPestsCalled = false;
  bool classifyPestsByCropsCalled = false;

  @override
  Future<LeavesDetectionResponse> detectLeavesOnline({
    required String imagePath,
    double? latitude,
    double? longitude,
  }) async {
    detectLeavesCalled = true;
    if (detectResponse != null) return detectResponse!;
    throw Exception('Error detect online');
  }

  @override
  Future<LeavesClassifyResponse> classifyPestsOnline({
    required String imageUrl,
    required List<LeafBoxModel> leaves,
    required int imageWidth,
    required int imageHeight,
  }) async {
    classifyPestsCalled = true;
    if (classifyResponse != null) return classifyResponse!;
    throw Exception('Error classify online');
  }

  @override
  Future<LeavesClassifyResponse> classifyPestsByCropsOnline({
    required List<Map<String, String>> crops,
  }) async {
    classifyPestsByCropsCalled = true;
    if (classifyResponse != null) return classifyResponse!;
    throw Exception('Error classify crops online');
  }

  @override
  Future<DiagnosisAnalyzeResponse> analyzeImageOnline({
    required String imagePath,
    double? latitude,
    double? longitude,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> syncDiagnosis(DiagnosisSyncRequest request) async {}

  @override
  Future<DiagnosisAnalyzeResponse> getDiagnosisById(String id) async {
    throw UnimplementedError();
  }
}

class MockDiagnosisLocalDataSource implements DiagnosisLocalDataSource {
  List<LeafDetectionModel> detectResult = [];
  List<LeafDetectionModel> classifyResult = [];
  bool detectCalled = false;
  bool classifyCalled = false;

  @override
  Future<List<LeafDetectionModel>> detectLeaves(String imagePath) async {
    detectCalled = true;
    return detectResult;
  }

  @override
  Future<List<LeafDetectionModel>> classifyPests(List<LeafDetectionModel> leaves) async {
    classifyCalled = true;
    return classifyResult;
  }

  @override
  Future<void> saveDiagnosis(dynamic diagnosis) async {}

  @override
  Future<List<DiagnosisModel>> getDiagnosisHistory() async => [];

  @override
  Future<void> clearHistory() async {}

  @override
  Future<void> closeInterpreters() async {}
}

class MockConnectivityService implements ConnectivityService {
  bool isConnectedValue = true;

  @override
  Future<bool> isConnected() async => isConnectedValue;

  @override
  Stream<bool> get connectivityStream => Stream.value(isConnectedValue);
}

// ─── Main Tests ─────────────────────────────────────────────────────────────

void main() {
  late DiagnosisRepositoryImpl repository;
  late MockDiagnosisRemoteDataSource mockRemote;
  late MockDiagnosisLocalDataSource mockLocal;
  late MockConnectivityService mockConnectivity;

  setUp(() {
    mockRemote = MockDiagnosisRemoteDataSource();
    mockLocal = MockDiagnosisLocalDataSource();
    mockConnectivity = MockConnectivityService();
    repository = DiagnosisRepositoryImpl(
      localDataSource: mockLocal,
      remoteDataSource: mockRemote,
      connectivityService: mockConnectivity,
    );
  });

  group('detectLeaves Online', () {
    test('debe llamar a detectLeavesOnline y mapear cajas sin crear bbox falso (0,0,1,1)', () async {
      // Arrange
      mockRemote.detectResponse = const LeavesDetectionResponse(
        leaves: [
          LeafBoxModel(id: 'leaf_0', boxX: 0.1, boxY: 0.2, boxWidth: 0.3, boxHeight: 0.4, detectionConfidence: 0.9)
        ],
        imageUrl: 'http://blob/image.jpg',
        imageWidth: 1000,
        imageHeight: 800,
        processingMs: 100,
      );

      // Act
      final result = await repository.detectLeaves('original.jpg', isOffline: false);

      // Assert
      expect(result.isRight(), isTrue);
      final leaves = result.getOrElse(() => []);
      expect(leaves.length, 1);
      expect(leaves.first.id, 'leaf_0');
      // No debe ser el bbox falso (0,0,1,1)
      expect(leaves.first.boxX, 0.1);
      expect(leaves.first.boxY, 0.2);
      expect(leaves.first.boxWidth, 0.3);
      expect(leaves.first.boxHeight, 0.4);
      expect(repository.latestDetectionImageUrl, 'http://blob/image.jpg');
      expect(mockRemote.detectLeavesCalled, isTrue);
    });

    test('debe hacer fallback local a TFLite si la llamada al servidor falla', () async {
      // Arrange
      mockLocal.detectResult = [
        const LeafDetectionModel(id: 'local_0', boxX: 0.0, boxY: 0.0, boxWidth: 0.5, boxHeight: 0.5, croppedImagePath: 'crop.jpg')
      ];

      // Act
      final result = await repository.detectLeaves('original.jpg', isOffline: false);

      // Assert
      expect(result.isRight(), isTrue);
      final leaves = result.getOrElse(() => []);
      expect(leaves.length, 1);
      expect(leaves.first.id, 'local_0');
      expect(mockLocal.detectCalled, isTrue);
    });
  });

  group('classifyPests Online', () {
    test('debe llamar a classifyPestsOnline con la imageUrl y dimensiones persistidas', () async {
      // Arrange
      // 1. Simulamos el detect previo para persistir imageUrl y dimensiones
      mockRemote.detectResponse = const LeavesDetectionResponse(
        leaves: [
          LeafBoxModel(id: 'leaf_0', boxX: 0.1, boxY: 0.2, boxWidth: 0.3, boxHeight: 0.4)
        ],
        imageUrl: 'http://blob/image.jpg',
        imageWidth: 1000,
        imageHeight: 800,
        processingMs: 100,
      );
      await repository.detectLeaves('original.jpg', isOffline: false);

      mockRemote.classifyResponse = const LeavesClassifyResponse(
        leaves: [
          LeafClassificationModel(id: 'leaf_0', diagnosedPest: 'RUST', confidence: 0.85)
        ],
        aggregate: AggregateModel(detectedPest: 'RUST', confidence: 0.85, healthy: false),
        processingMs: 150,
      );

      final detectedLeaves = [
        const LeafDetection(id: 'leaf_0', boxX: 0.1, boxY: 0.2, boxWidth: 0.3, boxHeight: 0.4, croppedImagePath: '')
      ];

      // Act
      final result = await repository.classifyPests(detectedLeaves, isOffline: false);

      // Assert
      expect(result.isRight(), isTrue);
      final classified = result.getOrElse(() => []);
      expect(classified.first.diagnosedPest, PestType.roya);
      expect(classified.first.confidence, 0.85);
      expect(mockRemote.classifyPestsCalled, isTrue);
    });
  });
}

// Extensión básica para desempaquetar Either en tests
extension EitherTestExt<L, R> on dynamic {
  bool isRight() => this.runtimeType.toString().startsWith('Right');
  R getOrElse(R Function() fallback) {
    try {
      return this.value;
    } catch (_) {
      return fallback();
    }
  }
}
