import 'dart:async';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_fcm_datasource.dart';
import '../datasources/notifications_local_datasource.dart';

/// Composition of the FCM remote source (push delivery) and the local
/// SharedPreferences store (in-app list). All read APIs come from the
/// local store; writes are mirrored to the local store so the list
/// survives offline use.
///
/// The repository bridges the FCM data source's callbacks into its own
/// broadcast streams, and persists every received notification so the
/// in-app list stays in sync with what the user actually saw in the
/// system tray.
class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsFcmDataSource _fcm;
  final NotificationsLocalDataSource _local;
  bool _callbacksWired = false;

  final StreamController<NotificationItem> _receivedController =
      StreamController<NotificationItem>.broadcast();
  final StreamController<NotificationItem> _openedController =
      StreamController<NotificationItem>.broadcast();

  NotificationsRepositoryImpl({
    required this._fcm,
    required this._local,
  }) {
    // Bridge: every FCM message gets persisted and forwarded to our
    // broadcast stream so the in-app notifier can refresh. We swap
    // the placeholder callbacks the data source was constructed with
    // for the real handlers that have access to the local store.
    if (!_callbacksWired) {
      _fcm.onMessageReceived = _handleReceived;
      _fcm.onMessageOpened = _handleOpened;
      _callbacksWired = true;
    }
  }

  @override
  Future<bool> requestPermission() => _fcm.requestPermission();

  @override
  Future<String?> getDeviceToken() => _fcm.getDeviceToken();

  @override
  Stream<NotificationItem> get onMessageReceived => _receivedController.stream;

  @override
  Stream<NotificationItem> get onMessageOpenedApp => _openedController.stream;

  @override
  Future<NotificationItem?> getInitialNotification() =>
      _fcm.getInitialNotification();

  @override
  Future<void> saveLocally(NotificationItem item) => _local.save(item);

  @override
  Future<List<NotificationItem>> getAll() => _local.getAll();

  @override
  Future<void> markAsRead(String id) => _local.markAsRead(id);

  @override
  Future<void> markAllAsRead() => _local.markAllAsRead();

  @override
  Future<void> delete(String id) => _local.delete(id);

  @override
  Future<void> clear() => _local.clear();

  /// Closes the broadcast streams. Call from app teardown if you ever
  /// rebuild the repository.
  void dispose() {
    _receivedController.close();
    _openedController.close();
  }

  // ─── private ───────────────────────────────────────────────────────────

  Future<void> _handleReceived(NotificationItem item) async {
    await _local.save(item);
    _receivedController.add(item);
  }

  Future<void> _handleOpened(NotificationItem item) async {
    // The FCM source emits a stub (id only) for tray taps. Hydrate
    // the full record from disk before forwarding.
    final list = await _local.getAll();
    final match = list.firstWhere(
      (n) => n.id == item.id,
      orElse: () => item,
    );
    if (!match.isRead) {
      await _local.markAsRead(match.id);
    }
    _openedController.add(match.copyWith(isRead: true));
  }
}