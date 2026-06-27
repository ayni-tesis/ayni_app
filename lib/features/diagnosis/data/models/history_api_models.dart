// DTOs para history-sync-service vía API Gateway.
//
// Endpoints:
//   GET  /history          → DiagnosisHistoryPage
//   GET  /history/stats    → HistoryStatsResponse
//   GET  /history/{id}     → DiagnosisHistoryItem

// ─── GET /history ────────────────────────────────────────────────────────────

/// Response paginado de GET /history
class DiagnosisHistoryPage {
  final List<DiagnosisHistoryItem> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  const DiagnosisHistoryPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory DiagnosisHistoryPage.fromJson(Map<String, dynamic> json) {
    final list = json['content'] as List<dynamic>;
    return DiagnosisHistoryPage(
      content: list
          .map((e) => DiagnosisHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      size: json['size'] as int,
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      last: json['last'] as bool,
    );
  }
}

/// Item individual dentro del historial paginado.
class DiagnosisHistoryItem {
  final String id;
  final String diagnosisId;
  final String pestType;
  final double confidenceScore;
  final String? farmName;
  final double? latitude;
  final double? longitude;
  final DateTime capturedAt;
  final DateTime? syncedAt;
  final String syncStatus; // SYNCED | PENDING | FAILED

  const DiagnosisHistoryItem({
    required this.id,
    required this.diagnosisId,
    required this.pestType,
    required this.confidenceScore,
    this.farmName,
    this.latitude,
    this.longitude,
    required this.capturedAt,
    this.syncedAt,
    required this.syncStatus,
  });

  factory DiagnosisHistoryItem.fromJson(Map<String, dynamic> json) {
    return DiagnosisHistoryItem(
      id: json['id'] as String,
      diagnosisId: json['diagnosisId'] as String,
      pestType: (json['pestType'] as String).toUpperCase(),
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      farmName: json['farmName'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
      syncedAt: json['syncedAt'] != null
          ? DateTime.parse(json['syncedAt'] as String)
          : null,
      syncStatus: (json['syncStatus'] as String).toUpperCase(),
    );
  }

  bool get isSynced => syncStatus == 'SYNCED';
}

// ─── GET /history/stats ──────────────────────────────────────────────────────

class HistoryStatsResponse {
  final List<PestCount> topPests;
  final int totalDiagnoses;
  final int totalSynced;
  final int totalPending;
  final DateTime? lastDiagnosisAt;

  const HistoryStatsResponse({
    required this.topPests,
    required this.totalDiagnoses,
    required this.totalSynced,
    required this.totalPending,
    this.lastDiagnosisAt,
  });

  factory HistoryStatsResponse.fromJson(Map<String, dynamic> json) {
    final pests = json['topPests'] as List<dynamic>;
    return HistoryStatsResponse(
      topPests: pests
          .map((e) => PestCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDiagnoses: json['totalDiagnoses'] as int,
      totalSynced: json['totalSynced'] as int,
      totalPending: json['totalPending'] as int,
      lastDiagnosisAt: json['lastDiagnosisAt'] != null
          ? DateTime.parse(json['lastDiagnosisAt'] as String)
          : null,
    );
  }
}

class PestCount {
  final String pestType;
  final int count;
  final double percentage;

  const PestCount({
    required this.pestType,
    required this.count,
    required this.percentage,
  });

  factory PestCount.fromJson(Map<String, dynamic> json) {
    return PestCount(
      pestType: (json['pestType'] as String).toUpperCase(),
      count: json['count'] as int,
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}
