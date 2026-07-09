import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/sync_database.dart';
import '../../data/datasources/sync_local_datasource.dart';
import '../../data/datasources/sync_remote_datasource.dart';
import '../../data/repositories/sync_repository_impl.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../../diagnosis/domain/entities/diagnosis.dart';

// ─── DataSource & Repository ─────────────────────────────────────────────────

/// Singleton de la base de datos sqflite de sincronización.
final syncDatabaseProvider = Provider<SyncDatabase>((ref) {
  return SyncDatabase();
});

final syncLocalDataSourceProvider = Provider<SyncLocalDataSource>((ref) {
  final db = ref.watch(syncDatabaseProvider);
  return SyncLocalDataSourceImpl(db: db);
});

final syncRemoteDataSourceProvider = Provider<SyncRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SyncRemoteDataSourceImpl(api: apiClient);
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepositoryImpl(
    localDataSource: ref.watch(syncLocalDataSourceProvider),
    remoteDataSource: ref.watch(syncRemoteDataSourceProvider),
  );
});

// ─── Sync State Notifier ──────────────────────────────────────────────────────

/// Notifier que gestiona el estado de sincronización y escucha cambios de conectividad
/// para disparar sync automático cuando el dispositivo recupera conexión.
class SyncNotifier extends StateNotifier<SyncStatus> {
  final SyncRepository _syncRepo;
  final ConnectivityService _connectivity;
  StreamSubscription<bool>? _connectivitySubscription;

  SyncNotifier({
    required this._syncRepo,
    required this._connectivity,
  }) : super(const SyncStatus()) {
    _loadStatus();
    _listenConnectivity();
  }

  /// Suscribe a cambios de conectividad y dispara sync automático al recuperar conexión.
  void _listenConnectivity() {
    _connectivitySubscription = _connectivity.connectivityStream.listen((isOnline) async {
      if (!isOnline) return;
      // Dispositivo acaba de recuperar conexión — syncar pending automáticamente.
      // Solo si no está syncing ya y hay diagnósticos pendientes.
      if (state.isSyncing) return;
      final pending = await _syncRepo.getPendingCount();
      if (pending > 0) {
        await syncPending();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
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

  /// Envía todos los diagnósticos pendientes en un solo lote a diagnosis-service
  /// (POST /diagnoses/sync/batch): sube la imagen original a Azure Blob y publica
  /// diagnosis.created para el dashboard. Marca como sincronizados solo si el
  /// servidor confirma el lote (queued > 0).
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

      // Enviar lote completo de una vez a diagnosis-service
      final batchResponse = await _syncRepo.syncBatch(pending);
      final queued = batchResponse.queued;

      // "duplicates" son ítems que el servidor ya había recibido en un
      // intento anterior (idempotencia por localDiagnosisId, ver
      // SyncRemoteDataSource.syncBatch) — ya están sincronizados del lado
      // del servidor aunque esta respuesta no los cuente como "queued".
      // Si solo se chequea queued > 0, un reintento tras una respuesta
      // perdida deja esos diagnósticos marcados como pendientes para siempre.
      if (queued > 0 || batchResponse.duplicates > 0) {
        // Marcar todos los diagnósticos del lote como sincronizados.
        // diagnosis-service publica diagnosis.created de forma asíncrona por Kafka.
        final syncedIds = pending.map((d) => d.id).toList();
        await _syncRepo.markAllAsSynced(syncedIds);
        await _syncRepo.setLastSyncTime(DateTime.now());
      }

      final remaining = await _syncRepo.getPendingCount();
      state = state.copyWith(
        state: SyncState.success,
        pendingCount: remaining,
        lastSyncAt: DateTime.now(),
        syncedInSession: state.syncedInSession + queued,
      );

      return queued;
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
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

// ─── Pending diagnoses list ────────────────────────────────────────────────────

final pendingDiagnosesProvider = FutureProvider<List<Diagnosis>>((ref) async {
  final syncRepo = ref.watch(syncRepositoryProvider);
  return syncRepo.getPendingDiagnoses();
});
