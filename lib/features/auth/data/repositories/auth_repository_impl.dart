import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';

/// Offline-only auth repository backed by SharedPreferences.
///
/// The "sign in" and "sign up" flows simulate a network call with a
/// short delay so the UI shows the same loading states the real
/// (backend-backed) implementation will eventually have.
class AuthRepositoryImpl implements AuthRepository {
  /// Mirrors the `JWT_EXPIRATION` documented in `CLAUDE.md` §5.3:
  /// 24 hours. Tuned down for the offline MVP so QA can exercise
  /// expiration paths in a reasonable timeframe (set to 24h here so
  /// the production-aligned default holds; tests can override the
  /// data source to control time).
  static const Duration sessionDuration = Duration(hours: 24);

  final AuthLocalDataSource _local;

  AuthRepositoryImpl({required this._local});

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
    // Simulate a network round-trip so the UI shows its loading state.
    await Future<void>.delayed(const Duration(milliseconds: 800));

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
    await _persistActiveSession(user);
    return Right(user);
  }

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

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

    await _persistActiveSession(user);
    return Right(user);
  }

  @override
  Future<Either<Failure, AuthSession>> refreshSession() async {
    final current = _local.getCurrentSession();
    final user = _local.getCurrentUser();
    if (current == null || user == null) {
      return const Left(AuthFailure('No hay una sesión activa.'));
    }
    final refreshed = current.copyWith(
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(sessionDuration),
    );
    await _local.setCurrentSession(refreshed);
    return Right(refreshed);
  }

  @override
  Future<void> logout() => _clearSession();

  Future<void> _persistActiveSession(User user) async {
    final now = DateTime.now();
    final session = AuthSession(
      userId: user.id,
      issuedAt: now,
      expiresAt: now.add(sessionDuration),
    );
    await _local.setCurrentUser(user);
    await _local.setCurrentSession(session);
  }

  Future<void> _clearSession() async {
    await _local.setCurrentUser(null);
    await _local.setCurrentSession(null);
  }
}