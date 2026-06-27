import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_models.dart';

/// Data source que se comunica con el auth-service a través del API Gateway.
///
/// Cada método devuelve el raw DTO del API; la conversión a entidad del
/// dominio ocurre en el repository, manteniendo la data layer libre de
/// lógica de negocio.
class AuthRemoteDataSource {
  final ApiClient _api;

  AuthRemoteDataSource({required this._api});

  /// POST /auth/login
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/auth/login',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data!);
    } on DioException catch (e) {
      // El ApiClient ya formatea el mensaje de error; lo propagamos
      throw Exception(e.message);
    }
  }

  /// POST /auth/register
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/auth/register',
        data: request.toJson(),
      );
      return AuthResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  /// POST /auth/refresh
  Future<RefreshResponse> refresh(RefreshRequest request) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: request.toJson(),
      );
      return RefreshResponse.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }

  /// POST /auth/logout (el cliente descarta los tokens localmente)
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } on DioException {
      // Ignore — el cliente ya borró los tokens de todas formas
    }
  }

  /// GET /account/me — perfil del usuario autenticado
  Future<UserDto> getAccountMe() async {
    try {
      final response = await _api.get<Map<String, dynamic>>('/account/me');
      return UserDto.fromJson(response.data!);
    } on DioException catch (e) {
      throw Exception(e.message);
    }
  }
}
