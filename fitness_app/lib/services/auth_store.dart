import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/user_profile.dart';

/// Gestiona el registro, inicio de sesion y preferencias de usuario en Hive.
class AuthStore {
  static const _usersBoxName = 'fit_pro_users';
  static const _sessionBoxName = 'fit_pro_auth_session';
  static const _activeEmailKey = 'active_email';
  static const _lastEmailKey = 'last_email';

  Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(_usersBoxName),
      Hive.openBox(_sessionBoxName),
    ]);
  }

  String _hashPassword(String email, String password) {
    final normalized = '${email.trim().toLowerCase()}::$password::FIT_PRO_SALT';
    final bytes = utf8.encode(normalized);
    var h1 = 0x811c9dc5;
    var h2 = 0x9e3779b9;
    for (final b in bytes) {
      h1 ^= b;
      h1 = (h1 * 0x01000193) & 0xFFFFFFFF;
      h2 = ((h2 << 5) - h2 + b) & 0xFFFFFFFF;
    }
    return '${h1.toRadixString(16).padLeft(8, '0')}${h2.toRadixString(16).padLeft(8, '0')}';
  }

  Future<Box<dynamic>> _usersBox() async => Hive.isBoxOpen(_usersBoxName)
      ? Hive.box<dynamic>(_usersBoxName)
      : await Hive.openBox<dynamic>(_usersBoxName);

  Future<Box<dynamic>> _sessionBox() async => Hive.isBoxOpen(_sessionBoxName)
      ? Hive.box<dynamic>(_sessionBoxName)
      : await Hive.openBox<dynamic>(_sessionBoxName);

  Future<bool> hasRegisteredUsers() async {
    final box = await _usersBox();
    return box.isNotEmpty;
  }

  Future<String?> getLastEmail() async {
    final box = await _sessionBox();
    return box.get(_lastEmailKey) as String?;
  }

  Future<UserProfile?> getCurrentUser() async {
    final session = await _sessionBox();
    final activeEmail = session.get(_activeEmailKey) as String?;
    if (activeEmail == null || activeEmail.isEmpty) return null;
    final users = await _usersBox();
    final raw = users.get(activeEmail);
    if (raw is Map) {
      return UserProfile.fromMap(raw);
    }
    return null;
  }

  Future<UserProfile?> getLastBiometricUser() async {
    final session = await _sessionBox();
    final users = await _usersBox();
    final lastEmail = session.get(_lastEmailKey) as String?;

    if (lastEmail != null && lastEmail.isNotEmpty) {
      final raw = users.get(lastEmail);
      if (raw is Map) {
        final profile = UserProfile.fromMap(raw);
        if (profile.biometricEnabled) return profile;
      }
    }

    for (final val in users.values) {
      if (val is Map) {
        final profile = UserProfile.fromMap(val);
        if (profile.biometricEnabled) return profile;
      }
    }
    return null;
  }

  Future<({bool ok, String message, UserProfile? user})> register({
    required String name,
    required String email,
    required String password,
    int stepGoal = 8000,
    double weightKg = 70.0,
    double heightCm = 170.0,
    bool biometricEnabled = true,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    if (cleanName.isEmpty || cleanEmail.isEmpty || password.length < 4) {
      return (
        ok: false,
        message: 'Completa nombre, correo válido y contraseña de al menos 4 caracteres.',
        user: null,
      );
    }

    final users = await _usersBox();
    if (users.containsKey(cleanEmail)) {
      return (
        ok: false,
        message: 'Ya existe una cuenta registrada con este correo.',
        user: null,
      );
    }

    final profile = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: cleanName,
      email: cleanEmail,
      passwordHash: _hashPassword(cleanEmail, password),
      stepGoal: stepGoal,
      weightKg: weightKg,
      heightCm: heightCm,
      biometricEnabled: biometricEnabled,
      createdAt: DateTime.now(),
    );

    await users.put(cleanEmail, profile.toMap());
    final session = await _sessionBox();
    await session.put(_activeEmailKey, cleanEmail);
    await session.put(_lastEmailKey, cleanEmail);

    return (
      ok: true,
      message: 'Cuenta FITPRO creada correctamente.',
      user: profile,
    );
  }

  Future<({bool ok, String message, UserProfile? user})> loginWithCredentials(
    String email,
    String password,
  ) async {
    final cleanEmail = email.trim().toLowerCase();
    final users = await _usersBox();
    final raw = users.get(cleanEmail);
    if (raw is! Map) {
      return (
        ok: false,
        message: 'No encontramos una cuenta con ese correo. Regístrate primero.',
        user: null,
      );
    }

    final profile = UserProfile.fromMap(raw);
    final incomingHash = _hashPassword(cleanEmail, password);
    if (profile.passwordHash != incomingHash) {
      return (
        ok: false,
        message: 'Contraseña incorrecta. Verifica tus credenciales.',
        user: null,
      );
    }

    final session = await _sessionBox();
    await session.put(_activeEmailKey, cleanEmail);
    await session.put(_lastEmailKey, cleanEmail);
    return (
      ok: true,
      message: 'Bienvenido de vuelta, ${profile.name}.',
      user: profile,
    );
  }

  Future<void> activateBiometricSession(UserProfile user) async {
    final session = await _sessionBox();
    await session.put(_activeEmailKey, user.email);
    await session.put(_lastEmailKey, user.email);
  }

  Future<void> updateUser(UserProfile updated) async {
    final users = await _usersBox();
    await users.put(updated.email, updated.toMap());
  }

  Future<void> logout() async {
    final session = await _sessionBox();
    await session.delete(_activeEmailKey);
  }
}
