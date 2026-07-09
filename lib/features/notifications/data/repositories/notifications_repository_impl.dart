import 'dart:async';
import 'package:dio/dio.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_fcm_datasource.dart';
import '../datasources/notifications_local_datasource.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/notification_api_models.dart';

/// Composition of FCM (push delivery), remote API (server sync), and local
/// SharedPreferences store (offline access).
///
/// Read strategy: when online, fetch from server and use as source of truth;
/// when offline, fall back to SharedPreferences.
///
/// Write strategy: always persist locally first, then sync to server when online.
class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsFcmDataSource _fcm;
  final NotificationsLocalDataSource _local;
  final NotificationRemoteDataSource _remote;
  final ConnectivityService _connectivity;

  bool _callbacksWired = false;

  final StreamController<NotificationItem> _receivedController =
      StreamController<NotificationItem>.broadcast();
  final StreamController<NotificationItem> _openedController =
      StreamController<NotificationItem>.broadcast();

  NotificationsRepositoryImpl({
    required this._fcm,
    required this._local,
    required this._remote,
    required this._connectivity,
  }) {
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
  Future<List<NotificationItem>> getAll() async {
    try {
      final isOnline = await _connectivity.isConnected();
      if (isOnline) {
        // Server as source of truth — fetch and persist
        final serverPage = await _remote.getNotifications();
        final serverItems = serverPage.content.map(_toNotificationItem).toList();
        // Persist server items locally for offline access
        for (final item in serverItems) {
          await _local.save(item);
        }
        return serverItems;
      }
    } on DioException {
      // Fall through to local
    }

    return _local.getAll();
  }

  @override
  Future<void> markAsRead(String id) async {
    // Always update local first
    await _local.markAsRead(id);

    // Sync to server if online
    try {
      final isOnline = await _connectivity.isConnected();
      if (isOnline) {
        await _remote.markAsRead(id);
      }
    } on DioException {
      // Already marked locally; will sync later
    }
  }

  @override
  Future<void> markAllAsRead() async {
    await _local.markAllAsRead();

    try {
      final isOnline = await _connectivity.isConnected();
      if (isOnline) {
        await _remote.markAllAsRead();
      }
    } on DioException {
      // Already marked locally
    }
  }

  @override
  Future<void> delete(String id) async {
    await _local.delete(id);

    try {
      final isOnline = await _connectivity.isConnected();
      if (isOnline) {
        await _remote.deleteNotification(id);
      }
    } on DioException {
      // Already deleted locally
    }
  }

  @override
  Future<void> clear() => _local.clear();

  void dispose() {
    _receivedController.close();
    _openedController.close();
  }

  // ─── Private ───────────────────────────────────────────────────────────

  Future<void> _handleReceived(NotificationItem item) async {
    await _local.save(item);
    _receivedController.add(item);
  }

  Future<void> _handleOpened(NotificationItem item) async {
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

  NotificationItem _toNotificationItem(NotificationResponse r) {
    return NotificationItem(
      id: r.id,
      title: r.title,
      body: _htmlToPlainText(r.body),
      receivedAt: r.receivedAt,
      isRead: r.isRead,
      type: _parseType(r.type),
      imageUrl: r.imageUrl,
      data: r.dataJson ?? const {},
    );
  }

  /// El `body` de notification-service siempre viaja en HTML — está pensado
  /// para el canal de correo (SMTP) y se persiste tal cual en la bandeja
  /// in-app (ver `NotificationContentFactory`/`NotificationEventService` en
  /// el backend); no hay un campo de texto plano separado para mostrar en
  /// la app. Lo convertimos aquí para no renderizar tags crudos en la lista.
  static String _htmlToPlainText(String html) {
    final withBreaks = html.replaceAll(
      RegExp(r'<\s*(br|/p|/div|/h[1-6])\s*/?>', caseSensitive: false),
      '\n',
    );
    final withoutTags = withBreaks.replaceAll(RegExp(r'<[^>]+>'), '');
    final decoded = withoutTags
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    return decoded
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n')
        .trim();
  }

  /// Maps the backend's `NotificationType` enum name (`n.getType().name()`
  /// in `NotificationResponse`) to our domain enum. `PASSWORD_RESET` has no
  /// dedicated UI type yet and falls back to `other`.
  NotificationType _parseType(String apiType) {
    switch (apiType.toUpperCase()) {
      case 'SYNC_SUCCESS':
        return NotificationType.syncCompleted;
      case 'PEST_ALERT':
        return NotificationType.pestAlert;
      case 'RECOMMENDATION':
        return NotificationType.recommendation;
      case 'DIAGNOSIS_COMPLETE':
        return NotificationType.diagnosisComplete;
      default:
        return NotificationType.other;
    }
  }
}
