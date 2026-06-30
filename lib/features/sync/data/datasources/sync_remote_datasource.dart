import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../diagnosis/data/models/diagnosis_api_models.dart';

/// Contrato con el history-sync-service vía API Gateway.
///
/// Usa POST /sync/batch para sincronizar lotes de diagnósticos offline.
/// El userId se toma del JWT en el Authorization header; no se envía en el body.
abstract class SyncRemoteDataSource {
  /// POST /sync/batch — sincroniza un lote de diagnósticos offline.
  ///
  /// El servidor responde 202 Accepted y procesa los ítems de forma asíncrona.
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
        '/sync/batch',
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
