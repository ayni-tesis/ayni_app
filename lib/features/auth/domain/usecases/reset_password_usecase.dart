import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

/// Confirms the password reset with the 6-digit OTP code received by email (HU0039).
class ResetPasswordUseCase {
  final AuthRepository _repository;

  const ResetPasswordUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String email,
    required String code,
    required String newPassword,
  }) {
    final trimmedEmail = email.trim();
    final trimmedCode = code.trim();
    if (trimmedEmail.isEmpty || trimmedCode.isEmpty || newPassword.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Completa el código y la nueva contraseña.')),
      );
    }
    if (!RegExp(r'^\d{6}$').hasMatch(trimmedCode)) {
      return Future.value(const Left(ValidationFailure('El código debe tener 6 dígitos.')));
    }
    if (newPassword.length < 8) {
      return Future.value(
        const Left(ValidationFailure('La nueva contraseña debe tener al menos 8 caracteres.')),
      );
    }
    return _repository.confirmPasswordReset(
      email: trimmedEmail,
      code: trimmedCode,
      newPassword: newPassword,
    );
  }
}
