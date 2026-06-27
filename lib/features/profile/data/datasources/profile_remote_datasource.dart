import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/profile_api_models.dart';

/// Data source para user-service vía API Gateway.
class ProfileRemoteDataSource {
  final ApiClient _api;

  ProfileRemoteDataSource({required this._api});

  /// GET /users/profile
  Future<FarmerProfileResponse> getProfile() async {
    try {
      final response = await _api.get<Map<String, dynamic>>('/users/profile');
      return FarmerProfileResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  /// PUT /users/profile — crea o actualiza el perfil completo.
  Future<FarmerProfileResponse> saveProfile(FarmerProfileRequest request) async {
    try {
      final response = await _api.put<Map<String, dynamic>>(
        '/users/profile',
        data: request.toJson(),
      );
      return FarmerProfileResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  /// PATCH /users/profile/fcm-token — registra el token FCM para push notifications.
  Future<void> updateFcmToken(FcmTokenRequest request) async {
    try {
      await _api.patch(
        '/users/profile/fcm-token',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }
}
