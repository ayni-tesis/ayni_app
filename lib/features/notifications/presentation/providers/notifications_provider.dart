import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/notifications_fcm_datasource.dart';
import '../../data/datasources/notifications_local_datasource.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notifications_repository.dart';

// ─── Data sources ──────────────────────────────────────────────────────────

final notificationsLocalDataSourceProvider =
    Provider<NotificationsLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationsLocalDataSource(sharedPreferences: prefs);
});

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
  return NotificationRemoteDataSource(
    api: ref.watch(apiClientProvider),
  );
});

// ─── Repository ────────────────────────────────────────────────────────────

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepositoryImpl(
    fcm: NotificationsFcmDataSource(
      onMessageReceived: (_) {},
      onMessageOpened: (_) {},
    ),
    local: ref.watch(notificationsLocalDataSourceProvider),
    remote: ref.watch(notificationRemoteDataSourceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

// ─── Notifier ──────────────────────────────────────────────────────────────

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<NotificationItem>>> {
  final NotificationsRepository _repository;
  final NotificationsFcmDataSource _fcm;
  StreamSubscription<NotificationItem>? _receivedSub;
  StreamSubscription<NotificationItem>? _openedSub;

  NotificationsNotifier(this._repository, this._fcm)
      : super(const AsyncValue.loading()) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 1. Render whatever's already on disk so the UI shows up
    //    immediately, even if Firebase is still warming up.
    final initial = await _repository.getAll();
    state = AsyncValue.data(initial);

    // 2. Ask the OS for permission. Non-fatal on failure.
    try {
      await _fcm.requestPermission();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notifications: permission request failed: $e');
      }
    }

    // 3. Wire the FCM lifecycle. The data source subscribes to
    //    onMessage / onMessageOpenedApp and triggers our stream
    //    bridge inside the repository.
    await _fcm.initialize();

    // 4. If the user opened the app by tapping a notification, mark
    //    it read so the badge clears.
    final launch = await _fcm.getInitialNotification();
    if (launch != null) {
      await _repository.saveLocally(launch);
      if (!launch.isRead) {
        await _repository.markAsRead(launch.id);
      }
      await _refresh();
    }

    // 5. Subscribe to the repository's broadcast streams so the
    //    in-app list auto-refreshes on every new FCM message.
    _receivedSub = _repository.onMessageReceived.listen((_) => _refresh());
    _openedSub = _repository.onMessageOpenedApp.listen((_) => _refresh());
  }

  Future<void> _refresh() async {
    final list = await _repository.getAll();
    state = AsyncValue.data(list);
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    await _refresh();
  }

  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    await _refresh();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await _refresh();
  }

  Future<void> clear() async {
    await _repository.clear();
    state = const AsyncValue.data([]);
  }

  /// Returns the current FCM device token. The caller (typically the
  /// auth flow) is responsible for sending it to the backend.
  Future<String?> getDeviceToken() => _fcm.getDeviceToken();

  @override
  void dispose() {
    _receivedSub?.cancel();
    _openedSub?.cancel();
    _fcm.dispose();
    super.dispose();
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier,
    AsyncValue<List<NotificationItem>>>((ref) {
  final local = ref.watch(notificationsLocalDataSourceProvider);
  final remote = ref.watch(notificationRemoteDataSourceProvider);

  // The repository owns the FCM stream bridge. To make the FCM source
  // also forward incoming messages to the repository, the repository
  // creates its own live FCM source internally. Here we just create a
  // sibling FCM source that the notifier will use to drive its own
  // initialize()/dispose() lifecycle AND to call getToken().
  final fcm = NotificationsFcmDataSource(
    onMessageReceived: (_) {},
    onMessageOpened: (_) {},
  );

  final repo = NotificationsRepositoryImpl(
    fcm: fcm,
    local: local,
    remote: remote,
    connectivity: ref.watch(connectivityServiceProvider),
  );
  final notifier = NotificationsNotifier(repo, fcm);
  ref.onDispose(() {
    repo.dispose();
  });
  return notifier;
});

/// The current FCM device token, or `null` while it's being fetched.
/// Callers (typically the auth flow) send this to the backend so the
/// backend can target push notifications at this specific device.
final fcmDeviceTokenProvider = FutureProvider<String?>((ref) async {
  final notifier = ref.watch(notificationsProvider.notifier);
  return notifier.getDeviceToken();
});

/// Number of unread notifications. Exposed as a small derived state so
/// badges in the home/account tabs can react to changes.
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationsProvider);
  return state.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});