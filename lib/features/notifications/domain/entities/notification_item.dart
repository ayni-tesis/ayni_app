/// A single notification item displayed in the notifications list.
///
/// Captures everything the UI needs to render a notification card and
/// a `data` payload that the app uses for navigation when the user taps it.
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool isRead;
  final NotificationType type;
  final String? imageUrl;
  final Map<String, dynamic> data;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.type,
    this.isRead = false,
    this.imageUrl,
    this.data = const {},
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? receivedAt,
    bool? isRead,
    NotificationType? type,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
    );
  }
}

/// High-level classification used to pick the right icon/color in the UI.
enum NotificationType {
  syncCompleted,
  pestAlert,
  recommendation,
  systemUpdate,
  diagnosisComplete,
  other,
}

extension NotificationTypeX on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.syncCompleted:
        return 'Sincronización';
      case NotificationType.pestAlert:
        return 'Alerta de plaga';
      case NotificationType.recommendation:
        return 'Recomendación';
      case NotificationType.systemUpdate:
        return 'Sistema';
      case NotificationType.diagnosisComplete:
        return 'Diagnóstico';
      case NotificationType.other:
        return 'Notificación';
    }
  }
}