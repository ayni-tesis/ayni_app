import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Requests a password-reset OTP code by email (HU0039).
class ForgotPasswordUseCase {
  final AuthRepository _repository;

  const ForgotPasswordUseCase(this._repository);

  Future<Either<Failure, void>> call({required String email}) {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      return Future.value(const Left(ValidationFailure('Ingresa tu correo.')));
    }
    if (!_isValidEmail(trimmedEmail)) {
      return Future.value(
        const Left(ValidationFailure('El correo no tiene un formato válido.')),
      );
    }
    return _repository.requestPasswordReset(email: trimmedEmail);
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w.\-+]+@[\w.\-]+\.\w{2,}$');
    return regex.hasMatch(email);
  }
}
