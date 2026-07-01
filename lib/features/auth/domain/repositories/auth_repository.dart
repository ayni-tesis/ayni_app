import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

/// Abstract contract the presentation layer consumes to authenticate
/// the farmer. The data layer provides a concrete implementation
/// backed by SharedPreferences in the offline MVP — when the backend
/// lands, this same contract is satisfied by an HTTP-backed impl.
abstract class AuthRepository {
  /// Returns the user currently logged in on this device, or `null`
  /// if there is no session or the session has expired.
  Future<User?> getCurrentUser();

  /// Returns the active session, or `null` if the user is logged out.
  Future<AuthSession?> getCurrentSession();

  /// Creates a new account and starts a fresh session.
  ///
  /// Returns the new [User] on success, or a [Failure] explaining
  /// what went wrong (e.g. email already in use, invalid input).
  Future<Either<Failure, User>> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  /// Authenticates an existing account and starts a fresh session.
  ///
  /// Returns the [User] on success, or a [Failure] for invalid
  /// credentials, missing user, etc.
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  /// Renews the current session by extending `expiresAt`. Returns
  /// the new session, or a [Failure] if there is no active session.
  Future<Either<Failure, AuthSession>> refreshSession();

  /// Logs the current user out and clears the persisted session.
  /// The user profile on the device is left untouched.
  Future<void> logout();

  /// Requests a password-reset OTP code by email (HU0039). Requires connectivity —
  /// there is no offline fallback. The backend always succeeds with a generic message
  /// regardless of whether the email is registered (avoids account enumeration).
  Future<Either<Failure, void>> requestPasswordReset({required String email});

  /// Confirms the password reset with the 6-digit OTP code received by email.
  /// Returns a [Failure] if the code is invalid, expired, or already used.
  Future<Either<Failure, void>> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  });
}