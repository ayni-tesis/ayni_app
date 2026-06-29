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

  /// POST /diagnoses/leaves/detect
  Future<LeavesDetectionResponse> detectLeavesOnline({
    required String imagePath,
    double? latitude,
    double? longitude,
  });

  /// POST /diagnoses/leaves/classify (forma A)
  Future<LeavesClassifyResponse> classifyPestsOnline({
    required String imageUrl,
    required List<LeafBoxModel> leaves,
    required int imageWidth,
    required int imageHeight,
  });

  /// POST /diagnoses/leaves/classify (forma B)
  Future<LeavesClassifyResponse> classifyPestsByCropsOnline({
    required List<Map<String, String>> crops,
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

  @override
  Future<LeavesDetectionResponse> detectLeavesOnline({
    required String imagePath,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _api.uploadFile<Map<String, dynamic>>(
        '/diagnoses/leaves/detect',
        filePath: imagePath,
        fieldName: 'image',
        fields: {
          if (latitude != null) 'latitude': latitude.toString(),
          if (longitude != null) 'longitude': longitude.toString(),
        },
      );
      return LeavesDetectionResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<LeavesClassifyResponse> classifyPestsOnline({
    required String imageUrl,
    required List<LeafBoxModel> leaves,
    required int imageWidth,
    required int imageHeight,
  }) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/diagnoses/leaves/classify',
        data: {
          'imageUrl': imageUrl,
          'imageWidth': imageWidth,
          'imageHeight': imageHeight,
          'leaves': leaves.map((l) => l.toJson()).toList(),
        },
      );
      return LeavesClassifyResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  @override
  Future<LeavesClassifyResponse> classifyPestsByCropsOnline({
    required List<Map<String, String>> crops,
  }) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/diagnoses/leaves/classify',
        data: {
          'crops': crops,
        },
      );
      return LeavesClassifyResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }
}
