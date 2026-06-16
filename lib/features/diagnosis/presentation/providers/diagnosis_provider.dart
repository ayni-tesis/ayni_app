import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../data/datasources/diagnosis_local_datasource.dart';
import '../../data/datasources/diagnosis_remote_datasource.dart';
import '../../data/repositories/diagnosis_repository_impl.dart';
import '../../domain/entities/diagnosis.dart';
import '../../domain/entities/leaf_detection.dart';
import '../../domain/repositories/diagnosis_repository.dart';
import '../../domain/usecases/classify_pests_usecase.dart';
import '../../domain/usecases/detect_leaves_usecase.dart';
import '../../domain/usecases/get_diagnosis_history_usecase.dart';
import '../../domain/usecases/save_diagnosis_usecase.dart';

// SharedPreferences Provider - will be overridden in main.dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Debe sobrescribir sharedPreferencesProvider en main.dart');
});

// Data Sources Providers
final diagnosisLocalDataSourceProvider = Provider<DiagnosisLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DiagnosisLocalDataSourceImpl(sharedPreferences: prefs);
});

final diagnosisRemoteDataSourceProvider = Provider<DiagnosisRemoteDataSource>((ref) {
  return const DiagnosisRemoteDataSourceImpl();
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

// Diagnosis Flow State definition
class DiagnosisState {
  final String? capturedImagePath;
  final bool isOffline;
  final bool isDetectingLeaves;
  final bool isClassifyingPests;
  final List<LeafDetection> detectedLeaves;
  final String? error;
  final Diagnosis? completedDiagnosis;

  const DiagnosisState({
    this.capturedImagePath,
    required this.isOffline,
    required this.isDetectingLeaves,
    required this.isClassifyingPests,
    required this.detectedLeaves,
    this.error,
    this.completedDiagnosis,
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
  }) {
    return DiagnosisState(
      capturedImagePath: capturedImagePath ?? this.capturedImagePath,
      isOffline: isOffline ?? this.isOffline,
      isDetectingLeaves: isDetectingLeaves ?? this.isDetectingLeaves,
      isClassifyingPests: isClassifyingPests ?? this.isClassifyingPests,
      detectedLeaves: detectedLeaves ?? this.detectedLeaves,
      error: error, // Clear error if not explicitly passed
      completedDiagnosis: completedDiagnosis ?? this.completedDiagnosis,
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
        state = state.copyWith(
          isDetectingLeaves: false,
          detectedLeaves: leaves,
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

    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (_) {
        // Refresh history list provider
        _ref.invalidate(diagnosisHistoryProvider);
        return true;
      },
    );
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
