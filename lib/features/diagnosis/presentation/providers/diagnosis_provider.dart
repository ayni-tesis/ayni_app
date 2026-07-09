import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/utils/location_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/diagnosis_local_datasource.dart';
import '../../data/datasources/diagnosis_remote_datasource.dart';
import '../../data/datasources/history_remote_datasource.dart';
import '../../data/models/history_api_models.dart';
import '../../data/repositories/diagnosis_repository_impl.dart';
import '../../domain/entities/diagnosis.dart';
import '../../domain/entities/leaf_detection.dart';
import '../../domain/repositories/diagnosis_repository.dart';
import '../../domain/usecases/classify_pests_usecase.dart';
import '../../domain/usecases/detect_leaves_usecase.dart';
import '../../domain/usecases/get_diagnosis_history_usecase.dart';
import '../../domain/usecases/save_diagnosis_usecase.dart';
import '../../../sync/presentation/providers/sync_provider.dart';

// Data Sources Providers
final diagnosisLocalDataSourceProvider = Provider<DiagnosisLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DiagnosisLocalDataSourceImpl(sharedPreferences: prefs);
});

final diagnosisRemoteDataSourceProvider = Provider<DiagnosisRemoteDataSource>((ref) {
  return DiagnosisRemoteDataSourceImpl(
    api: ref.watch(apiClientProvider),
  );
});

