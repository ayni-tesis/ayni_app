import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';

/// Persists user accounts and sessions in SharedPreferences. In the
/// offline MVP this is the entire auth backend — the on-device
/// "registered users" table lives here.
class AuthLocalDataSource {
  static const String _kUsersKey = 'auth.users.v1';
  static const String _kCurrentUserKey = 'auth.currentUser.v1';
  static const String _kCurrentSessionKey = 'auth.currentSession.v1';

  final SharedPreferences _prefs;

  AuthLocalDataSource({required SharedPreferences sharedPreferences})
      : _prefs = sharedPreferences;

  // ─── Registered users (the "user table") ────────────────────────────────

  List<User> getRegisteredUsers() {
    final raw = _prefs.getString(_kUsersKey);
    if (raw == null || raw.isEmpty) return <User>[];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => _userFromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> _saveRegisteredUsers(List<User> users) async {
    final encoded = jsonEncode(users.map(_userToJson).toList());
    await _prefs.setString(_kUsersKey, encoded);
  }

  Future<void> registerUser(User user, String password) async {
    final users = getRegisteredUsers();
    // Replace if email already exists; otherwise append.
    final filtered =
        users.where((u) => u.email.toLowerCase() != user.email.toLowerCase()).toList()
          ..add(user);
    await _saveRegisteredUsers(filtered);
    // Stash the password in a separate map so login can verify.
    final passwords = _getPasswordMap();
    passwords[user.email.toLowerCase()] = password;
    await _prefs.setString(_kPasswordsKey, jsonEncode(passwords));
  }

  String? getPasswordFor(String email) {
    final passwords = _getPasswordMap();
    return passwords[email.toLowerCase()];
  }

  static const String _kPasswordsKey = 'auth.passwords.v1';

  Map<String, String> _getPasswordMap() {
    final raw = _prefs.getString(_kPasswordsKey);
    if (raw == null || raw.isEmpty) return <String, String>{};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as String));
  }

  // ─── Current user + session ────────────────────────────────────────────

  User? getCurrentUser() {
    final raw = _prefs.getString(_kCurrentUserKey);
    if (raw == null || raw.isEmpty) return null;
    return _userFromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> setCurrentUser(User? user) async {
    if (user == null) {
      await _prefs.remove(_kCurrentUserKey);
    } else {
      await _prefs.setString(
          _kCurrentUserKey, jsonEncode(_userToJson(user)));
    }
  }

  AuthSession? getCurrentSession() {
    final raw = _prefs.getString(_kCurrentSessionKey);
    if (raw == null || raw.isEmpty) return null;
    return _sessionFromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> setCurrentSession(AuthSession? session) async {
    if (session == null) {
      await _prefs.remove(_kCurrentSessionKey);
    } else {
      await _prefs.setString(
          _kCurrentSessionKey, jsonEncode(_sessionToJson(session)));
    }
  }

  // ─── JSON ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _userToJson(User u) => {
        'id': u.id,
        'email': u.email,
        'fullName': u.fullName,
        'role': u.role.name,
        'createdAt': u.createdAt.toIso8601String(),
      };

  User _userFromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['fullName'] as String,
        role: UserRole.values.firstWhere(
          (r) => r.name == json['role'],
          orElse: () => UserRole.farmer,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> _sessionToJson(AuthSession s) => {
        'userId': s.userId,
        'issuedAt': s.issuedAt.toIso8601String(),
        'expiresAt': s.expiresAt.toIso8601String(),
      };

  AuthSession _sessionFromJson(Map<String, dynamic> json) => AuthSession(
        userId: json['userId'] as String,
        issuedAt: DateTime.parse(json['issuedAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );
}