import '../../domain/entities/user.dart';

/// DTO que refleja la respuesta de `/auth/login` y `/auth/register`.
/// El campo `tokenType` siempre es "Bearer".
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn; // milisegundos
  final UserDto user;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tokenType: json['tokenType'] as String,
      expiresIn: json['expiresIn'] as int,
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// DTO que refleja el `user` dentro de AuthResponse y `/account/me`.
class UserDto {
  final String id;
  final String email;
  final String fullName;
  final String role; // FARMER | AGRONOMIST | ADMIN
  final bool active;
  final bool consentGiven;
  final DateTime? createdAt;

  const UserDto({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.active = true,
    this.consentGiven = false,
    this.createdAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      role: (json['role'] as String).toUpperCase(),
      active: json['active'] as bool? ?? true,
      consentGiven: json['consentGiven'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Convierte el DTO del API a la entidad `User` del dominio.
  User toEntity() {
    return User(
      id: id,
      email: email,
      fullName: fullName,
      role: _parseRole(role),
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static UserRole _parseRole(String role) {
    switch (role.toUpperCase()) {
      case 'AGRONOMIST':
        return UserRole.agronomist;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.farmer;
    }
  }
}

/// DTO para el body de `/auth/register`.
class RegisterRequest {
  final String email;
  final String password;
  final String fullName;
  final bool consentGiven;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.consentGiven,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'fullName': fullName,
        'consentGiven': consentGiven,
      };
}

/// DTO para el body de `/auth/login`.
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

/// DTO para el body de `/auth/refresh`.
class RefreshRequest {
  final String refreshToken;

  const RefreshRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refreshToken': refreshToken};
}

/// DTO para el body de `/auth/forgot-password`.
class ForgotPasswordRequest {
  final String email;

  const ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() => {'email': email};
}

/// DTO para el body de `/auth/reset-password`. El código OTP tiene 6 dígitos (HU0039).
class ResetPasswordRequest {
  final String email;
  final String code;
  final String newPassword;

  const ResetPasswordRequest({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'code': code,
        'newPassword': newPassword,
      };
}

/// Respuesta de `/auth/refresh` — mismos campos que AuthResponse.
class RefreshResponse {
  final String accessToken;
  final String? refreshToken; // opcional; si viene, actualizar
  final int expiresIn;

  const RefreshResponse({
    required this.accessToken,
    this.refreshToken,
    required this.expiresIn,
  });

  factory RefreshResponse.fromJson(Map<String, dynamic> json) {
    return RefreshResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      expiresIn: json['expiresIn'] as int,
    );
  }
}
