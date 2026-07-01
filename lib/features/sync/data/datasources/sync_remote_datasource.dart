import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../diagnosis/data/models/diagnosis_api_models.dart';

/// Contrato con el diagnosis-service vía API Gateway.
///
/// Usa POST /diagnoses/sync/batch para sincronizar lotes de diagnósticos offline:
/// diagnosis-service es el dueño único del diagnóstico (sube la imagen original a
/// Azure Blob y publica diagnosis.created para el dashboard). El userId se toma del
/// JWT en el Authorization header; no se envía en el body.
abstract class SyncRemoteDataSource {
  /// POST /diagnoses/sync/batch — sincroniza un lote de diagnósticos offline.
  ///
  /// Procesa cada ítem de forma idempotente por (userId, localDiagnosisId) y
  /// devuelve el resumen {received, queued, duplicates, status}.
  Future<SyncBatchResponse> syncBatch(SyncBatchRequest request);

  /// GET /sync/status — estado actual de la cola de sincronización del usuario.
  Future<SyncStatusResponse> getSyncStatus();
}

/// Implementación real con Dio → API Gateway → history-sync-service.
class SyncRemoteDataSourceImpl implements SyncRemoteDataSource {
  final ApiClient _api;

  SyncRemoteDataSourceImpl({required this._api});

  @override
  Future<SyncBatchResponse> syncBatch(SyncBatchRequest request) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/diagnoses/sync/batch',
        data: request.toJson(),
      );
      return SyncBatchResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<SyncStatusResponse> getSyncStatus() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/sync/status',
      );
      return SyncStatusResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }
}
