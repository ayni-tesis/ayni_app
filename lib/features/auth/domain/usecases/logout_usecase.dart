import '../repositories/auth_repository.dart';

/// Clears the persisted session. The user profile on the device is
/// intentionally left untouched — next sign-in will re-use the same
/// profile data.
class LogoutUseCase {
  final AuthRepository _repository;

  const LogoutUseCase(this._repository);

  Future<void> call() => _repository.logout();
}