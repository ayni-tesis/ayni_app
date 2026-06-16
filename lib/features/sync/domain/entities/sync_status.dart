import 'package:flutter/foundation.dart';

enum SyncState { idle, syncing, success, error }

@immutable
class SyncStatus {
  final int pendingCount;
  final DateTime? lastSyncAt;
  final SyncState state;
  final String? errorMessage;
  final int syncedInSession;

  const SyncStatus({
    this.pendingCount = 0,
    this.lastSyncAt,
    this.state = SyncState.idle,
    this.errorMessage,
    this.syncedInSession = 0,
  });

  SyncStatus copyWith({
    int? pendingCount,
    DateTime? lastSyncAt,
    SyncState? state,
    String? errorMessage,
    int? syncedInSession,
  }) {
    return SyncStatus(
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      state: state ?? this.state,
      errorMessage: errorMessage,
      syncedInSession: syncedInSession ?? this.syncedInSession,
    );
  }

  bool get hasPending => pendingCount > 0;
  bool get isSyncing => state == SyncState.syncing;
}
