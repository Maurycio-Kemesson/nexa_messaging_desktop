import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/auth_session_entity.dart';
import 'auth_session_storage.dart';

class SecureAuthSessionStorage implements AuthSessionStorage {
  const SecureAuthSessionStorage();

  static const String _sessionKey = 'auth_session';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<void> save(AuthSessionEntity session) async {
    final Map<String, String?> data = {
      'homeserver': session.homeserver,
      'userId': session.userId,
      'deviceId': session.deviceId,
      'accessToken': session.accessToken,
      'refreshToken': session.refreshToken,
    };

    await _storage.write(key: _sessionKey, value: jsonEncode(data));
  }

  @override
  Future<AuthSessionEntity?> get() async {
    final String? value = await _storage.read(key: _sessionKey);

    if (value == null) {
      return null;
    }

    final data = jsonDecode(value) as Map<String, dynamic>;

    return AuthSessionEntity(
      homeserver: data['homeserver'] as String,
      userId: data['userId'] as String,
      deviceId: data['deviceId'] as String,
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String?,
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _sessionKey);
  }
}
