/// Represents a user account in Ayni.
///
/// In the offline-only MVP this is created locally by sign-up and
/// persisted in SharedPreferences. When the backend integration lands,
/// this entity will mirror the `UserDto` returned by `auth-service`.
class User {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Roles supported by the system. For the offline MVP every account
/// is created as `farmer` — admins and agronomists will only be
/// provisioned by the backend in a future iteration.
enum UserRole {
  farmer,
  agronomist,
  admin,
}

extension UserRoleX on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.farmer:
        return 'Caficultor';
      case UserRole.agronomist:
        return 'Agrónomo';
      case UserRole.admin:
        return 'Administrador';
    }
  }
}

/// Snapshot of the active session.
///
/// `expiresAt` controls when the session is considered stale and the
/// user is forced back to the login screen. In the offline MVP this is
/// a wall-clock deadline stored in SharedPreferences. When the backend
/// integration lands this will be derived from the JWT `exp` claim.
class AuthSession {
  final String userId;
  final DateTime issuedAt;
  final DateTime expiresAt;

  const AuthSession({
    required this.userId,
    required this.issuedAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isValid =>
      DateTime.now().isAfter(issuedAt) && !isExpired;

  AuthSession copyWith({
    String? userId,
    DateTime? issuedAt,
    DateTime? expiresAt,
  }) {
    return AuthSession(
      userId: userId ?? this.userId,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}