// Repository Provider
final diagnosisRepositoryProvider = Provider<DiagnosisRepository>((ref) {
  final local = ref.watch(diagnosisLocalDataSourceProvider);
  final remote = ref.watch(diagnosisRemoteDataSourceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return DiagnosisRepositoryImpl(
    localDataSource: local,
    remoteDataSource: remote,
    connectivityService: connectivity,
  );
});

// Use Cases Providers
final detectLeavesUseCaseProvider = Provider<DetectLeavesUseCase>((ref) {
  final repo = ref.watch(diagnosisRepositoryProvider);
  return DetectLeavesUseCase(repo);
});

final classifyPestsUseCaseProvider = Provider<ClassifyPestsUseCase>((ref) {
  final repo = ref.watch(diagnosisRepositoryProvider);
  return ClassifyPestsUseCase(repo);
});

final saveDiagnosisUseCaseProvider = Provider<SaveDiagnosisUseCase>((ref) {
  final repo = ref.watch(diagnosisRepositoryProvider);
  return SaveDiagnosisUseCase(repo);
});

final getDiagnosisHistoryUseCaseProvider = Provider<GetDiagnosisHistoryUseCase>((ref) {
  final repo = ref.watch(diagnosisRepositoryProvider);
  return GetDiagnosisHistoryUseCase(repo);
});

// ─── History remote (server) ─────────────────────────────────────────────────

final historyRemoteDataSourceProvider = Provider<HistoryRemoteDataSource>((ref) {
  return HistoryRemoteDataSource(
    api: ref.watch(apiClientProvider),
  );
});

/// GET /history — historial paginado del servidor.
final serverHistoryProvider = FutureProvider.family<DiagnosisHistoryPage, int>((
  ref,
  page,
) async {
  final remote = ref.watch(historyRemoteDataSourceProvider);
  return remote.getHistory(page: page, size: 20);
});

/// GET /history/stats — estadísticas de plagas del servidor.
final serverHistoryStatsProvider = FutureProvider<HistoryStatsResponse>((ref) async {
  final remote = ref.watch(historyRemoteDataSourceProvider);
  return remote.getHistoryStats();
});

// Diagnosis Flow State definition
class DiagnosisState {
  final String? capturedImagePath;
  final bool isOffline;
  final bool isDetectingLeaves;
  final bool isClassifyingPests;
  final List<LeafDetection> detectedLeaves;
  final String? error;
  final Diagnosis? completedDiagnosis;
  final String? detectionImageUrl;
  final double? latitude;
  final double? longitude;

  const DiagnosisState({
    this.capturedImagePath,
    required this.isOffline,
    required this.isDetectingLeaves,
    required this.isClassifyingPests,
    required this.detectedLeaves,
    this.error,
    this.completedDiagnosis,
    this.detectionImageUrl,
    this.latitude,
    this.longitude,
  });

  factory DiagnosisState.initial({bool isOffline = false}) {
    return DiagnosisState(
      isOffline: isOffline,
      isDetectingLeaves: false,
      isClassifyingPests: false,
      detectedLeaves: [],
    );
  }

  DiagnosisState copyWith({
    String? capturedImagePath,
    bool? isOffline,
    bool? isDetectingLeaves,
    bool? isClassifyingPests,
    List<LeafDetection>? detectedLeaves,
    String? error,
    Diagnosis? completedDiagnosis,
    String? detectionImageUrl,
    double? latitude,
    double? longitude,
  }) {
    return DiagnosisState(
      capturedImagePath: capturedImagePath ?? this.capturedImagePath,
      isOffline: isOffline ?? this.isOffline,
      isDetectingLeaves: isDetectingLeaves ?? this.isDetectingLeaves,
      isClassifyingPests: isClassifyingPests ?? this.isClassifyingPests,
      detectedLeaves: detectedLeaves ?? this.detectedLeaves,
      error: error, // Clear error if not explicitly passed
      completedDiagnosis: completedDiagnosis ?? this.completedDiagnosis,
      detectionImageUrl: detectionImageUrl ?? this.detectionImageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

// State Notifier for Diagnosis Flow
class DiagnosisNotifier extends StateNotifier<DiagnosisState> {
  final DetectLeavesUseCase _detectLeavesUseCase;
  final ClassifyPestsUseCase _classifyPestsUseCase;
  final SaveDiagnosisUseCase _saveDiagnosisUseCase;
  final Ref _ref;

  DiagnosisNotifier({
    required this._detectLeavesUseCase,
    required this._classifyPestsUseCase,
    required this._saveDiagnosisUseCase,
    required this._ref,
  }) : super(DiagnosisState.initial());

  void setCapturedImage(String imagePath, bool isOffline) {
    state = DiagnosisState.initial(isOffline: isOffline).copyWith(
      capturedImagePath: imagePath,
    );
    // Se resuelve en paralelo a la detección/clasificación de plagas, sin
    // bloquear el flujo: si el usuario niega el permiso o el GPS está
    // apagado, el diagnóstico simplemente se guarda sin coordenadas.
    unawaited(_captureLocation(imagePath));
  }

  Future<void> _captureLocation(String forImagePath) async {
    final position = await LocationUtils.getCurrentLocation();
    if (position == null) return;
    // El usuario pudo reiniciar la captura mientras esperábamos el GPS.
    if (state.capturedImagePath != forImagePath) return;
    state = state.copyWith(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<bool> runLeafDetection() async {
    final imagePath = state.capturedImagePath;
    if (imagePath == null) return false;

    state = state.copyWith(isDetectingLeaves: true);

    final result = await _detectLeavesUseCase(imagePath, isOffline: state.isOffline);

    return result.fold(
      (failure) {
        state = state.copyWith(isDetectingLeaves: false, error: failure.message);
        return false;
      },
      (leaves) {
        final latestImageUrl = _ref.read(diagnosisRepositoryProvider).latestDetectionImageUrl;
        state = state.copyWith(
          isDetectingLeaves: false,
          detectedLeaves: leaves,
          detectionImageUrl: latestImageUrl,
        );
        return true;
      },
    );
  }

  Future<bool> runPestClassification() async {
    if (state.detectedLeaves.isEmpty) return false;

    state = state.copyWith(isClassifyingPests: true);

    final result = await _classifyPestsUseCase(state.detectedLeaves, isOffline: state.isOffline);

    return result.fold(
      (failure) {
        state = state.copyWith(isClassifyingPests: false, error: failure.message);
        return false;
      },
      (classifiedLeaves) {
        final diagnosis = Diagnosis(
          id: 'diag_${DateTime.now().microsecondsSinceEpoch}',
          dateTime: DateTime.now(),
          originalImagePath: state.capturedImagePath!,
          detectedLeaves: classifiedLeaves,
          isOffline: state.isOffline,
          isSynced: false,
          latitude: state.latitude,
          longitude: state.longitude,
        );

        state = state.copyWith(
          isClassifyingPests: false,
          detectedLeaves: classifiedLeaves,
          completedDiagnosis: diagnosis,
        );
        return true;
      },
    );
  }

  Future<bool> saveCompletedDiagnosis() async {
    final diagnosis = state.completedDiagnosis;
    if (diagnosis == null) return false;

    final result = await _saveDiagnosisUseCase(diagnosis);

    final saved = result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) => true,
    );
    if (!saved) return false;

    // Diagnóstico offline: encolarlo también en sync_queue (sqflite) para
    // que la pantalla de sincronización lo detecte como pendiente.
    // El historial local (SharedPreferences) y la cola de sync son
    // almacenes separados — guardar en uno no llena el otro.
    if (diagnosis.isOffline) {
      await _ref.read(syncRepositoryProvider).savePendingDiagnosis(diagnosis);
      await _ref.read(syncNotifierProvider.notifier).refresh();
    }

    // Refresh history list provider
    _ref.invalidate(diagnosisHistoryProvider);
    return true;
  }

  void reset() {
    state = DiagnosisState.initial();
  }
}

final diagnosisNotifierProvider =
    StateNotifierProvider<DiagnosisNotifier, DiagnosisState>((ref) {
  final detect = ref.watch(detectLeavesUseCaseProvider);
  final classify = ref.watch(classifyPestsUseCaseProvider);
  final save = ref.watch(saveDiagnosisUseCaseProvider);
  return DiagnosisNotifier(
    detectLeavesUseCase: detect,
    classifyPestsUseCase: classify,
    saveDiagnosisUseCase: save,
    ref: ref,
  );
});

// AsyncNotifier/FutureProvider for diagnosis history list
final diagnosisHistoryProvider = FutureProvider<List<Diagnosis>>((ref) async {
  final getHistory = ref.watch(getDiagnosisHistoryUseCaseProvider);
  final result = await getHistory();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (history) => history,
  );
});
