import '../models/diagnosis_model.dart';
import '../models/leaf_detection_model.dart';

abstract class DiagnosisRemoteDataSource {
  Future<List<LeafDetectionModel>> detectLeavesOnline(String originalImagePath);
  Future<List<LeafDetectionModel>> classifyPestsOnline(List<LeafDetectionModel> leaves);
  Future<void> uploadDiagnosis(DiagnosisModel diagnosis);
}

class DiagnosisRemoteDataSourceImpl implements DiagnosisRemoteDataSource {
  // We can inject dio API client later
  const DiagnosisRemoteDataSourceImpl();

  @override
  Future<List<LeafDetectionModel>> detectLeavesOnline(String originalImagePath) async {
    // In the future, this will perform a POST multipart request to /diagnoses/analyze-leaves
    // For now, it delegates to a brief delay to simulate network latency, then fails or falls back.
    await Future.delayed(const Duration(milliseconds: 1500));
    throw UnimplementedError('Servidor remoto no configurado.');
  }

  @override
  Future<List<LeafDetectionModel>> classifyPestsOnline(List<LeafDetectionModel> leaves) async {
    // In the future, this will perform a POST request to /diagnoses/classify-pests
    await Future.delayed(const Duration(milliseconds: 1500));
    throw UnimplementedError('Servidor remoto no configurado.');
  }

  @override
  Future<void> uploadDiagnosis(DiagnosisModel diagnosis) async {
    // In the future, uploads the offline-synchronized batch / sync queue
    await Future.delayed(const Duration(milliseconds: 1000));
  }
}
