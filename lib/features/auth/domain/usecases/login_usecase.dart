import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Authenticates an existing account and starts a fresh session.
class LoginUseCase {
  final AuthRepository _repository;

  const LoginUseCase(this._repository);

  Future<Either<Failure, User>> call({
    required String email,
    required String password,
  }) {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Ingresa tu correo y contraseña.')),
      );
    }
    if (!_isValidEmail(trimmedEmail)) {
      return Future.value(
        const Left(ValidationFailure('El correo no tiene un formato válido.')),
      );
    }
    return _repository.login(email: trimmedEmail, password: password);
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w.\-+]+@[\w.\-]+\.\w{2,}$');
    return regex.hasMatch(email);
  }
}