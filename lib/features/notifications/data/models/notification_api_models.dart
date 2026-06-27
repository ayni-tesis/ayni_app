// DTOs para notification-service vía API Gateway.
//
// Endpoints:
//   GET    /notifications              → NotificationsPage
//   GET    /notifications/unread-count → UnreadCountResponse
//   PATCH  /notifications/{id}/read
//   PATCH  /notifications/read-all
//   DELETE /notifications/{id}

// ─── GET /notifications ──────────────────────────────────────────────────────

class NotificationsPage {
  final List<NotificationResponse> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  const NotificationsPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory NotificationsPage.fromJson(Map<String, dynamic> json) {
    final list = json['content'] as List<dynamic>;
    return NotificationsPage(
      content: list
          .map((e) => NotificationResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      size: json['size'] as int,
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      last: json['last'] as bool,
    );
  }
}

class NotificationResponse {
  final String id;
  final String title;
  final String body;
  final String type; // SYNC_COMPLETED | PEST_ALERT | RECOMMENDATION | DIAGNOSIS_COMPLETE | SYSTEM_UPDATE
  final bool isRead;
  final String? imageUrl;
  final Map<String, dynamic>? dataJson;
  final DateTime receivedAt;

  const NotificationResponse({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.imageUrl,
    this.dataJson,
    required this.receivedAt,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: (json['type'] as String).toUpperCase(),
      isRead: json['isRead'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      dataJson: (json['dataJson'] as Map?)?.cast<String, dynamic>(),
      receivedAt: DateTime.parse(json['receivedAt'] as String),
    );
  }

  /// Convierte el tipo string del API al NotificationType del dominio.
  /// API: SYNC_COMPLETED | PEST_ALERT | RECOMMENDATION | DIAGNOSIS_COMPLETE | SYSTEM_UPDATE
  String toDomainType() {
    switch (type) {
      case 'SYNC_COMPLETED':
        return 'syncCompleted';
      case 'PEST_ALERT':
        return 'pestAlert';
      case 'RECOMMENDATION':
        return 'recommendation';
      case 'DIAGNOSIS_COMPLETE':
        return 'diagnosisComplete';
      case 'SYSTEM_UPDATE':
        return 'systemUpdate';
      default:
        return 'other';
    }
  }
}

// ─── GET /notifications/unread-count ─────────────────────────────────────────

class UnreadCountResponse {
  final int unreadCount;

  const UnreadCountResponse({required this.unreadCount});

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountResponse(
      unreadCount: json['unreadCount'] as int,
    );
  }
}
