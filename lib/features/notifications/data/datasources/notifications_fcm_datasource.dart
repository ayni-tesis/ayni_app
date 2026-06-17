import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../domain/entities/notification_item.dart';

/// Thin wrapper over `firebase_messaging` + `flutter_local_notifications`.
///
/// Responsibilities:
///  * Request runtime permission (Android 13+).
///  * Surface the FCM device token.
///  * Convert raw `RemoteMessage`s into our [NotificationItem] domain type
///    and stream them out to whoever is listening.
///  * Show a system tray notification when a message arrives in the
///    foreground (FCM does this automatically when the app is backgrounded
///    or terminated, so we only need to handle the foreground case).
class NotificationsFcmDataSource {
  final FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  void Function(NotificationItem) onMessageReceived;
  void Function(NotificationItem) onMessageOpened;

  static const String _androidChannelId = 'ayni_default_channel';
  static const String _androidChannelName = 'Ayni';
  static const String _androidChannelDescription =
      'Notificaciones de sincronización y alertas fitosanitarias';

  NotificationsFcmDataSource({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    required this.onMessageReceived,
    required this.onMessageOpened,
  })  : _messaging = messaging ?? (Firebase.apps.isNotEmpty ? FirebaseMessaging.instance : null),
        _localNotifications = localNotifications ??
            FlutterLocalNotificationsPlugin();

  /// Swaps the callback targets at runtime. Used by the repository to
  /// wire itself into the FCM data source after construction — this
  /// keeps the FCM source a single, well-known instance that the
  /// notifier can drive via `initialize()`.
  void registerCallbacks({
    required void Function(NotificationItem) onMessageReceived,
    required void Function(NotificationItem) onMessageOpened,
  }) {
    this.onMessageReceived = onMessageReceived;
    this.onMessageOpened = onMessageOpened;
  }

  /// One-shot initialization. Call once at app startup, after
  /// `Firebase.initializeApp`. Returns when permission + channel setup
  /// is complete (or has been denied by the user).
  Future<void> initialize() async {
    // 1. Notification channel (Android 8+ requires a channel to show
    //    notifications at all).
    const channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDescription,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 2. Wire the local notifications plugin so we can show tray
    //    notifications from foreground messages.
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(
      init,
      onDidReceiveNotificationResponse: (response) {
        // User tapped a tray notification we showed ourselves.
        // The payload is the notification id.
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        // The actual NotificationItem was already saved by the FCM
        // stream listener — here we just signal that it was opened.
        onMessageOpened(
          NotificationItem(
            id: payload,
            title: '',
            body: '',
            receivedAt: DateTime.now(),
            type: NotificationType.other,
          ),
        );
      },
    );

    // 3. Foreground messages → show a tray notification AND forward
    //    to the domain stream so the in-app list updates.
    if (Firebase.apps.isNotEmpty) {
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 4. User tapped a notification that opened the app from
      //    background. Forward to the domain stream.
      FirebaseMessaging.onMessageOpenedApp.listen((remote) {
        final item = _toDomain(remote);
        onMessageOpened(item);
      });
    }
  }

  /// Asks the OS for permission to display notifications.
  /// On Android 13+ this is a runtime prompt; on older Android versions
  /// the permission is granted at install time and this is a no-op.
  Future<bool> requestPermission() async {
    final messaging = _messaging;
    if (messaging == null) return false;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Returns the FCM registration token. The backend stores this token
  /// in the farmer profile so notifications can be targeted at this device.
  Future<String?> getDeviceToken() async {
    final messaging = _messaging;
    if (messaging == null) return null;
    try {
      return await messaging.getToken();
    } catch (e) {
      // getToken can fail if Firebase has not been initialized or the
      // device has no Google Play Services. We swallow the error so the
      // rest of the app can keep working.
      if (kDebugMode) {
        debugPrint('NotificationsFcmDataSource.getDeviceToken failed: $e');
      }
      return null;
    }
  }

  /// Listens for token rotation. FCM rotates the token periodically;
  /// whenever it changes we log the new value so the backend can sync.
  Stream<String> get onTokenRefresh =>
      _messaging?.onTokenRefresh ?? const Stream.empty();

  /// Inspects the launch intent and returns the notification that
  /// brought the app to the foreground (if any).
  Future<NotificationItem?> getInitialNotification() async {
    final messaging = _messaging;
    if (messaging == null) return null;
    final remote = await messaging.getInitialMessage();
    if (remote == null) return null;
    return _toDomain(remote);
  }

  // ─── private helpers ───────────────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    final item = _toDomain(message);

    // Show a tray notification even though the app is in the
    // foreground (FCM only auto-shows when backgrounded/terminated).
    final notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        item.id.hashCode & 0x7fffffff, // keep positive for Android
        notification.title ?? item.title,
        notification.body ?? item.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            channelDescription: _androidChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: item.id,
      );
    }

    onMessageReceived(item);
  }

  /// Maps a `RemoteMessage` to our domain entity. Both the
  /// `notification` payload (for display) and the `data` payload
  /// (for routing/deep-linking) are merged.
  NotificationItem _toDomain(RemoteMessage message) {
    final notification = message.notification;
    final data = Map<String, dynamic>.from(message.data);

    final type = _classifyType(data['type'] as String?);

    return NotificationItem(
      id: message.messageId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: notification?.title ?? (data['title'] as String? ?? 'Ayni'),
      body: notification?.body ?? (data['body'] as String? ?? ''),
      receivedAt: DateTime.now(),
      type: type,
      imageUrl: notification?.android?.imageUrl,
      data: data,
    );
  }

  /// Maps a backend-supplied `type` string into our enum. Unknown
  /// values fall back to `other` rather than crashing.
  NotificationType _classifyType(String? raw) {
    switch (raw) {
      case 'sync.completed':
        return NotificationType.syncCompleted;
      case 'pest.alert':
        return NotificationType.pestAlert;
      case 'recommendation':
        return NotificationType.recommendation;
      case 'system.update':
        return NotificationType.systemUpdate;
      case 'diagnosis.complete':
        return NotificationType.diagnosisComplete;
      default:
        return NotificationType.other;
    }
  }

  /// Currently a no-op kept for API symmetry with the repository.
  /// The FCM SDK manages its own subscriptions.
  void dispose() {}
}