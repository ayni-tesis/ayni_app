import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayni_app/features/diagnosis/presentation/screens/leaf_selection_screen.dart';
import 'package:ayni_app/features/diagnosis/presentation/providers/diagnosis_provider.dart';
import 'package:ayni_app/features/diagnosis/domain/entities/leaf_detection.dart';
import 'package:ayni_app/features/diagnosis/domain/entities/diagnosis.dart';
import 'package:ayni_app/features/diagnosis/domain/repositories/diagnosis_repository.dart';
import 'package:ayni_app/features/diagnosis/domain/usecases/detect_leaves_usecase.dart';
import 'package:ayni_app/features/diagnosis/domain/usecases/classify_pests_usecase.dart';
import 'package:ayni_app/features/diagnosis/domain/usecases/save_diagnosis_usecase.dart';
import 'package:ayni_app/core/errors/failures.dart';

// ─── Fakes para inicializar el super constructor del notifier ─────────────────

class MockDiagnosisRepository implements DiagnosisRepository {
  @override
  String? get latestDetectionImageUrl => null;
  @override
  Future<Either<Failure, List<LeafDetection>>> detectLeaves(String path, {required bool isOffline}) async => const Right([]);
  @override
  Future<Either<Failure, List<LeafDetection>>> classifyPests(List<LeafDetection> leaves, {required bool isOffline}) async => const Right([]);
  @override
  Future<Either<Failure, void>> saveDiagnosis(Diagnosis diagnosis) async => const Right(null);
  @override
  Future<Either<Failure, List<Diagnosis>>> getDiagnosisHistory() async => const Right([]);
  @override
  Future<Diagnosis?> syncDiagnosis(Diagnosis diagnosis) async => null;
}

class _FakeDetect extends DetectLeavesUseCase {
  _FakeDetect() : super(MockDiagnosisRepository());
  @override
  Future<Either<Failure, List<LeafDetection>>> call(String path, {required bool isOffline}) async {
    return const Right([]);
  }
}

class _FakeClassify extends ClassifyPestsUseCase {
  _FakeClassify() : super(MockDiagnosisRepository());
  @override
  Future<Either<Failure, List<LeafDetection>>> call(List<LeafDetection> leaves, {required bool isOffline}) async {
    return const Right([]);
  }
}

class _FakeSave extends SaveDiagnosisUseCase {
  _FakeSave() : super(MockDiagnosisRepository());
  @override
  Future<Either<Failure, void>> call(Diagnosis diagnosis) async {
    return const Right(null);
  }
}

class _FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ─── Mock del Notifier ────────────────────────────────────────────────────────

class MockDiagnosisNotifier extends DiagnosisNotifier {
  bool runPestClassificationCalled = false;

  MockDiagnosisNotifier(DiagnosisState state)
      : super(
          detectLeavesUseCase: _FakeDetect(),
          classifyPestsUseCase: _FakeClassify(),
          saveDiagnosisUseCase: _FakeSave(),
          ref: _FakeRef(),
        ) {
    this.state = state;
  }

  @override
  Future<bool> runPestClassification() async {
    runPestClassificationCalled = true;
    return true;
  }
}

void main() {
  late File tempFile;
  late MockDiagnosisNotifier mockNotifier;

  setUpAll(() {
    // Escribimos una imagen dummy de 1x1 png en el sistema temporal
    final tempDir = Directory.systemTemp.createTempSync();
    tempFile = File('${tempDir.path}/test_image.jpg');
    final bytes = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');
    tempFile.writeAsBytesSync(bytes);
  });

  setUp(() {
    final state = DiagnosisState(
      capturedImagePath: tempFile.path,
      isOffline: false,
      isDetectingLeaves: false,
      isClassifyingPests: false,
      detectedLeaves: const [
        LeafDetection(id: 'leaf_1', boxX: 0.1, boxY: 0.1, boxWidth: 0.2, boxHeight: 0.2, croppedImagePath: ''),
        LeafDetection(id: 'leaf_2', boxX: 0.4, boxY: 0.4, boxWidth: 0.2, boxHeight: 0.2, croppedImagePath: ''),
        LeafDetection(id: 'leaf_3', boxX: 0.7, boxY: 0.7, boxWidth: 0.2, boxHeight: 0.2, croppedImagePath: ''),
      ],
    );
    mockNotifier = MockDiagnosisNotifier(state);
  });

  testWidgets('LeafSelectionScreen renderiza las hojas detectadas y permite diagnosticar', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diagnosisNotifierProvider.overrideWith((ref) => mockNotifier),
        ],
        child: const MaterialApp(
          home: LeafSelectionScreen(isOfflineMode: false),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verificar el título en el AppBar
    expect(find.text('Detección de Hojas'), findsOneWidget);

    // 2. Verificar que el texto de indicación está presente
    expect(find.text('Hojas detectadas (3)'), findsOneWidget);

    // 3. Verificar que el botón "Iniciar Diagnóstico de Plagas" está visible
    final diagnoseButton = find.text('Iniciar Diagnóstico de Plagas');
    expect(diagnoseButton, findsOneWidget);

    // 4. Hacer tap en el botón de diagnóstico y validar que llama al método de clasificación
    await tester.tap(diagnoseButton);
    await tester.pump();

    expect(mockNotifier.runPestClassificationCalled, isTrue);
  });
}
