import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Base URL del API Gateway en Azure Container Apps.
/// En desarrollo local apuntar a `http://10.0.2.2:8080/api` (Android emulator).
/// En producción usar la URL de Azure:
/// `https://api-gateway.redgrass-67daf10a.eastus.azurecontainerapps.io/api`
///
/// Establecer la variable de entorno `AYNI_API_BASE_URL` para sobrescribir.
const String _kDefaultBaseUrl =
    'https://api-gateway.redgrass-67daf10a.eastus.azurecontainerapps.io/api';

/// Claves bajo las que se persisten los tokens en SharedPreferences.
const String _kAccessTokenKey = 'auth.accessToken';
const String _kRefreshTokenKey = 'auth.refreshToken';

/// Cliente HTTP global con interceptores para JWT y manejo de errores.
///
/// Usage:
/// ```dart
/// final api = ApiClient(sharedPreferences: prefs);
/// final response = await api.post('/auth/login', data: {...});
/// ```
class ApiClient {
  late final Dio _dio;
  final SharedPreferences _prefs;

  ApiClient({required SharedPreferences sharedPreferences})
      : _prefs = sharedPreferences {
    _dio = Dio(
      BaseOptions(
        baseUrl: _kDefaultBaseUrl,
        // Timeouts globales holgados: las respuestas del backend pueden tardar
        // (inferencia ML online hasta ~65s, subida de imagen a Azure Blob). 15s
        // era demasiado bajo y causaba receiveTimeout. Las subidas pesadas usan
        // un timeout aún mayor por-petición (ver ApiClient.post / syncBatch).
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_prefs, _dio),
      _ErrorInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint('[ApiClient] $o'),
      ),
    ]);
  }

  // ─── HTTP verbs ─────────────────────────────────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
  }) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
  }) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);

  /// Upload con Content-Type multipart/form-data (para imágenes).
  Future<Response<T>> uploadFile<T>(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? fields,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
      ...?fields,
    });
    return _dio.post<T>(
      path,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
  }

  // ─── Token access (para use cases que necesitan enviar el bearer) ────────

  /// Persiste los tokens tras un login/refresh exitoso.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs.setString(_kAccessTokenKey, accessToken);
    await _prefs.setString(_kRefreshTokenKey, refreshToken);
  }

  /// Elimina los tokens al hacer logout.
  Future<void> clearTokens() async {
    await _prefs.remove(_kAccessTokenKey);
    await _prefs.remove(_kRefreshTokenKey);
  }

  String? get accessToken => _prefs.getString(_kAccessTokenKey);
}

/// Interceptor que inyecta el `Authorization: Bearer <token>` en cada
/// request y reintenta automáticamente con un token renovado si el
/// servidor responde 401.
class _AuthInterceptor extends Interceptor {
  final SharedPreferences _prefs;
  final Dio _dio;

  _AuthInterceptor(this._prefs, this._dio);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = _prefs.getString(_kAccessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Token expirado → intentar refresh
    final refreshToken = _prefs.getString(_kRefreshTokenKey);
    if (refreshToken == null) {
      return handler.next(err);
    }

    try {
      final refreshResponse = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccess =
          refreshResponse.data['accessToken'] as String;
      final newRefresh =
          refreshResponse.data['refreshToken'] as String? ?? refreshToken;

      await _prefs.setString(_kAccessTokenKey, newAccess);
      await _prefs.setString(_kRefreshTokenKey, newRefresh);

      // Reintentar request original con el nuevo token
      err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
      final retry = await _dio.fetch(err.requestOptions);
      return handler.resolve(retry);
    } catch (_) {
      // Refresh falló → propagate el 401 original
      return handler.next(err);
    }
  }
}

/// Interceptor que convierte respuestas de error del backend en
/// excepciones tipadas.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Timeouts (conexión/envío/recepción): mensaje claro en vez del texto crudo de Dio.
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return handler.next(DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: err.error,
        message:
            'La operación tardó demasiado. Puede deberse a imágenes grandes o '
            'a una conexión lenta; vuelve a intentarlo.',
      ));
    }

    final statusCode = err.response?.statusCode;
    final serverMessage = err.response?.data?['message'] as String?;

    String message;
    switch (statusCode) {
      case 400:
        message = serverMessage ?? 'Datos inválidos en la solicitud.';
        break;
      case 401:
        message = serverMessage ?? 'Sesión expirada. Inicia sesión de nuevo.';
        break;
      case 403:
        message = serverMessage ?? 'No tienes permiso para esta acción.';
        break;
      case 404:
        message = serverMessage ?? 'Recurso no encontrado.';
        break;
      case 409:
        message = serverMessage ?? 'El recurso ya existe.';
        break;
      case 422:
        message = serverMessage ?? 'No se pudo procesar la imagen.';
        break;
      case 429:
        message = serverMessage ?? 'Demasiadas solicitudes. Espera un momento.';
        break;
      case 503:
        message = serverMessage ?? 'Servicio no disponible. Intenta más tarde.';
        break;
      default:
        message = serverMessage ??
            err.message ??
            'Ocurrió un error inesperado. Intenta de nuevo.';
    }

    final wrapped = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: err.error,
      message: message,
    );
    return handler.next(wrapped);
  }
}
