import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/notification_api_models.dart';

/// Data source para notification-service vía API Gateway.
///
/// Solo maneja la sincronización con el servidor. Las notificaciones
/// entrantes llegan por FCM (push), no por polling a este endpoint.
class NotificationRemoteDataSource {
  final ApiClient _api;

  NotificationRemoteDataSource({required this._api});

  /// GET /notifications?page=0&size=20
  Future<NotificationsPage> getNotifications({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {'page': page, 'size': size},
      );
      return NotificationsPage.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  /// GET /notifications/unread-count
  Future<int> getUnreadCount() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/notifications/unread-count',
      );
      return UnreadCountResponse.fromJson(response.data!).unreadCount;
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  /// PATCH /notifications/{id}/read
  Future<void> markAsRead(String id) async {
    try {
      await _api.patch('/notifications/$id/read');
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  /// PATCH /notifications/read-all
  Future<void> markAllAsRead() async {
    try {
      await _api.patch('/notifications/read-all');
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  /// DELETE /notifications/{id}
  Future<void> deleteNotification(String id) async {
    try {
      await _api.delete('/notifications/$id');
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }
}
