// DTOs para la comunicación con el diagnosis-service vía API Gateway.
//
// Endpoints integrados:
//   POST /diagnoses/analyze      → DiagnosisAnalyzeResponse
//   POST /diagnoses/sync        ← DiagnosisSyncRequest
//   GET  /diagnoses/{id}        → DiagnosisAnalyzeResponse
//   POST /sync/batch            ← SyncBatchRequest
//   GET  /sync/status           → SyncStatusResponse

// ─── Analyze (online diagnosis) ────────────────────────────────────────────────

/// Response del POST /diagnoses/analyze — diagnóstico completo del servidor.
class DiagnosisAnalyzeResponse {
  final String id;
  final String imageUrl;
  final String? gradcamImageUrl;
  final String detectedPest;
  final double confidenceScore;
  final double severityLevel;
  final String? recommendation;
  final double? latitude;
  final double? longitude;
  final DateTime capturedAt;

  const DiagnosisAnalyzeResponse({
    required this.id,
    required this.imageUrl,
    this.gradcamImageUrl,
    required this.detectedPest,
    required this.confidenceScore,
    required this.severityLevel,
    this.recommendation,
    this.latitude,
    this.longitude,
    required this.capturedAt,
  });

  factory DiagnosisAnalyzeResponse.fromJson(Map<String, dynamic> json) {
    return DiagnosisAnalyzeResponse(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      gradcamImageUrl: json['gradcamImageUrl'] as String?,
      detectedPest: (json['detectedPest'] as String).toUpperCase(),
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      severityLevel: (json['severityLevel'] as num).toDouble(),
      recommendation: json['recommendation'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      capturedAt: DateTime.parse(json['capturedAt'] as String),
    );
  }
}

// ─── Sync (offline → online) ─────────────────────────────────────────────────

/// Request del POST /diagnoses/sync — envía un diagnóstico capturado offline.
class DiagnosisSyncRequest {
  final String userId;
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;
  final List<LeafSyncItem> leaves;

  const DiagnosisSyncRequest({
    required this.userId,
    required this.capturedAt,
    this.latitude,
    this.longitude,
    required this.leaves,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'capturedAt': capturedAt.toIso8601String(),
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        'leaves': leaves.map((l) => l.toJson()).toList(),
      };
}

/// Item individual de una hoja dentro del sync request.
class LeafSyncItem {
  final String localId;
  final double boxX;
  final double boxY;
  final double boxWidth;
  final double boxHeight;
  final String? croppedImageBase64;
  final String diagnosedPest;
  final double confidence;
  final double? severity;

  const LeafSyncItem({
    required this.localId,
    required this.boxX,
    required this.boxY,
    required this.boxWidth,
    required this.boxHeight,
    this.croppedImageBase64,
    required this.diagnosedPest,
    required this.confidence,
    this.severity,
  });

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'boxX': boxX,
        'boxY': boxY,
        'boxWidth': boxWidth,
        'boxHeight': boxHeight,
        if (croppedImageBase64 != null) 'croppedImageBase64': croppedImageBase64,
        'diagnosedPest': diagnosedPest,
        'confidence': confidence,
        if (severity != null) 'severity': severity,
      };
}

// ─── Batch Sync ────────────────────────────────────────────────────────────────

/// Request del POST /sync/batch — sincroniza un lote de diagnósticos offline.
class SyncBatchRequest {
  final String userId;
  final List<DiagnosisSyncRequest> diagnoses;

  const SyncBatchRequest({
    required this.userId,
    required this.diagnoses,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'diagnoses': diagnoses.map((d) => d.toJson()).toList(),
      };
}

/// Response del GET /sync/status — estado de la cola de sincronización.
class SyncStatusResponse {
  final int pendingCount;
  final int syncedCount;
  final int failedCount;
  final DateTime? lastSyncedAt;

  const SyncStatusResponse({
    required this.pendingCount,
    required this.syncedCount,
    required this.failedCount,
    this.lastSyncedAt,
  });

  factory SyncStatusResponse.fromJson(Map<String, dynamic> json) {
    return SyncStatusResponse(
      pendingCount: json['pendingCount'] as int,
      syncedCount: json['syncedCount'] as int,
      failedCount: json['failedCount'] as int,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
    );
  }
}
