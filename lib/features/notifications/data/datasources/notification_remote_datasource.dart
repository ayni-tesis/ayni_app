import '../../../../core/network/api_client.dart';
import '../models/notification_api_models.dart';

/// Data source para notification-service vía API Gateway.
///
/// Solo maneja la sincronización con el servidor. Las notificaciones
/// entrantes llegan por FCM (push), no por polling a este endpoint.
///
/// No envuelve `DioException` en excepciones genéricas: el repositorio
/// necesita el tipo original para decidir cuándo hacer fallback al
/// almacenamiento local.
class NotificationRemoteDataSource {
  final ApiClient _api;

  NotificationRemoteDataSource({required this._api});

  /// GET /notifications?page=0&size=20
  Future<NotificationsPage> getNotifications({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: {'page': page, 'size': size},
    );
    return NotificationsPage.fromJson(response.data!);
  }

  /// GET /notifications/unread-count
  Future<int> getUnreadCount() async {
    final response = await _api.get<Map<String, dynamic>>(
      '/notifications/unread-count',
    );
    return UnreadCountResponse.fromJson(response.data!).unreadCount;
  }

  /// PATCH /notifications/{id}/read
  Future<void> markAsRead(String id) async {
    await _api.patch('/notifications/$id/read');
  }

  /// PATCH /notifications/read-all
  Future<void> markAllAsRead() async {
    await _api.patch('/notifications/read-all');
  }

  /// DELETE /notifications/{id}
  Future<void> deleteNotification(String id) async {
    await _api.delete('/notifications/$id');
  }
}
