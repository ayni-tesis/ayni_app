import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_models.dart';
import '../../../../core/network/api_client.dart';

/// Implementation of AuthRepository that bridges the remote API with
/// local persistence.
///
/// Strategy:
/// - `login()` / `register()`: tries the remote API first; on network
///   error falls back to the local credential store (offline mode).
/// - Tokens returned by the API are persisted locally so the app can
///   make authenticated requests even when offline.
/// - Session duration mirrors JWT_EXPIRATION (24 h) from CLAUDE.md §5.3.
class AuthRepositoryImpl implements AuthRepository {
  static const Duration _sessionDuration = Duration(hours: 24);

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;
  final ApiClient _api;

  AuthRepositoryImpl({
    required this._remote,
    required this._local,
    required this._api,
  });

  // ─── Public API ──────────────────────────────────────────────────────────────

  @override
  Future<User?> getCurrentUser() async {
    final user = _local.getCurrentUser();
    final session = _local.getCurrentSession();
    if (user == null || session == null) return null;
    if (session.isExpired) {
      await _clearSession();
      return null;
    }
    return user;
  }

  @override
  Future<AuthSession?> getCurrentSession() async {
    final session = _local.getCurrentSession();
    if (session == null) return null;
    if (session.isExpired) {
      await _clearSession();
      return null;
    }
    return session;
  }

  @override
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    // 1. Try remote API first
    try {
      final response = await _remote.register(
        RegisterRequest(
          email: email,
          password: password,
          fullName: fullName,
          consentGiven: true,
        ),
      );
      await _persistApiSession(response);
      return Right(response.user.toEntity());
    } on DioException catch (e) {
      // Network error → try offline registration
      if (_isNetworkError(e)) {
        return _offlineSignUp(email: email, password: password, fullName: fullName);
      }
      return Left(AuthFailure(e.message ?? 'Error al registrar. Intenta de nuevo.'));
    } catch (e) {
      return Left(AuthFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    // 1. Try remote API first
    try {
      final response = await _remote.login(
        LoginRequest(email: email, password: password),
      );
      await _persistApiSession(response);
      return Right(response.user.toEntity());
    } on DioException catch (e) {
      // Network error → try offline credential check
      if (_isNetworkError(e)) {
        return _offlineLogin(email: email, password: password);
      }
      return Left(AuthFailure(e.message ?? 'Error al iniciar sesión. Intenta de nuevo.'));
    } catch (e) {
      return Left(AuthFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, AuthSession>> refreshSession() async {
    final current = _local.getCurrentSession();
    if (current == null) {
      return const Left(AuthFailure('No hay una sesión activa.'));
    }

    try {
      final response = await _remote.refresh(
        RefreshRequest(refreshToken: _local.getCurrentSession()!.userId),
      );
      final newSession = AuthSession(
        userId: current.userId,
        issuedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(milliseconds: response.expiresIn)),
      );
      await _local.setCurrentSession(newSession);
      if (response.refreshToken != null) {
        await _api.saveTokens(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken!,
        );
      }
      return Right(newSession);
    } on DioException catch (e) {
      // Token inválido o expirado → forzar logout
      await _clearSession();
      return Left(AuthFailure(e.message ?? 'Sesión expirada.'));
    }
  }

  @override
  Future<void> logout() async {
    await _remote.logout();
    await _api.clearTokens();
    await _clearSession();
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  Future<void> _persistApiSession(AuthResponse response) async {
    // Persist tokens in ApiClient (so all HTTP calls are authenticated)
    await _api.saveTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );

    // Also persist in local data source for offline capability
    final user = response.user.toEntity();
    await _local.setCurrentUser(user);
    await _local.setCurrentSession(
      AuthSession(
        userId: user.id,
        issuedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(milliseconds: response.expiresIn)),
      ),
    );
  }

  Future<void> _clearSession() async {
    await _local.setCurrentUser(null);
    await _local.setCurrentSession(null);
    await _api.clearTokens();
  }

  bool _isNetworkError(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown;
  }

  /// Offline sign-up: stores user locally without server confirmation.
  Future<Either<Failure, User>> _offlineSignUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final existing = _local.getRegisteredUsers();
    if (existing.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
      return const Left(AuthFailure(
          'Ya existe una cuenta con este correo electrónico.'));
    }

    final user = User(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      email: email,
      fullName: fullName,
      role: UserRole.farmer,
      createdAt: DateTime.now(),
    );

    await _local.registerUser(user, password);
    await _persistLocalSession(user);
    return Right(user);
  }

  /// Offline login: validates credentials against the local store.
  Future<Either<Failure, User>> _offlineLogin({
    required String email,
    required String password,
  }) async {
    final user = _local
        .getRegisteredUsers()
        .where((u) => u.email.toLowerCase() == email.toLowerCase())
        .firstOrNull;
    if (user == null) {
      return const Left(
          AuthFailure('No encontramos una cuenta con ese correo.'));
    }

    final storedPassword = _local.getPasswordFor(email);
    if (storedPassword != password) {
      return const Left(AuthFailure('La contraseña es incorrecta.'));
    }

    await _persistLocalSession(user);
    return Right(user);
  }

  Future<void> _persistLocalSession(User user) async {
    final now = DateTime.now();
    final session = AuthSession(
      userId: user.id,
      issuedAt: now,
      expiresAt: now.add(_sessionDuration),
    );
    await _local.setCurrentUser(user);
    await _local.setCurrentSession(session);
  }
}
