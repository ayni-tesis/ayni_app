import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/diagnosis_api_models.dart';
import '../models/leaf_detection_model.dart';

/// Contrato con el diagnosis-service a través del API Gateway.
///
/// Los métodos de inferenciaonline (detectLeavesOnline / classifyPestsOnline)
/// se reemplazan por analyzeImageOnline que usa el pipeline completo del
/// servidor (/diagnoses/analyze). El TFLite local es el fallback offline.
abstract class DiagnosisRemoteDataSource {
  /// POST /diagnoses/analyze
  ///
  /// Sube la imagen original al servidor y recibe el diagnóstico completo:
  /// plaga, confianza, severidad, Grad-CAM y recomendación.
  Future<DiagnosisAnalyzeResponse> analyzeImageOnline({
    required String imagePath,
    double? latitude,
    double? longitude,
  });

  /// POST /diagnoses/sync
  ///
  /// Envía un diagnóstico capturado offline para persistencia en el servidor.
  Future<void> syncDiagnosis(DiagnosisSyncRequest request);

  /// GET /diagnoses/{id}
  Future<DiagnosisAnalyzeResponse> getDiagnosisById(String id);
}

/// Implementación real con Dio → API Gateway.
class DiagnosisRemoteDataSourceImpl implements DiagnosisRemoteDataSource {
  final ApiClient _api;

  DiagnosisRemoteDataSourceImpl({required this._api});

  @override
  Future<DiagnosisAnalyzeResponse> analyzeImageOnline({
    required String imagePath,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _api.uploadFile<Map<String, dynamic>>(
        '/diagnoses/analyze',
        filePath: imagePath,
        fieldName: 'image',
        fields: {
          if (latitude != null) 'latitude': latitude.toString(),
          if (longitude != null) 'longitude': longitude.toString(),
        },
      );
      return DiagnosisAnalyzeResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<void> syncDiagnosis(DiagnosisSyncRequest request) async {
    try {
      await _api.post(
        '/diagnoses/sync',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<DiagnosisAnalyzeResponse> getDiagnosisById(String id) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/diagnoses/$id',
      );
      return DiagnosisAnalyzeResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }
}

// ─── Legacy stubs — ya no se usan; se mantienen para no romper compile
// en código que aún referencia detectLeavesOnline / classifyPestsOnline
// que fueron removidos del contrato. Se eliminan en el siguiente diff.

/// @deprecated Use [analyzeImageOnline] en su lugar.
/// Este método existía para separar detección YOLO de clasificación.
/// Ahora el servidor hace ambas en un solo paso.
Future<List<LeafDetectionModel>> detectLeavesOnlineStub(
    String originalImagePath) async {
  await Future.delayed(const Duration(milliseconds: 1500));
  throw UnimplementedError(
      'detectLeavesOnline fue reemplazado por analyzeImageOnline.');
}

/// @deprecated La clasificación ahora ocurre en el servidor vía [analyzeImageOnline].
Future<List<LeafDetectionModel>> classifyPestsOnlineStub(
    List<LeafDetectionModel> leaves) async {
  await Future.delayed(const Duration(milliseconds: 1500));
  throw UnimplementedError(
      'classifyPestsOnline fue reemplazado por analyzeImageOnline.');
}
