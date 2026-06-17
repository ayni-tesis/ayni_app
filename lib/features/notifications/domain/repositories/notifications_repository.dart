import '../entities/notification_item.dart';

/// Abstract contract the presentation layer consumes to talk to the
/// notifications subsystem. The data layer provides a concrete
/// implementation backed by Firebase Cloud Messaging and a local store.
abstract class NotificationsRepository {
  /// Asks the OS for permission to show push notifications.
  /// Returns `true` if the user grants (or already granted) permission.
  Future<bool> requestPermission();

  /// Returns the current FCM token, or `null` if it has not been
  /// obtained yet. The token is what the backend uses to target
  /// this specific device when sending a push.
  Future<String?> getDeviceToken();

  /// Streams incoming FCM messages, including those received while
  /// the app is in the foreground. The data layer translates the raw
  /// `RemoteMessage` into our [NotificationItem] domain object.
  Stream<NotificationItem> get onMessageReceived;

  /// Streams FCM messages that caused the app to be opened from
  /// a terminated state. Used for deep-linking on tap.
  Stream<NotificationItem> get onMessageOpenedApp;

  /// Returns the notification that launched the app (if any), so the
  /// UI can act on it once mounted.
  Future<NotificationItem?> getInitialNotification();

  /// Persists a notification so it survives an app restart and shows
  /// up in the in-app list. Backed by SharedPreferences.
  Future<void> saveLocally(NotificationItem item);

  /// Returns the list of notifications stored on this device,
  /// newest first.
  Future<List<NotificationItem>> getAll();

  /// Marks a notification as read. Persisted.
  Future<void> markAsRead(String id);

  /// Marks every stored notification as read.
  Future<void> markAllAsRead();

  /// Deletes a single notification from the local store.
  Future<void> delete(String id);

  /// Wipes the entire local notifications list.
  Future<void> clear();
}