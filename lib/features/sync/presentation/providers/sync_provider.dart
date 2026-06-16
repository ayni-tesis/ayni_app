import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../diagnosis/domain/repositories/diagnosis_repository.dart';
import '../../../diagnosis/presentation/providers/diagnosis_provider.dart';
import '../../data/datasources/sync_local_datasource.dart';
import '../../data/repositories/sync_repository_impl.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../../diagnosis/domain/entities/diagnosis.dart';

// ─── DataSource & Repository ─────────────────────────────────────────────────

final syncLocalDataSourceProvider = Provider<SyncLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SyncLocalDataSourceImpl(sharedPreferences: prefs);
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepositoryImpl(
    diagnosisRepository: ref.watch(diagnosisRepositoryProvider),
    localDataSource: ref.watch(syncLocalDataSourceProvider),
  );
});

// ─── Sync State Notifier ──────────────────────────────────────────────────────

class SyncNotifier extends StateNotifier<SyncStatus> {
  final SyncRepository _syncRepo;
  final DiagnosisRepository _diagnosisRepo;
  final ConnectivityService _connectivity;

  SyncNotifier({
    required SyncRepository syncRepo,
    required DiagnosisRepository diagnosisRepo,
    required ConnectivityService connectivity,
  })  : _syncRepo = syncRepo,
        _diagnosisRepo = diagnosisRepo,
        _connectivity = connectivity,
        super(const SyncStatus()) {
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final pending = await _syncRepo.getPendingCount();
    final lastSync = await _syncRepo.getLastSyncTime();
    state = state.copyWith(
      pendingCount: pending,
      lastSyncAt: lastSync,
    );
  }

  Future<void> refresh() async {
    await _loadStatus();
  }

  /// Attempts to sync all pending diagnoses to the server.
  /// Returns the number of successfully synced items.
  Future<int> syncPending() async {
    if (state.isSyncing) return 0;

    final isOnline = await _connectivity.isConnected();
    if (!isOnline) {
      state = state.copyWith(
        state: SyncState.error,
        errorMessage: 'Sin conexión a internet',
      );
      return 0;
    }

    state = state.copyWith(state: SyncState.syncing, errorMessage: null);

    try {
      final pending = await _syncRepo.getPendingDiagnoses();
      if (pending.isEmpty) {
        state = state.copyWith(
          state: SyncState.success,
          pendingCount: 0,
          lastSyncAt: DateTime.now(),
        );
        return 0;
      }

      int synced = 0;
      final syncedIds = <String>[];

      for (final diagnosis in pending) {
        try {
          // Try to sync each diagnosis to the remote server
          final result = await _diagnosisRepo.syncDiagnosis(diagnosis);
          if (result != null) {
            syncedIds.add(diagnosis.id);
            synced++;
          }
        } catch (_) {
          // If sync fails for one, continue with others
        }
      }

      if (syncedIds.isNotEmpty) {
        await _syncRepo.markAllAsSynced(syncedIds);
        await _syncRepo.setLastSyncTime(DateTime.now());
      }

      final remaining = await _syncRepo.getPendingCount();
      state = state.copyWith(
        state: SyncState.success,
        pendingCount: remaining,
        lastSyncAt: DateTime.now(),
        syncedInSession: state.syncedInSession + synced,
      );

      return synced;
    } catch (e) {
      state = state.copyWith(
        state: SyncState.error,
        errorMessage: 'Error al sincronizar: ${e.toString()}',
      );
      return 0;
    }
  }

  void clearError() {
    state = state.copyWith(state: SyncState.idle, errorMessage: null);
  }
}

final syncNotifierProvider =
    StateNotifierProvider<SyncNotifier, SyncStatus>((ref) {
  return SyncNotifier(
    syncRepo: ref.watch(syncRepositoryProvider),
    diagnosisRepo: ref.watch(diagnosisRepositoryProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

// ─── Pending diagnoses list ────────────────────────────────────────────────────

final pendingDiagnosesProvider = FutureProvider<List<Diagnosis>>((ref) async {
  final syncRepo = ref.watch(syncRepositoryProvider);
  return syncRepo.getPendingDiagnoses();
});
