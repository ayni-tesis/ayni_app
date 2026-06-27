import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/history_api_models.dart';

/// Data source para history-sync-service vía API Gateway.
class HistoryRemoteDataSource {
  final ApiClient _api;

  HistoryRemoteDataSource({required this._api});

  /// GET /history?page=0&size=20&sortBy=capturedAt&direction=DESC
  Future<DiagnosisHistoryPage> getHistory({
    int page = 0,
    int size = 20,
    String sortBy = 'capturedAt',
    String direction = 'DESC',
  }) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/history',
        queryParameters: {
          'page': page,
          'size': size,
          'sortBy': sortBy,
          'direction': direction,
        },
      );
      return DiagnosisHistoryPage.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  /// GET /history/stats
  Future<HistoryStatsResponse> getHistoryStats() async {
    try {
      final response = await _api.get<Map<String, dynamic>>('/history/stats');
      return HistoryStatsResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  /// GET /history/{id}
  Future<DiagnosisHistoryItem> getHistoryById(String id) async {
    try {
      final response = await _api.get<Map<String, dynamic>>('/history/$id');
      return DiagnosisHistoryItem.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }
}
