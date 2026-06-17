import '../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Creates a new account and starts a fresh session.
class SignUpUseCase {
  final AuthRepository _repository;

  const SignUpUseCase(this._repository);

  Future<Either<Failure, User>> call({
    required String email,
    required String password,
    required String fullName,
  }) {
    final trimmedEmail = email.trim();
    final trimmedName = fullName.trim();

    if (trimmedEmail.isEmpty ||
        password.isEmpty ||
        trimmedName.isEmpty) {
      return Future.value(
        const Left(ValidationFailure(
            'Completa todos los campos para registrarte.')),
      );
    }
    if (password.length < 6) {
      return Future.value(
        const Left(ValidationFailure(
            'La contraseña debe tener al menos 6 caracteres.')),
      );
    }
    if (!_isValidEmail(trimmedEmail)) {
      return Future.value(
        const Left(ValidationFailure('El correo no tiene un formato válido.')),
      );
    }
    return _repository.signUp(
      email: trimmedEmail,
      password: password,
      fullName: trimmedName,
    );
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w.\-+]+@[\w.\-]+\.\w{2,}$');
    return regex.hasMatch(email);
  }
}