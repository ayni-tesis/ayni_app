import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/notification_item.dart';

/// Stores notifications in SharedPreferences as a JSON list so the
/// in-app notification list survives app restarts even when offline.
class NotificationsLocalDataSource {
  static const String _kStorageKey = 'notifications.list.v1';

  final SharedPreferences _prefs;

  NotificationsLocalDataSource({required SharedPreferences sharedPreferences})
      : _prefs = sharedPreferences;

  Future<List<NotificationItem>> getAll() async {
    final raw = _prefs.getString(_kStorageKey);
    if (raw == null || raw.isEmpty) return <NotificationItem>[];

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => _fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> save(NotificationItem item) async {
    final list = await getAll();
    // Dedupe by id — if a notification with the same id already
    // exists, replace it (handles FCM redelivery).
    final filtered = list.where((n) => n.id != item.id).toList()
      ..insert(0, item);
    await _persist(filtered);
  }

  Future<void> markAsRead(String id) async {
    final list = await getAll();
    final updated = list
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    await _persist(updated);
  }

  Future<void> markAllAsRead() async {
    final list = await getAll();
    final updated = list.map((n) => n.copyWith(isRead: true)).toList();
    await _persist(updated);
  }

  Future<void> delete(String id) async {
    final list = await getAll();
    final filtered = list.where((n) => n.id != id).toList();
    await _persist(filtered);
  }

  Future<void> clear() async {
    await _prefs.remove(_kStorageKey);
  }

  Future<void> _persist(List<NotificationItem> items) async {
    final encoded = jsonEncode(items.map(_toJson).toList());
    await _prefs.setString(_kStorageKey, encoded);
  }

  Map<String, dynamic> _toJson(NotificationItem n) => {
        'id': n.id,
        'title': n.title,
        'body': n.body,
        'receivedAt': n.receivedAt.toIso8601String(),
        'isRead': n.isRead,
        'type': n.type.name,
        'imageUrl': n.imageUrl,
        'data': n.data,
      };

  NotificationItem _fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        receivedAt: DateTime.parse(json['receivedAt'] as String),
        isRead: json['isRead'] as bool? ?? false,
        type: NotificationType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => NotificationType.other,
        ),
        imageUrl: json['imageUrl'] as String?,
        data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}