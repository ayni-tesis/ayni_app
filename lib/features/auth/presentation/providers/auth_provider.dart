import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';

// ─── SharedPreferences Provider ────────────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'sharedPreferencesProvider must be overridden in main.dart');
});

// ─── API client ────────────────────────────────────────────────────────────

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    sharedPreferences: ref.watch(sharedPreferencesProvider),
  );
});

// ─── Data sources ──────────────────────────────────────────────────────────

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource(
    sharedPreferences: ref.watch(sharedPreferencesProvider),
  );
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    api: ref.watch(apiClientProvider),
  );
});

// ─── Repository + use cases ────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteDataSourceProvider),
    local: ref.watch(authLocalDataSourceProvider),
    api: ref.watch(apiClientProvider),
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  return SignUpUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

final forgotPasswordUseCaseProvider = Provider<ForgotPasswordUseCase>((ref) {
  return ForgotPasswordUseCase(ref.watch(authRepositoryProvider));
});

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  return ResetPasswordUseCase(ref.watch(authRepositoryProvider));
});

// ─── Auth state + notifier ─────────────────────────────────────────────────

class AuthState {
  final User? user;
  final AuthSession? session;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.session,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null && session != null && !session!.isExpired;

  AuthState copyWith({
    User? user,
    AuthSession? session,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearSession = false,
    bool clearError = true,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      session: clearSession ? null : (session ?? this.session),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? error : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;
  final SignUpUseCase _signUpUseCase;
  final LogoutUseCase _logoutUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;
  final AuthRepository _repository;

  AuthNotifier({
    required this._loginUseCase,
    required this._signUpUseCase,
    required this._logoutUseCase,
    required this._forgotPasswordUseCase,
    required this._resetPasswordUseCase,
    required this._repository,
  }) : super(const AuthState());

  /// Restores the persisted session at app start. If the session
  /// has expired the user is dropped back to the login screen.
  Future<void> bootstrap() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final user = await _repository.getCurrentUser();
    final session = await _repository.getCurrentSession();
    state = state.copyWith(
      user: user,
      session: session,
      isLoading: false,
      clearError: true,
    );
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _loginUseCase(email: email, password: password);
    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
          clearError: false,
        );
        return false;
      },
      (user) async {
        final session = await _repository.getCurrentSession();
        state = state.copyWith(
          user: user,
          session: session,
          isLoading: false,
          clearError: true,
        );
        return true;
      },
    );
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _signUpUseCase(
      email: email,
      password: password,
      fullName: fullName,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
          clearError: false,
        );
        return false;
      },
      (user) async {
        final session = await _repository.getCurrentSession();
        state = state.copyWith(
          user: user,
          session: session,
          isLoading: false,
          clearError: true,
        );
        return true;
      },
    );
  }

  /// HU0039 — solicita el código OTP por correo. Siempre exitoso salvo error de red
  /// (el backend no revela si el correo existe, así evita enumeración de cuentas).
  Future<bool> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _forgotPasswordUseCase(email: email);
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message, clearError: false);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false, clearError: true);
        return true;
      },
    );
  }

  /// HU0039 — confirma el reseteo con el código OTP. No inicia sesión: el usuario
  /// vuelve al login para entrar con su nueva contraseña.
  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _resetPasswordUseCase(
      email: email,
      code: code,
      newPassword: newPassword,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message, clearError: false);
        return false;
      },
      (_) {
        state = state.copyWith(isLoading: false, clearError: true);
        return true;
      },
    );
  }

  Future<void> refreshSession() async {
    final result = await _repository.refreshSession();
    result.fold(
      (_) => _invalidate(),
      (session) => state = state.copyWith(session: session, clearError: true),
    );
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _logoutUseCase();
    _invalidate();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void _invalidate() {
    state = const AuthState();
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    signUpUseCase: ref.watch(signUpUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    forgotPasswordUseCase: ref.watch(forgotPasswordUseCaseProvider),
    resetPasswordUseCase: ref.watch(resetPasswordUseCaseProvider),
    repository: ref.watch(authRepositoryProvider),
  );
});

/// Convenience provider that exposes only the current user, or `null`
/// if the user is logged out / the session expired.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authNotifierProvider).user;
});

/// True if there is a non-expired session. Use to gate routes.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});